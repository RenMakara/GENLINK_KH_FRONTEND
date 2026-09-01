import '../../domain/entities/profile_entity.dart';

/// Wire models for the profile module.
///
/// Every field is read defensively — the backend serialises enums as their
/// names and `LocalDate` as `yyyy-MM-dd`, both of which arrive as strings.
abstract final class ProfileMapper {
  static ProfileEntity profile(Map<String, dynamic> json) {
    return ProfileEntity(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      universityName: json['universityName'] as String?,
      workStatus: json['workStatus'] as String?,
      location: json['location'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      accountStatus: json['accountStatus'] as String? ?? 'PENDING',
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      // English is the system default (backend APP_DEFAULT_LANGUAGE=ENGLISH,
      // LocalizationService, UserSettingsEntity). Defaulting to KHMER here
      // silently flipped the whole UI to Khmer whenever the field was absent.
      preferredLanguage: json['preferredLanguage'] as String? ?? 'ENGLISH',
    );
  }

  static PublicProfileEntity publicProfile(Map<String, dynamic> json) {
    return PublicProfileEntity(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      universityName: json['universityName'] as String?,
      workStatus: json['workStatus'] as String?,
      location: json['location'] as String?,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      joinedAt: json['joinedAt'] as String?,
      portfolio: _list(json['portfolio'], portfolioItem),
      interests: _list(json['interests'], interest),
      socialLinks: _list(json['socialLinks'], socialLink),
    );
  }

  static PortfolioItemEntity portfolioItem(Map<String, dynamic> json) {
    return PortfolioItemEntity(
      portfolioId: json['portfolioId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      link: json['link'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static InterestEntity interest(Map<String, dynamic> json) {
    return InterestEntity(
      interestId: json['interestId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  static BadgeEntity badge(Map<String, dynamic> json) {
    return BadgeEntity(
      badgeId: json['badgeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      requirement: json['requirement'] as String?,
      iconUrl: json['iconUrl'] as String?,
      earned: json['earned'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] as String?,
    );
  }

  static SavedItemEntity savedItem(Map<String, dynamic> json) {
    return SavedItemEntity(
      savedItemId: json['savedItemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? 'POST',
      itemId: json['itemId'] as String? ?? '',
      savedAt: json['savedAt'] as String?,
      available: json['available'] as bool? ?? true,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static SocialLinkEntity socialLink(Map<String, dynamic> json) {
    return SocialLinkEntity(
      platform: json['platform'] as String? ?? 'OTHER',
      url: json['url'] as String? ?? '',
    );
  }

  /// Body for `PUT /profile/me`.
  ///
  /// Null entries are stripped: the backend treats the request as a partial
  /// patch, so sending `null` for an untouched field would be a no-op at
  /// best and ambiguous at worst.
  static Map<String, dynamic> profileUpdateBody({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? universityName,
    String? workStatus,
    String? location,
    String? preferredLanguage,
  }) {
    final body = <String, dynamic>{
      'fullName': fullName,
      'username': username,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'universityName': universityName,
      'workStatus': workStatus,
      'location': location,
      'preferredLanguage': preferredLanguage,
    }..removeWhere((_, value) => value == null);
    return body;
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) item) {
    final list = raw as List? ?? const [];
    return list
        .map((e) => item((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
