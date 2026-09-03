import '../../domain/models/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource _remoteDataSource;

  const QuizRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<QuizSummary>> getQuizzes({
    String? category,
    String? difficulty,
  }) =>
      _remoteDataSource.getQuizzes(category: category, difficulty: difficulty);

  @override
  Future<List<QuizQuestion>> getQuizDetails(String quizId) =>
      _remoteDataSource.getQuizDetails(quizId);

  @override
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  ) => _remoteDataSource.submitQuizAttempt(quizId, answers);

  @override
  Future<List<QuizAttemptSummary>> getQuizHistory() =>
      _remoteDataSource.getQuizHistory();

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String category,
    String period,
  ) => _remoteDataSource.getLeaderboard(category, period);
}
