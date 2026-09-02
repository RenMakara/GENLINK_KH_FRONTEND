enum QuizType { single, random }
<<<<<<< Updated upstream
=======

class QuizSummary {
  final String quizId;
  final String title;
  final String? category;
  final String difficulty;
  final int xpReward;
  final int questionCount;

  const QuizSummary({
    required this.quizId,
    required this.title,
    this.category,
    required this.difficulty,
    required this.xpReward,
    required this.questionCount,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      quizId: (json['quizId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: json['category']?.toString(),
      difficulty: (json['difficulty'] ?? '').toString(),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
>>>>>>> Stashed changes

class QuizCategory {
  final String id;
  final String name;
  final String icon;
  final int questionCount;
  final int colorIndex;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.questionCount,
    this.colorIndex = 0,
  });
}

class Opponent {
  final String name;
  final String avatarUrl;
  final int level;
  final int winRate;

  const Opponent({
    required this.name,
    required this.avatarUrl,
    required this.level,
    required this.winRate,
  });
}

class QuizOptionModel {
  final String id;
  final String text;

  const QuizOptionModel({required this.id, required this.text});
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOptionModel> options;
  final int? correctIndex;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.correctIndex,
  });
}

class QuizQuestionResult {
  final String questionId;
  final String selectedOptionId;
  final String correctOptionId;
  final bool correct;

  const QuizQuestionResult({
    required this.questionId,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.correct,
  });
}

class QuizResult {
  final String attemptId;
  final int correct;
  final int wrong;
  final int total;
  final int timeTakenSeconds;
  final int xpEarned;
  final int coinsEarned;
  final int accuracyPercent;
  final List<QuizQuestionResult> results;

  const QuizResult({
    this.attemptId = '',
    required this.correct,
    required this.wrong,
    required this.total,
    required this.timeTakenSeconds,
    required this.xpEarned,
    required this.coinsEarned,
    required this.accuracyPercent,
    this.results = const [],
  });

  QuizResult copyWith({
    String? attemptId,
    int? correct,
    int? wrong,
    int? total,
    int? timeTakenSeconds,
    int? xpEarned,
    int? coinsEarned,
    int? accuracyPercent,
    List<QuizQuestionResult>? results,
  }) {
    return QuizResult(
      attemptId: attemptId ?? this.attemptId,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      total: total ?? this.total,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      xpEarned: xpEarned ?? this.xpEarned,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      results: results ?? this.results,
    );
  }
}

class QuizAttemptSummary {
  final String attemptId;
  final String quizId;
  final String quizTitle;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final String? completedAt;

  const QuizAttemptSummary({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    this.completedAt,
  });

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) {
    return QuizAttemptSummary(
      attemptId: (json['attemptId'] ?? '').toString(),
      quizId: (json['quizId'] ?? '').toString(),
      quizTitle: (json['quizTitle'] ?? json['title'] ?? '').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt']?.toString(),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String avatarUrl;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.xp,
    this.isCurrentUser = false,
  });
}

class UserStats {
  final String name;
  final String avatarUrl;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int streak;
  final int coins;
  final int badges;
  final int totalQuizzes;

  const UserStats({
    required this.name,
    required this.avatarUrl,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.streak,
    required this.coins,
    this.badges = 0,
    this.totalQuizzes = 0,
  });
}
