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

  HomeEntity copyWith({
    HomeUser? user,
    TodayProgress? todayProgress,
    ChallengePreview? dailyChallenge,
    FinanceSnapshot? financeSnapshot,
    UpcomingEvent? upcomingEvent,
    List<CommunitySuggestion>? recommendedCommunities,
    MotivationCard? dailyMotivation,
    List<FeedPreview>? feedPreview,
  }) {
    return HomeEntity(
      user: user ?? this.user,
      todayProgress: todayProgress ?? this.todayProgress,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      financeSnapshot: financeSnapshot ?? this.financeSnapshot,
      upcomingEvent: upcomingEvent ?? this.upcomingEvent,
      recommendedCommunities:
          recommendedCommunities ?? this.recommendedCommunities,
      dailyMotivation: dailyMotivation ?? this.dailyMotivation,
      feedPreview: feedPreview ?? this.feedPreview,
    );
  }
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

  int get safeLevel => level > 0 ? level : 1;
  int get safeTotalXp => totalXp >= 0 ? totalXp : 0;

  /// Levels are 100 XP wide (`level = 1 + total_xp / 100` on the backend).
  static const xpPerLevel = 100;

  int get xpIntoLevel => safeTotalXp % xpPerLevel;
  int get xpForNextLevel => safeLevel * xpPerLevel;
  double get levelProgress => (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);
  int get percentToNext => (levelProgress * 100).round();

  /// First name only, for the greeting.
  String get firstName {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }
}

/// Drives the Today Hub progress. Totals can be 0 — guard the divide safely.
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

  double get progress =>
      totalCount <= 0 ? 0.0 : (doneCount / totalCount).clamp(0.0, 1.0);
  int get percent => (progress * 100).round();

  TodayProgress copyWith({
    int? habitsCompletedToday,
    int? habitsTotal,
    int? tasksCompleted,
    int? tasksTotal,
  }) {
    return TodayProgress(
      habitsCompletedToday: habitsCompletedToday ?? this.habitsCompletedToday,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksTotal: tasksTotal ?? this.tasksTotal,
    );
  }
}

class HabitItemEntity {
  const HabitItemEntity({
    required this.habitId,
    required this.title,
    this.category,
    this.frequency,
    this.streakCount = 0,
    this.checkedInToday = false,
  });

  final String habitId;
  final String title;
  final String? category;
  final String? frequency;
  final int streakCount;
  final bool checkedInToday;

  HabitItemEntity copyWith({
    String? habitId,
    String? title,
    String? category,
    String? frequency,
    int? streakCount,
    bool? checkedInToday,
  }) {
    return HabitItemEntity(
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      streakCount: streakCount ?? this.streakCount,
      checkedInToday: checkedInToday ?? this.checkedInToday,
    );
  }
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
    this.description,
    this.category,
    this.participantCount,
  });

  final String eventId;
  final String title;
  final String? dateTime;
  final String? locationName;
  final String? coverImageUrl;
  final String? description;
  final String? category;
  final int? participantCount;
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
  const MotivationCard({required this.motivationId, this.title, this.content});

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
    this.commentCount,
    this.communityName,
    this.createdAt,
  });

  final String postId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? contentText;
  final String? imageUrl;
  final int? likeCount;
  final int? commentCount;
  final String? communityName;

  /// ISO-8601 instant.
  final String? createdAt;
}
