import 'dart:typed_data';

import '../entities/media_entity.dart';

abstract interface class MediaRepository {
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  });

  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  });

  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  });

  Future<void> delete(String mediaId);
}
