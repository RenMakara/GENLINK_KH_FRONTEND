import '../../domain/entities/media_entity.dart';

/// Wire models for the media endpoints.
///
/// Kept separate from the entities so a backend rename never reaches the UI.
abstract final class MediaMapper {
  static PresignedUpload presignFrom(Map<String, dynamic> json) {
    final headers =
        (json['requiredHeaders'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return PresignedUpload(
      mediaId: json['mediaId'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      storageKey: json['storageKey'] as String? ?? '',
      requiredHeaders: headers.map((k, v) => MapEntry(k, '$v')),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
    );
  }

  static MediaEntity mediaFrom(Map<String, dynamic> json) => MediaEntity(
    mediaId: json['mediaId'] as String? ?? '',
    url: json['url'] as String? ?? '',
    contentType: json['contentType'] as String? ?? '',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    checksumSha256: json['checksumSha256'] as String?,
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    durationMs: (json['durationMs'] as num?)?.toInt(),
    uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? ''),
  );
}
