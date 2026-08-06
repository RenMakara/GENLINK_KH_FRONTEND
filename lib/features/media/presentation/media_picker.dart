import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// A file chosen by the user, already compressed and read into memory.
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.contentType,
    this.width,
    this.height,
  });

  final Uint8List bytes;
  final String contentType;
  final int? width;
  final int? height;
}

/// Thin wrapper over `image_picker` that returns upload-ready bytes.
///
/// Compression is done by the picker itself (`imageQuality` re-encodes,
/// `maxWidth`/`maxHeight` downscale), which happens natively before the file is
/// handed over — no extra plugin, and the phone never decodes a 12 MP photo
/// into Dart memory. This is a bandwidth and UX optimisation only: the backend
/// enforces its own limits regardless of what the client sends.
class MediaPicker {
  MediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Longest edge after downscaling. 1920 keeps a photo sharp on any phone
  /// screen while cutting a typical camera shot by an order of magnitude.
  static const _maxDimension = 1920.0;

  /// JPEG quality. 85 is the usual sweet spot — visually indistinguishable
  /// from the original at a fraction of the size.
  static const _quality = 85;

  /// Pick an image and return its compressed bytes, or null if cancelled.
  Future<PickedMedia?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedMedia(
      bytes: bytes,
      // The picker re-encodes to JPEG whenever imageQuality is set, so the
      // original extension is not a reliable indicator of the result.
      contentType: 'image/jpeg',
    );
  }

  /// Pick a video and return its bytes, or null if cancelled.
  ///
  /// Not compressed: transcoding needs a heavyweight native dependency, and the
  /// picker cannot do it. [maxDuration] keeps the file small at the source
  /// instead, which is the cheaper lever.
  Future<PickedMedia?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedMedia(bytes: bytes, contentType: videoTypeFor(file.path));
  }

  /// Content type from the file extension. The presigned URL signs this exact
  /// value, so it has to describe the real container.
  @visibleForTesting
  static String videoTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
}
