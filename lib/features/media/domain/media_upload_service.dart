import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/errors/app_error.dart';
import 'entities/media_entity.dart';
import 'repositories/media_repository.dart';

/// Progress of an in-flight upload, 0.0 → 1.0.
typedef UploadProgress = void Function(double fraction);

/// Runs the three-step upload as one call: presign → PUT → confirm.
///
/// Callers hand over bytes and get back a confirmed [MediaEntity] whose `url`
/// is ready to render. Everything awkward about the flow — hashing, the size
/// caps, sending the signed headers verbatim, converting byte counts into a
/// fraction — is handled here so no screen has to know about it.
///
/// Deliberately takes bytes rather than a `File`: it keeps the service free of
/// `dart:io` (so it works on web and is unit-testable without a filesystem),
/// and picking a file is the caller's concern.
class MediaUploadService {
  const MediaUploadService(this._repository);

  final MediaRepository _repository;

  /// Server-side caps, mirrored here so an oversize file fails instantly
  /// instead of after a round trip. The backend enforces them regardless —
  /// these are a courtesy, never the security boundary.
  static const maxImageBytes = 5 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  /// Upload [bytes] and return the confirmed media.
  ///
  /// [width], [height] and [durationMs] are read from the local file by the
  /// caller; the backend stores them but never inspects the bytes to verify.
  ///
  /// Throws [AppError] on validation failure or any step failing.
  Future<MediaEntity> upload({
    required Uint8List bytes,
    required String contentType,
    required MediaPurpose purpose,
    int? width,
    int? height,
    int? durationMs,
    UploadProgress? onProgress,
  }) async {
    _validate(bytes: bytes, contentType: contentType, purpose: purpose);

    // Hash the final bytes — after any compression the caller applied, so the
    // checksum describes what actually lands in storage.
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
        // Dio reports total as -1 when the length is unknown; fall back to the
        // length we already know rather than emitting a negative fraction.
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

  /// Soft-delete media the current user owns.
  Future<void> delete(String mediaId) => _repository.delete(mediaId);

  // ── Validation ────────────────────────────────────────────────────────

  void _validate({
    required Uint8List bytes,
    required String contentType,
    required MediaPurpose purpose,
  }) {
    if (bytes.isEmpty) {
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
    if (bytes.length > cap) {
      throw AppError(
        message: 'File is too large (max ${cap ~/ (1024 * 1024)} MB)',
        errorCode: 'MEDIA_TOO_LARGE',
      );
    }
  }
}
