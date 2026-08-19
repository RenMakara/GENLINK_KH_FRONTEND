enum QuizType {
  single,
  random,
}

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

  const QuizOptionModel({
    required this.id,
    required this.text,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOptionModel> options;
  final int correctIndex;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
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
  final int correct;
  final int wrong;
  final int total;
  final int timeTakenSeconds;
  final int xpEarned;
  final int coinsEarned;
  final int accuracyPercent;
  final List<QuizQuestionResult> results;

  const QuizResult({
    required this.correct,
    required this.wrong,
    required this.total,
    required this.timeTakenSeconds,
    required this.xpEarned,
    required this.coinsEarned,
    required this.accuracyPercent,
    this.results = const [],
  });
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
