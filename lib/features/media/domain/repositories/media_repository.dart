import 'dart:typed_data';

import '../entities/media_entity.dart';

/// Media upload, as three separable steps.
///
/// The middle step goes straight to the storage provider — the backend is never
/// in the byte path, so a large upload never occupies our server.
abstract interface class MediaRepository {
  /// Ask the backend to validate and reserve an upload slot.
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  });

  /// PUT the bytes directly to the storage provider.
  ///
  /// [onProgress] reports bytes sent so a screen can show real progress on a
  /// large video rather than an indeterminate spinner.
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  });

  /// Tell the backend the upload finished, with dimensions read locally.
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  });

  /// Soft-delete media the current user owns.
  Future<void> delete(String mediaId);
}
