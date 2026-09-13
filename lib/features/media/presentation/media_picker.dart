import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.contentType,
    this.width,
    this.height,
    this.path,
  });

  final Uint8List bytes;
  final String contentType;
  final int? width;
  final int? height;
  final String? path;
}

class MediaPicker {
  MediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxDimension = 1920.0;

  static const _quality = 85;

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
      contentType: 'image/jpeg',
      path: file.path,
    );
  }

  Future<PickedMedia?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration maxDuration = const Duration(minutes: 5),
  }) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedMedia(
      bytes: bytes,
      contentType: videoTypeFor(file.path),
      path: file.path,
    );
  }

  @visibleForTesting
  static String videoTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
}
