import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/errors/app_error.dart';
import 'entities/media_entity.dart';
import 'repositories/media_repository.dart';

typedef UploadProgress = void Function(double fraction);

class MediaUploadService {
  const MediaUploadService(this._repository);

  final MediaRepository _repository;

  static const maxImageBytes = 5 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  Future<MediaEntity> upload({
    required Uint8List bytes,
    required String contentType,
    required MediaPurpose purpose,
    int? width,
    int? height,
    int? durationMs,
    UploadProgress? onProgress,
  }) async {
    validateFile(
      sizeBytes: bytes.length,
      contentType: contentType,
      purpose: purpose,
    );

    final checksum = sha256.convert(bytes).toString();

    final target = await _repository.presign(
      contentType: contentType,
      sizeBytes: bytes.length,
      purpose: purpose,
      checksumSha256: checksum,
    );

    onProgress?.call(0);
    await _repository.uploadBytes(
      target: target,
      bytes: bytes,
      onProgress: (sent, total) {
        final divisor = total > 0 ? total : bytes.length;
        if (divisor > 0) onProgress?.call((sent / divisor).clamp(0.0, 1.0));
      },
    );
    onProgress?.call(1);

    return _repository.confirm(
      mediaId: target.mediaId,
      width: width,
      height: height,
      durationMs: durationMs,
    );
  }

  Future<void> delete(String mediaId) => _repository.delete(mediaId);

  /// Validates file metadata before callers load a large local file into memory.
  void validateFile({
    required int sizeBytes,
    required String contentType,
    required MediaPurpose purpose,
  }) {
    if (sizeBytes <= 0) {
      throw const AppError(
        message: 'The selected file is empty',
        errorCode: 'MEDIA_EMPTY',
      );
    }

    final isVideo = contentType.startsWith('video/');
    final isImage = contentType.startsWith('image/');

    if (!isVideo && !isImage) {
      throw AppError(
        message: 'Unsupported file type: $contentType',
        errorCode: 'MEDIA_INVALID_TYPE',
      );
    }
    if (isVideo && !purpose.allowsVideo) {
      throw const AppError(
        message: 'Video is not allowed here',
        errorCode: 'MEDIA_VIDEO_NOT_ALLOWED',
      );
    }

    final cap = isVideo ? maxVideoBytes : maxImageBytes;
    if (sizeBytes > cap) {
      throw AppError(
        message: 'File is too large (max ${cap ~/ (1024 * 1024)} MB)',
        errorCode: 'MEDIA_TOO_LARGE',
      );
    }
  }
}
