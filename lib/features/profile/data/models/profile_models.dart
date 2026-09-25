import '../../domain/entities/profile_entity.dart';

abstract final class ProfileMapper {
  static ProfileEntity profile(Map<String, dynamic> json) {
    return ProfileEntity(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverPreset: _coverPreset(json['coverPreset']),
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
      preferredLanguage: json['preferredLanguage'] as String? ?? 'ENGLISH',
    );
  }

  static PublicProfileEntity publicProfile(Map<String, dynamic> json) {
    return PublicProfileEntity(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      coverPreset: _coverPreset(json['coverPreset']),
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

  static FollowStatsEntity followStats(Map<String, dynamic> json) {
    return FollowStatsEntity(
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      followStatus: json['followStatus'] as String?,
      friend: json['friend'] as bool? ?? false,
    );
  }

  static PortfolioItemEntity portfolioItem(Map<String, dynamic> json) {
    return PortfolioItemEntity(
      portfolioId: json['portfolioId']?.toString() ??
          json['id']?.toString() ??
          '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      link: json['link']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
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
    int? coverPreset,
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
      'coverPreset': coverPreset,
    }..removeWhere((_, value) => value == null);
    return body;
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) item) {
    final list = raw as List? ?? const [];
    return list
        .map((e) => item((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  static int _coverPreset(dynamic value) {
    final preset = (value as num?)?.toInt() ?? 0;
    return preset.clamp(0, 9).toInt();
  }
}
