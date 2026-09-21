import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';
import 'package:genlink_frontend/features/short_content/domain/models/short_content_models.dart';
import 'package:genlink_frontend/features/short_content/domain/repositories/short_content_repository.dart';
import 'package:genlink_frontend/features/short_content/presentation/controllers/short_content_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockShortContentRepository extends Mock
    implements ShortContentRepository {}

class _FakeMediaRepository implements MediaRepository {
  int _nextMediaId = 0;
  final mediaTypes = <String, String>{};
  final deletedMediaIds = <String>[];

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    final mediaId = 'media-${++_nextMediaId}';
    mediaTypes[mediaId] = contentType;
    return PresignedUpload(
      mediaId: mediaId,
      uploadUrl: 'https://upload.example.com/$mediaId',
      storageKey: 'short/$mediaId',
      requiredHeaders: const {},
      expiresInSeconds: 300,
    );
  }

  @override
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    return MediaEntity(
      mediaId: mediaId,
      url: 'https://cdn.example.com/$mediaId',
      contentType: mediaTypes[mediaId] ?? 'video/mp4',
      sizeBytes: 1,
    );
  }

  @override
  Future<void> delete(String mediaId) async {
    deletedMediaIds.add(mediaId);
  }
}

ShortContentModel _item({
  bool liked = false,
  bool saved = false,
  int likes = 0,
  int saves = 0,
}) {
  return ShortContentModel(
    shortContentId: 'short-1',
    title: 'Short',
    description: 'Description',
    category: 'FOCUS',
    videoUrl: 'https://cdn.example.com/short.mp4',
    thumbnailUrl: 'https://cdn.example.com/short.jpg',
    creatorId: 'creator-1',
    likeCount: likes,
    saveCount: saves,
    shareCount: 0,
    liked: liked,
    saved: saved,
  );
}

ShortContentPage _page({
  required List<ShortContentModel> content,
  int page = 0,
  bool hasNext = false,
}) {
  return ShortContentPage(
    content: content,
    page: page,
    size: 20,
    totalElements: content.length,
    totalPages: hasNext ? page + 2 : page + 1,
    hasNext: hasNext,
  );
}

void main() {
  late _MockShortContentRepository repository;
  late _FakeMediaRepository mediaRepository;
  late ShortContentController controller;

  setUpAll(() {
    registerFallbackValue(
      const ShortContentCreateRequest(
        title: 'fallback',
        videoUrl: 'https://cdn.example.com/fallback.mp4',
      ),
    );
  });

  setUp(() {
    repository = _MockShortContentRepository();
    mediaRepository = _FakeMediaRepository();
    controller = ShortContentController(
      repository: repository,
      mediaUploadService: MediaUploadService(mediaRepository),
    );
  });

  tearDown(() => controller.onClose());

  test('loads the first page and exposes loading state', () async {
    final completer = Completer<ShortContentPage>();
    when(
      () => repository.getFeed(page: 0, size: 20, category: null),
    ).thenAnswer((_) => completer.future);

    final request = controller.loadFeed();
    expect(controller.isLoading.value, isTrue);

    completer.complete(_page(content: [_item()], hasNext: true));
    await request;

    expect(controller.isLoading.value, isFalse);
    expect(controller.items.single.shortContentId, 'short-1');
    expect(controller.currentPage.value, 0);
    expect(controller.hasMore.value, isTrue);
  });

  test('keeps a real empty response empty', () async {
    when(
      () => repository.getFeed(page: 0, size: 20, category: null),
    ).thenAnswer((_) async => _page(content: const []));

    await controller.loadFeed();

    expect(controller.items, isEmpty);
    expect(controller.errorMessage.value, isNull);
    expect(controller.hasMore.value, isFalse);
  });

  test('loads a specific content item for the detail route', () async {
    final detail = _item().copyWith(shortContentId: 'short-42');
    when(() => repository.getById('short-42')).thenAnswer((_) async => detail);

    final result = await controller.loadById('short-42');

    expect(result, same(detail));
    expect(controller.itemById('short-42'), same(detail));
    verify(() => repository.getById('short-42')).called(1);
  });

  test('surfaces feed errors without creating placeholder content', () async {
    when(() => repository.getFeed(page: 0, size: 20, category: null)).thenThrow(
      const AppError(message: 'Feed unavailable', errorCode: 'API_ERROR'),
    );

    await controller.loadFeed();

    expect(controller.items, isEmpty);
    expect(controller.errorMessage.value, 'Feed unavailable');
    expect(controller.isLoading.value, isFalse);
  });

  test('loads the next page and prevents duplicate content ids', () async {
    controller.items.assignAll([_item()]);
    controller.currentPage.value = 0;
    controller.hasMore.value = true;
    when(
      () => repository.getFeed(page: 1, size: 20, category: null),
    ).thenAnswer(
      (_) async => _page(
        page: 1,
        hasNext: false,
        content: [
          _item(),
          _item().copyWith(shortContentId: 'short-2'),
        ],
      ),
    );

    await controller.loadMore();

    expect(controller.items.map((item) => item.shortContentId), [
      'short-1',
      'short-2',
    ]);
    expect(controller.currentPage.value, 1);
    expect(controller.hasMore.value, isFalse);
  });

  test('refresh replaces the feed from page zero', () async {
    controller.items.assignAll([_item()]);
    controller.currentPage.value = 2;
    controller.hasMore.value = false;
    when(
      () => repository.getFeed(page: 0, size: 20, category: null),
    ).thenAnswer(
      (_) async => _page(
        content: [_item().copyWith(shortContentId: 'fresh-1')],
        hasNext: true,
      ),
    );

    await controller.refreshFeed();

    expect(controller.items.single.shortContentId, 'fresh-1');
    expect(controller.currentPage.value, 0);
    expect(controller.hasMore.value, isTrue);
    expect(controller.isRefreshing.value, isFalse);
  });

  test('likes once and blocks a duplicate in-flight request', () async {
    controller.items.assignAll([_item()]);
    final completer = Completer<ShortContentModel>();
    when(() => repository.like('short-1')).thenAnswer((_) => completer.future);

    final first = controller.toggleLike('short-1');
    final duplicate = controller.toggleLike('short-1');

    expect(controller.isLiking('short-1'), isTrue);
    verify(() => repository.like('short-1')).called(1);

    completer.complete(_item(liked: true, likes: 1));
    await Future.wait([first, duplicate]);

    expect(controller.items.single.liked, isTrue);
    expect(controller.items.single.likeCount, 1);
    expect(controller.isLiking('short-1'), isFalse);
  });

  test('saves and unsaves from the backend state', () async {
    controller.items.assignAll([_item()]);
    final saveCompleter = Completer<ShortContentModel>();
    when(
      () => repository.save('short-1'),
    ).thenAnswer((_) => saveCompleter.future);
    when(
      () => repository.unsave('short-1'),
    ).thenAnswer((_) async => _item(saved: false, saves: 0));

    final firstSave = controller.toggleSave('short-1');
    final duplicateSave = controller.toggleSave('short-1');
    expect(controller.isSaving('short-1'), isTrue);
    verify(() => repository.save('short-1')).called(1);

    saveCompleter.complete(_item(saved: true, saves: 1));
    await Future.wait([firstSave, duplicateSave]);
    expect(controller.items.single.saved, isTrue);
    expect(controller.items.single.saveCount, 1);

    await controller.toggleSave('short-1');
    expect(controller.items.single.saved, isFalse);
    expect(controller.items.single.saveCount, 0);
    verify(() => repository.unsave('short-1')).called(1);
  });

  test('releases action lock and exposes action errors', () async {
    controller.items.assignAll([_item()]);
    when(
      () => repository.like('short-1'),
    ).thenThrow(const AppError(message: 'Like failed', errorCode: 'API_ERROR'));

    await controller.toggleLike('short-1');

    expect(controller.actionErrorMessage.value, 'Like failed');
    expect(controller.isLiking('short-1'), isFalse);
  });

  test('uploads video and publishes without an optional thumbnail', () async {
    ShortContentCreateRequest? request;
    final created = _item().copyWith(
      shortContentId: 'created-1',
      videoUrl: 'https://cdn.example.com/media-1',
      thumbnailUrl: null,
    );
    when(() => repository.create(any())).thenAnswer((invocation) async {
      request =
          invocation.positionalArguments.first as ShortContentCreateRequest;
      return created;
    });

    final result = await controller.createShortContent(
      title: '  New short  ',
      description: 'Description',
      category: 'FOCUS',
      video: PickedMedia(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'video/mp4',
        path: '/tmp/video.mp4',
      ),
    );

    expect(result?.shortContentId, 'created-1');
    expect(request?.title, 'New short');
    expect(request?.videoUrl, 'https://cdn.example.com/media-1');
    expect(request?.thumbnailUrl, isNull);
    expect(request?.videoMediaId, 'media-1');
    expect(request?.thumbnailMediaId, isNull);
    expect(mediaRepository.mediaTypes, {'media-1': 'video/mp4'});
    expect(controller.items.first.shortContentId, 'created-1');
    expect(controller.uploadProgress.value, 1);
    expect(controller.isCreating.value, isFalse);
  });

  test(
    'uploads an optional thumbnail and blocks duplicate publishes',
    () async {
      final createCompleter = Completer<ShortContentModel>();
      ShortContentCreateRequest? request;
      when(() => repository.create(any())).thenAnswer((invocation) {
        request =
            invocation.positionalArguments.first as ShortContentCreateRequest;
        return createCompleter.future;
      });

      final video = PickedMedia(
        bytes: Uint8List.fromList([1]),
        contentType: 'video/mp4',
      );
      final thumbnail = PickedMedia(
        bytes: Uint8List.fromList([2]),
        contentType: 'image/jpeg',
      );
      final first = controller.createShortContent(
        title: 'New short',
        video: video,
        thumbnail: thumbnail,
      );
      final duplicate = controller.createShortContent(
        title: 'Duplicate',
        video: video,
        thumbnail: thumbnail,
      );

      expect(controller.isCreating.value, isTrue);

      createCompleter.complete(_item().copyWith(shortContentId: 'created-2'));
      await Future.wait([first, duplicate]);

      verify(() => repository.create(any())).called(1);
      expect(mediaRepository.mediaTypes, {
        'media-1': 'video/mp4',
        'media-2': 'image/jpeg',
      });
      expect(request?.thumbnailUrl, 'https://cdn.example.com/media-2');
      expect(request?.videoMediaId, 'media-1');
      expect(request?.thumbnailMediaId, 'media-2');
      expect(controller.isCreating.value, isFalse);
    },
  );

  test(
    'deletes once, removes the item, and blocks duplicate requests',
    () async {
      controller.items.assignAll([_item()]);
      final completer = Completer<void>();
      when(
        () => repository.delete('short-1'),
      ).thenAnswer((_) => completer.future);

      final first = controller.delete('short-1');
      final duplicate = controller.delete('short-1');

      expect(controller.isDeleting('short-1'), isTrue);
      verify(() => repository.delete('short-1')).called(1);

      completer.complete();
      expect(await first, isTrue);
      expect(await duplicate, isFalse);
      expect(controller.items, isEmpty);
      expect(controller.isDeleting('short-1'), isFalse);
    },
  );

  test('keeps content when delete fails and releases the lock', () async {
    controller.items.assignAll([_item()]);
    when(() => repository.delete('short-1')).thenThrow(
      const AppError(message: 'Delete failed', errorCode: 'API_ERROR'),
    );

    expect(await controller.delete('short-1'), isFalse);
    expect(controller.items.single.shortContentId, 'short-1');
    expect(controller.actionErrorMessage.value, 'Delete failed');
    expect(controller.isDeleting('short-1'), isFalse);
  });

  test('cleans confirmed media when publishing fails', () async {
    when(() => repository.create(any())).thenThrow(
      const AppError(message: 'Publish failed', errorCode: 'API_ERROR'),
    );

    final result = await controller.createShortContent(
      title: 'New short',
      video: PickedMedia(
        bytes: Uint8List.fromList([1]),
        contentType: 'video/mp4',
      ),
      thumbnail: PickedMedia(
        bytes: Uint8List.fromList([2]),
        contentType: 'image/jpeg',
      ),
    );

    expect(result, isNull);
    expect(controller.createErrorMessage.value, 'Publish failed');
    expect(mediaRepository.deletedMediaIds, ['media-2', 'media-1']);
    expect(controller.isCreating.value, isFalse);
  });
}
