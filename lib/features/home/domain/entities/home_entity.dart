/// The Home Super Dashboard payload, from `GET /api/v1/mobile/home`.
///
/// Card fields are nullable on purpose — a brand-new user has no budget, no
/// RSVP and possibly no challenge. Null means "render that card's empty
/// state", not an error. Lists are empty rather than null.
class HomeEntity {
  const HomeEntity({
    required this.user,
    required this.todayProgress,
    this.dailyChallenge,
    this.financeSnapshot,
    this.upcomingEvent,
    this.recommendedCommunities = const [],
    this.dailyMotivation,
    this.feedPreview = const [],
  });

  final HomeUser user;
  final TodayProgress todayProgress;
  final ChallengePreview? dailyChallenge;
  final FinanceSnapshot? financeSnapshot;
  final UpcomingEvent? upcomingEvent;
  final List<CommunitySuggestion> recommendedCommunities;
  final MotivationCard? dailyMotivation;
  final List<FeedPreview> feedPreview;
}

class HomeUser {
  const HomeUser({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    required this.level,
    required this.totalXp,
  });

  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final int level;
  final int totalXp;

  /// Levels are 100 XP wide (`level = 1 + total_xp / 100` on the backend).
  static const xpPerLevel = 100;

  int get xpIntoLevel => totalXp % xpPerLevel;
  int get xpForNextLevel => level * xpPerLevel;
  double get levelProgress => xpIntoLevel / xpPerLevel;
  int get percentToNext => (levelProgress * 100).round();

  /// First name only, for the greeting.
  String get firstName {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }
}

/// Drives the Today Hub progress. Totals can be 0 — guard the divide.
class TodayProgress {
  const TodayProgress({
    required this.habitsCompletedToday,
    required this.habitsTotal,
    required this.tasksCompleted,
    required this.tasksTotal,
  });

  final int habitsCompletedToday;
  final int habitsTotal;
  final int tasksCompleted;
  final int tasksTotal;

  int get doneCount => habitsCompletedToday + tasksCompleted;
  int get totalCount => habitsTotal + tasksTotal;

  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;
  int get percent => (progress * 100).round();
}

class ChallengePreview {
  const ChallengePreview({
    required this.challengeId,
    required this.title,
    this.description,
    this.xpReward,
    this.deadline,
  });

  final String challengeId;
  final String title;
  final String? description;
  final int? xpReward;
  final String? deadline;
}

/// Note: amounts come from the cached budget columns, which the backend
/// documents as a known follow-up (live spend is on the finance dashboard).
class FinanceSnapshot {
  const FinanceSnapshot({
    this.totalBudget,
    this.spentAmount,
    this.remainingAmount,
    this.budgetStatus,
    this.savingTarget,
    this.savingCurrent,
  });

  final double? totalBudget;
  final double? spentAmount;
  final double? remainingAmount;

  /// SAFE / WARNING / LIMIT_REACHED
  final String? budgetStatus;
  final double? savingTarget;
  final double? savingCurrent;
}

class UpcomingEvent {
  const UpcomingEvent({
    required this.eventId,
    required this.title,
    this.dateTime,
    this.locationName,
    this.coverImageUrl,
  });

  final String eventId;
  final String title;
  final String? dateTime;
  final String? locationName;
  final String? coverImageUrl;
}

class CommunitySuggestion {
  const CommunitySuggestion({
    required this.communityId,
    required this.name,
    this.slug,
    this.category,
    this.memberCount,
    this.avatarUrl,
  });

  final String communityId;
  final String name;
  final String? slug;
  final String? category;
  final int? memberCount;
  final String? avatarUrl;
}

class MotivationCard {
  const MotivationCard({
    required this.motivationId,
    this.title,
    this.content,
  });

  final String motivationId;
  final String? title;
  final String? content;
}

class FeedPreview {
  const FeedPreview({
    required this.postId,
    this.authorName,
    this.authorAvatarUrl,
    this.contentText,
    this.imageUrl,
    this.likeCount,
    this.createdAt,
  });

  final String postId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? contentText;
  final String? imageUrl;
  final int? likeCount;

  /// ISO-8601 instant.
  final String? createdAt;
}
