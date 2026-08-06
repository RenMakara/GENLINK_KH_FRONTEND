/// What a media object is for. Must match the backend `MediaPurpose` enum —
/// the wire value is the enum name in upper case.
///
/// The backend allows video only for [story] and [short]; every other purpose
/// is images and rejects a video content type with `MEDIA_VIDEO_NOT_ALLOWED`.
enum MediaPurpose {
  avatar,
  post,
  story,
  short,
  eventCover,
  communityCover,
  portfolio;

  /// The value the backend expects, e.g. `EVENT_COVER`.
  String get wireValue => switch (this) {
        MediaPurpose.avatar => 'AVATAR',
        MediaPurpose.post => 'POST',
        MediaPurpose.story => 'STORY',
        MediaPurpose.short => 'SHORT',
        MediaPurpose.eventCover => 'EVENT_COVER',
        MediaPurpose.communityCover => 'COMMUNITY_COVER',
        MediaPurpose.portfolio => 'PORTFOLIO',
      };

  /// Whether the backend will accept a video for this purpose. Checked before
  /// presigning so the user gets an immediate message instead of a round trip.
  bool get allowsVideo =>
      this == MediaPurpose.story || this == MediaPurpose.short;
}

/// A presigned upload target returned by `POST /media/presign`.
class PresignedUpload {
  const PresignedUpload({
    required this.mediaId,
    required this.uploadUrl,
    required this.storageKey,
    required this.requiredHeaders,
    required this.expiresInSeconds,
  });

  final String mediaId;

  /// Absolute URL at the storage provider — **not** our API. It carries its own
  /// authorisation, so the upload must not send our bearer token.
  final String uploadUrl;

  final String storageKey;

  /// Headers the upload must send verbatim; the signature covers them, so a
  /// missing or altered value is rejected with 403.
  final Map<String, String> requiredHeaders;

  final int expiresInSeconds;
}

/// A confirmed media object, as stored by the backend.
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

  /// CDN url for public media. Features store [mediaId] and render this.
  final String url;

  final String contentType;
  final int sizeBytes;
  final String? checksumSha256;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime? uploadedAt;

  bool get isVideo => contentType.startsWith('video/');
}
