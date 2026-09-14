class ProfileEntity {
  const ProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.coverPreset = 0,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.universityName,
    this.workStatus,
    this.location,
    required this.emailVerified,
    required this.accountStatus,
    required this.totalXp,
    required this.level,
    required this.preferredLanguage,
  });

  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final int coverPreset;
  final String? bio;

  final String? dateOfBirth;

  final String? gender;
  final String? universityName;

  final String? workStatus;
  final String? location;
  final bool emailVerified;

  final String accountStatus;
  final int totalXp;
  final int level;

  final String preferredLanguage;

  static const xpPerLevel = 100;

  int get xpIntoLevel => totalXp % xpPerLevel;

  int get xpForNextLevel => level * xpPerLevel;

  double get levelProgress => xpIntoLevel / xpPerLevel;

  double get completion {
    final fields = <Object?>[
      fullName,
      username,
      avatarUrl,
      bio,
      location,
      universityName,
      workStatus,
      dateOfBirth,
      gender,
      phoneNumber,
    ];
    final filled = fields
        .where((f) => f != null && (f is! String || f.trim().isNotEmpty))
        .length;
    return filled / fields.length;
  }

  int get completionPercent => (completion * 100).round();
}

class BadgeEntity {
  const BadgeEntity({
    required this.badgeId,
    required this.name,
    this.description,
    this.requirement,
    this.iconUrl,
    required this.earned,
    this.unlockedAt,
  });

  final String badgeId;
  final String name;
  final String? description;
  final String? requirement;
  final String? iconUrl;
  final bool earned;
  final String? unlockedAt;
}

class SavedItemEntity {
  const SavedItemEntity({
    required this.savedItemId,
    required this.itemType,
    required this.itemId,
    this.savedAt,
    required this.available,
    this.title,
    this.subtitle,
    this.imageUrl,
  });

  final String savedItemId;

  final String itemType;
  final String itemId;
  final String? savedAt;

  final bool available;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
}

class PublicProfileEntity {
  const PublicProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.coverPreset = 0,
    this.bio,
    this.universityName,
    this.workStatus,
    this.location,
    required this.totalXp,
    required this.level,
    this.joinedAt,
    this.portfolio = const [],
    this.interests = const [],
    this.socialLinks = const [],
  });

  final String userId;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final int coverPreset;
  final String? bio;
  final String? universityName;
  final String? workStatus;
  final String? location;
  final int totalXp;
  final int level;
  final String? joinedAt;
  final List<PortfolioItemEntity> portfolio;
  final List<InterestEntity> interests;
  final List<SocialLinkEntity> socialLinks;
}

/// The viewer's relationship with a public profile.
///
/// The API returns `ACCEPTED`, `PENDING`, or `null` for [followStatus].
/// Keeping this data beside the public profile lets the UI render a truthful
/// Follow / Requested / Following state instead of a placeholder action.
class FollowStatsEntity {
  const FollowStatsEntity({
    required this.followers,
    required this.following,
    this.followStatus,
    required this.friend,
  });

  final int followers;
  final int following;
  final String? followStatus;
  final bool friend;

  bool get isFollowing =>
      followStatus == 'ACCEPTED' || followStatus == 'PENDING';

  bool get isAccepted => followStatus == 'ACCEPTED';
}

class PortfolioItemEntity {
  const PortfolioItemEntity({
    required this.portfolioId,
    required this.title,
    this.description,
    this.link,
    this.imageUrl,
  });

  final String portfolioId;
  final String title;
  final String? description;
  final String? link;
  final String? imageUrl;
}

class InterestEntity {
  const InterestEntity({
    required this.interestId,
    required this.code,
    required this.name,
    this.category,
  });

  final String interestId;
  final String code;
  final String name;
  final String? category;
}

class SocialLinkEntity {
  const SocialLinkEntity({required this.platform, required this.url});

  final String platform;
  final String url;
}
