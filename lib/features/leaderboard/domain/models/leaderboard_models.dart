enum LeaderboardCategory {
  overallXp,
  productivity,
  communityEngagement,
  financialLearning,
  quizPerformance,
}

extension LeaderboardCategoryValues on LeaderboardCategory {
  String get apiValue => switch (this) {
    LeaderboardCategory.overallXp => 'OVERALL_XP',
    LeaderboardCategory.productivity => 'PRODUCTIVITY',
    LeaderboardCategory.communityEngagement => 'COMMUNITY_ENGAGEMENT',
    LeaderboardCategory.financialLearning => 'FINANCIAL_LEARNING',
    LeaderboardCategory.quizPerformance => 'QUIZ_PERFORMANCE',
  };

  String get translationKey => switch (this) {
    LeaderboardCategory.overallXp => 'leaderboard.categoryOverallXp',
    LeaderboardCategory.productivity => 'leaderboard.categoryProductivity',
    LeaderboardCategory.communityEngagement => 'leaderboard.categoryCommunity',
    LeaderboardCategory.financialLearning =>
      'leaderboard.categoryFinancialLearning',
    LeaderboardCategory.quizPerformance => 'leaderboard.categoryQuiz',
  };

  static LeaderboardCategory fromApiValue(String? value) {
    return switch (value?.toUpperCase()) {
      'PRODUCTIVITY' => LeaderboardCategory.productivity,
      'COMMUNITY_ENGAGEMENT' => LeaderboardCategory.communityEngagement,
      'FINANCIAL_LEARNING' => LeaderboardCategory.financialLearning,
      'QUIZ_PERFORMANCE' => LeaderboardCategory.quizPerformance,
      _ => LeaderboardCategory.overallXp,
    };
  }
}

enum LeaderboardPeriod { weekly, monthly, allTime }

extension LeaderboardPeriodValues on LeaderboardPeriod {
  String get apiValue => switch (this) {
    LeaderboardPeriod.weekly => 'WEEKLY',
    LeaderboardPeriod.monthly => 'MONTHLY',
    LeaderboardPeriod.allTime => 'ALL_TIME',
  };

  String get translationKey => switch (this) {
    LeaderboardPeriod.weekly => 'leaderboard.periodWeekly',
    LeaderboardPeriod.monthly => 'leaderboard.periodMonthly',
    LeaderboardPeriod.allTime => 'leaderboard.periodAllTime',
  };

  static LeaderboardPeriod fromApiValue(String? value) {
    return switch (value?.toUpperCase()) {
      'WEEKLY' => LeaderboardPeriod.weekly,
      'MONTHLY' => LeaderboardPeriod.monthly,
      _ => LeaderboardPeriod.allTime,
    };
  }
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int rank;
  final int level;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.rank,
    required this.level,
    required this.points,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    int? rank,
    int? level,
    int? points,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      points: points ?? this.points,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class LeaderboardMe {
  final int? rank;
  final int points;

  const LeaderboardMe({this.rank, required this.points});

  factory LeaderboardMe.fromJson(Map<String, dynamic> json) {
    return LeaderboardMe(
      rank: (json['rank'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardResponse {
  final LeaderboardCategory category;
  final LeaderboardPeriod period;
  final List<LeaderboardEntry> entries;
  final LeaderboardMe? me;

  const LeaderboardResponse({
    required this.category,
    required this.period,
    required this.entries,
    this.me,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List? ?? const [];
    final rawMe = json['me'];
    return LeaderboardResponse(
      category: LeaderboardCategoryValues.fromApiValue(
        json['category']?.toString(),
      ),
      period: LeaderboardPeriodValues.fromApiValue(json['period']?.toString()),
      entries: rawEntries
          .whereType<Map>()
          .map(
            (entry) => LeaderboardEntry.fromJson(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
      me: rawMe is Map
          ? LeaderboardMe.fromJson(rawMe.cast<String, dynamic>())
          : null,
    );
  }

  LeaderboardResponse markCurrentUserByRank() {
    final rank = me?.rank;
    if (rank == null) return this;
    return LeaderboardResponse(
      category: category,
      period: period,
      entries: entries
          .map((entry) => entry.copyWith(isCurrentUser: entry.rank == rank))
          .toList(growable: false),
      me: me,
    );
  }
}
