enum MediaPurpose {
  avatar,
  post,
  story,
  short,
  eventCover,
  communityCover,
  portfolio;

  String get wireValue => switch (this) {
        MediaPurpose.avatar => 'AVATAR',
        MediaPurpose.post => 'POST',
        MediaPurpose.story => 'STORY',
        MediaPurpose.short => 'SHORT',
        MediaPurpose.eventCover => 'EVENT_COVER',
        MediaPurpose.communityCover => 'COMMUNITY_COVER',
        MediaPurpose.portfolio => 'PORTFOLIO',
      };

  bool get allowsVideo =>
      this == MediaPurpose.post ||
      this == MediaPurpose.story ||
      this == MediaPurpose.short;
}

class PresignedUpload {
  const PresignedUpload({
    required this.mediaId,
    required this.uploadUrl,
    required this.storageKey,
    required this.requiredHeaders,
    required this.expiresInSeconds,
  });

  final String mediaId;

  final String uploadUrl;

  final String storageKey;

  final Map<String, String> requiredHeaders;

  final int expiresInSeconds;
}

class MediaEntity {
  const MediaEntity({
    required this.mediaId,
    required this.url,
    required this.contentType,
    required this.sizeBytes,
    this.checksumSha256,
    this.width,
    this.height,
    this.durationMs,
    this.uploadedAt,
  });

  final String mediaId;

  final String url;

  final String contentType;
  final int sizeBytes;
  final String? checksumSha256;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime? uploadedAt;

  /// Opaque upload reference. Community post/story endpoints resolve it after
  /// applying the owning content's audience policy.
  String get reference => 'genlink-media://$mediaId';

  bool get isVideo => contentType.startsWith('video/');
}
