import '../models/quiz_models.dart';

abstract class QuizRepository {
  /// Fetch a list of quizzes, optionally filtered by category and difficulty
  Future<List<QuizSummary>> getQuizzes({String? category, String? difficulty});

  /// Fetch a specific quiz's details (questions and options)
  Future<List<QuizQuestion>> getQuizDetails(String quizId);

  /// Submit answers for a quiz
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );

  /// Fetch the user's quiz history
  Future<List<QuizAttemptSummary>> getQuizHistory();

  /// Fetch leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}
