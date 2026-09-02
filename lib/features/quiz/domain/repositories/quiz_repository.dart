import '../models/quiz_models.dart';

abstract class QuizRepository {
  /// Fetch a list of quizzes, optionally filtered by category and difficulty
<<<<<<< Updated upstream
  Future<List<Map<String, dynamic>>> getQuizzes({
    String? category,
    String? difficulty,
  });
=======
  Future<List<QuizSummary>> getQuizzes({String? category, String? difficulty});
>>>>>>> Stashed changes

  /// Fetch a specific quiz's details (questions and options)
  Future<List<QuizQuestion>> getQuizDetails(String quizId);

  /// Submit answers for a quiz
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );

  /// Fetch the user's quiz history
<<<<<<< Updated upstream
  Future<List<Map<String, dynamic>>> getQuizHistory();
=======
  Future<List<QuizAttemptSummary>> getQuizHistory();
>>>>>>> Stashed changes

  /// Fetch leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}
