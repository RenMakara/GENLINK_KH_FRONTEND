import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';

class _FakeMediaRepository implements MediaRepository {
  String? presignedContentType;
  int? presignedSize;
  MediaPurpose? presignedPurpose;
  String? presignedChecksum;
  Uint8List? uploadedBytes;
  String? confirmedMediaId;
  int? confirmedWidth;
  int? confirmedDurationMs;
  final calls = <String>[];

  void Function(int, int)? _progressSink;

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    calls.add('presign');
    presignedContentType = contentType;
    presignedSize = sizeBytes;
    presignedPurpose = purpose;
    presignedChecksum = checksumSha256;
    return const PresignedUpload(
      mediaId: 'media-1',
      uploadUrl: 'https://storage.example.com/put?sig=x',
      storageKey: 'avatars/abc.jpg',
      requiredHeaders: {'Content-Type': 'image/jpeg'},
      expiresInSeconds: 300,
    );
  }

  @override
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    calls.add('upload');
    uploadedBytes = bytes;
    _progressSink = onProgress;
    onProgress?.call(bytes.length ~/ 2, bytes.length);
    onProgress?.call(bytes.length, bytes.length);
  }

  void emitUnknownTotal(int sent) => _progressSink?.call(sent, -1);

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    calls.add('confirm');
    confirmedMediaId = mediaId;
    confirmedWidth = width;
    confirmedDurationMs = durationMs;
    return MediaEntity(
      mediaId: mediaId,
      url: 'https://cdn.example.com/avatars/abc.jpg',
      contentType: 'image/jpeg',
      sizeBytes: uploadedBytes?.length ?? 0,
    );
  }

  @override
  Future<void> delete(String mediaId) async => calls.add('delete');
}

void main() {
  late _FakeMediaRepository repository;
  late MediaUploadService service;

  setUp(() {
    repository = _FakeMediaRepository();
    service = MediaUploadService(repository);
  });

  Uint8List bytes(int length) =>
      Uint8List.fromList(List.filled(length, 7));

  group('upload', () {
    test('runs presign, upload and confirm in order', () async {
      final media = await service.upload(
        bytes: bytes(1024),
        contentType: 'image/jpeg',
        purpose: MediaPurpose.avatar,
      );

      expect(repository.calls, ['presign', 'upload', 'confirm']);
      expect(media.url, 'https://cdn.example.com/avatars/abc.jpg');
      expect(repository.confirmedMediaId, 'media-1');
    });

    test('sends the SHA-256 of the exact bytes uploaded', () async {
      final payload = bytes(2048);

      await service.upload(
        bytes: payload,
        contentType: 'image/jpeg',
        purpose: MediaPurpose.avatar,
      );

      expect(repository.presignedChecksum, sha256.convert(payload).toString());
      expect(repository.presignedChecksum, hasLength(64));
      expect(repository.uploadedBytes, same(payload));
    });

    test('declares the real size and purpose at presign', () async {
      await service.upload(
        bytes: bytes(4096),
        contentType: 'image/jpeg',
        purpose: MediaPurpose.post,
      );

      expect(repository.presignedSize, 4096);
      expect(repository.presignedPurpose, MediaPurpose.post);
      expect(repository.presignedContentType, 'image/jpeg');
    });

    test('passes dimensions and duration through to confirm', () async {
      await service.upload(
        bytes: bytes(512),
        contentType: 'video/mp4',
        purpose: MediaPurpose.story,
        width: 1080,
        durationMs: 15000,
      );

      expect(repository.confirmedWidth, 1080);
      expect(repository.confirmedDurationMs, 15000);
    });

    test('reports progress from 0 to 1', () async {
      final seen = <double>[];

      await service.upload(
        bytes: bytes(1000),
        contentType: 'image/jpeg',
        purpose: MediaPurpose.avatar,
        onProgress: seen.add,
      );

      expect(seen.first, 0.0);
      expect(seen.last, 1.0);
      expect(seen, contains(0.5));
      expect(seen.every((f) => f >= 0.0 && f <= 1.0), isTrue);
    });
  });

  group('validation', () {
    test('rejects an empty file before any network call', () async {
      await expectLater(
        service.upload(
          bytes: Uint8List(0),
          contentType: 'image/jpeg',
          purpose: MediaPurpose.avatar,
        ),
        throwsA(isA<AppError>()
            .having((e) => e.errorCode, 'errorCode', 'MEDIA_EMPTY')),
      );
      expect(repository.calls, isEmpty);
    });

    test('rejects a non-media content type', () async {
      await expectLater(
        service.upload(
          bytes: bytes(10),
          contentType: 'application/pdf',
          purpose: MediaPurpose.post,
        ),
        throwsA(isA<AppError>()
            .having((e) => e.errorCode, 'errorCode', 'MEDIA_INVALID_TYPE')),
      );
      expect(repository.calls, isEmpty);
    });

    test('rejects video for a purpose that does not allow it', () async {
      await expectLater(
        service.upload(
          bytes: bytes(10),
          contentType: 'video/mp4',
          purpose: MediaPurpose.avatar,
        ),
        throwsA(isA<AppError>().having(
            (e) => e.errorCode, 'errorCode', 'MEDIA_VIDEO_NOT_ALLOWED')),
      );
      expect(repository.calls, isEmpty);
    });

    test('allows video for post, story and short', () async {
      await service.upload(
        bytes: bytes(10),
        contentType: 'video/mp4',
        purpose: MediaPurpose.post,
      );
      expect(repository.calls, contains('presign'));
    });

    test('rejects an image over the 5 MB cap', () async {
      await expectLater(
        service.upload(
          bytes: bytes(MediaUploadService.maxImageBytes + 1),
          contentType: 'image/jpeg',
          purpose: MediaPurpose.avatar,
        ),
        throwsA(isA<AppError>()
            .having((e) => e.errorCode, 'errorCode', 'MEDIA_TOO_LARGE')),
      );
      expect(repository.calls, isEmpty);
    });

    test('allows a video larger than the image cap', () async {
      await service.upload(
        bytes: bytes(MediaUploadService.maxImageBytes + 1),
        contentType: 'video/mp4',
        purpose: MediaPurpose.short,
      );
      expect(repository.calls, contains('upload'));
    });
  });

  group('MediaPurpose', () {
    test('wire values match the backend enum', () {
      expect(MediaPurpose.avatar.wireValue, 'AVATAR');
      expect(MediaPurpose.eventCover.wireValue, 'EVENT_COVER');
      expect(MediaPurpose.communityCover.wireValue, 'COMMUNITY_COVER');
    });

    test('story, short, and post allow video', () {
      expect(MediaPurpose.story.allowsVideo, isTrue);
      expect(MediaPurpose.short.allowsVideo, isTrue);
      expect(MediaPurpose.post.allowsVideo, isTrue);
      expect(MediaPurpose.avatar.allowsVideo, isFalse);
    });
  });

  group('MediaPicker', () {
    test('maps video extensions to the container type', () {
      expect(MediaPicker.videoTypeFor('/tmp/a.mp4'), 'video/mp4');
      expect(MediaPicker.videoTypeFor('/tmp/a.MOV'), 'video/quicktime');
      expect(MediaPicker.videoTypeFor('/tmp/a.webm'), 'video/webm');
      expect(MediaPicker.videoTypeFor('/tmp/no-extension'), 'video/mp4');
    });
  });
}
