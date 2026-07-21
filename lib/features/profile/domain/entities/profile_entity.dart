/// Owner-only profile, from `GET /api/v1/profile/me`.
///
/// The public view ([PublicProfileEntity]) deliberately omits email, phone,
/// date of birth, gender and account status.
class ProfileEntity {
  const ProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
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
  final String? bio;

  /// ISO-8601 date (`yyyy-MM-dd`), matching the backend `LocalDate`.
  final String? dateOfBirth;

  /// MALE / FEMALE / OTHER / PREFER_NOT_TO_SAY
  final String? gender;
  final String? universityName;

  /// STUDENT / FRESH_GRADUATE / YOUNG_PROFESSIONAL / CREATOR /
  /// FREELANCER / ENTREPRENEUR / OTHER
  final String? workStatus;
  final String? location;
  final bool emailVerified;

  /// PENDING / ACTIVE / BANNED / DELETED
  final String accountStatus;
  final int totalXp;
  final int level;

  /// ENGLISH / KHMER
  final String preferredLanguage;

  /// XP width of one level, matching the backend's
  /// `level = 1 + total_xp / 100`.
  static const xpPerLevel = 100;

  /// XP earned inside the current level.
  int get xpIntoLevel => totalXp % xpPerLevel;

  /// Total XP needed to reach the next level.
  int get xpForNextLevel => level * xpPerLevel;

  double get levelProgress => xpIntoLevel / xpPerLevel;

  /// How complete the profile is, as a 0–1 fraction.
  ///
  /// Computed on the client because the backend has no such field. The
  /// weighting is flat: each optional field a user can fill counts once.
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

/// A badge from `GET /api/v1/entertainment/badges`.
///
/// The catalog is returned in full with [earned] set per user, so the
/// achievements row can show unlocked and locked badges together.
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

/// A saved row from `GET /api/v1/profile/saved`.
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

  /// POST / DISCUSSION / EVENT / OPPORTUNITY / MOTIVATION / LESSON /
  /// SHORT_CONTENT
  final String itemType;
  final String itemId;
  final String? savedAt;

  /// False when the saved thing has since been deleted — `saved_items` is
  /// polymorphic, so the row can outlive its target. Render a "no longer
  /// available" tile rather than a blank one.
  final bool available;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
}

/// Public-safe profile, from `GET /api/v1/profile/public/{username}`.
class PublicProfileEntity {
  const PublicProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
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

/// A portfolio item. `description`, `link` and `imageUrl` are all optional.
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

/// An interest. `name` arrives already resolved to the caller's language —
/// the client never chooses between `name_en` and `name_km`.
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

/// A social link. One per platform — posting the same platform twice
/// replaces the existing link rather than adding a second.
class SocialLinkEntity {
  const SocialLinkEntity({required this.platform, required this.url});

  /// FACEBOOK / INSTAGRAM / TELEGRAM / TIKTOK / YOUTUBE / LINKEDIN /
  /// GITHUB / X / WEBSITE / OTHER
  final String platform;
  final String url;
}
