import '../models/quiz_models.dart';

abstract class QuizRepository {
  /// Fetch a list of quizzes, optionally filtered by category and difficulty
  Future<List<Map<String, dynamic>>> getQuizzes({
    String? category,
    String? difficulty,
  });

  /// Fetch a specific quiz's details (questions and options)
  Future<List<QuizQuestion>> getQuizDetails(String quizId);

  /// Submit answers for a quiz
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );

  /// Fetch the user's quiz history
  Future<List<Map<String, dynamic>>> getQuizHistory();

  /// Fetch leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}
