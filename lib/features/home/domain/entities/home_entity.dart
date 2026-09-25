import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';

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

  static const xpPerLevel = 100;

  int get xpIntoLevel => safeTotalXp % xpPerLevel;
  int get xpForNextLevel => safeLevel * xpPerLevel;
  double get levelProgress => (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);
  int get percentToNext => (levelProgress * 100).round();

  String get firstName {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }
}

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
    this.challengeType,
    this.type,
  });

  final String challengeId;
  final String title;
  final String? description;
  final int? xpReward;
  final String? deadline;
  final ChallengeType? challengeType;
  final String? type;

  ChallengeType get resolvedType {
    if (challengeType != null) {
      if (challengeType != ChallengeType.unknown) return challengeType!;
      if (type != null && type!.isNotEmpty) return ChallengeType.unknown;
    }
    if (type != null && type!.isNotEmpty) {
      return challengeTypeFromWire(type);
    }
    final text = '${title.toLowerCase()} ${(description ?? '').toLowerCase()}';
    if (text.contains('habit') || text.contains('ទម្លាប់')) {
      return ChallengeType.habit;
    }
    if (text.contains('task') || text.contains('កិច្ចការ')) {
      return ChallengeType.task;
    }
    if (text.contains('quiz') || text.contains('សំណួរ') || text.contains('កម្រងសំណួរ')) {
      return ChallengeType.quiz;
    }
    if (text.contains('expense') ||
        text.contains('budget') ||
        text.contains('finance') ||
        text.contains('ចំណាយ') ||
        text.contains('ថវិកា') ||
        text.contains('សន្សំ')) {
      return ChallengeType.finance;
    }
    if (text.contains('focus') ||
        text.contains('session') ||
        text.contains('deep work') ||
        text.contains('ការផ្តោតអារម្មណ៍')) {
      return ChallengeType.focus;
    }
    return ChallengeType.unknown;
  }

  ChallengePreview copyWith({
    String? challengeId,
    String? title,
    String? description,
    int? xpReward,
    String? deadline,
    ChallengeType? challengeType,
    String? type,
  }) {
    return ChallengePreview(
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      deadline: deadline ?? this.deadline,
      challengeType: challengeType ?? this.challengeType,
      type: type ?? this.type,
    );
  }
}

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

  final String? createdAt;
}
