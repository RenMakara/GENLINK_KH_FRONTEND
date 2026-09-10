import '../models/quiz_models.dart';

abstract class QuizRepository {
  Future<List<QuizSummary>> getQuizzes({String? category, String? difficulty});

  Future<List<QuizQuestion>> getQuizDetails(String quizId);

  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );

  Future<List<QuizAttemptSummary>> getQuizHistory();

  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}
