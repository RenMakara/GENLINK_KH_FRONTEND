import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/quiz_models.dart';

abstract class QuizRemoteDataSource {
  Future<List<Map<String, dynamic>>> getQuizzes({
    String? category,
    String? difficulty,
  });
  Future<List<QuizQuestion>> getQuizDetails(String quizId);
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );
  Future<List<Map<String, dynamic>>> getQuizHistory();
  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final ApiClient _apiClient;

  const QuizRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Map<String, dynamic>>> getQuizzes({
    String? category,
    String? difficulty,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (category != null) query['category'] = category;
      if (difficulty != null) query['difficulty'] = difficulty;

      final result = await _apiClient.get(
        ApiEndpoints.quizzes,
        query: query.isEmpty ? null : query,
        parse: (data) =>
            (data as List).map((e) => e as Map<String, dynamic>).toList(),
      );

      if (result.isNotEmpty) return result;
    } catch (e) {
      print('API Error getting quizzes: $e, using fallback data.');
    }

    // Fallback Mock Data
    return [
      {
        'quizId': 'mock-quiz-1',
        'title': 'Mock Quiz ($category)',
        'category': category ?? 'General',
      },
    ];
  }

  @override
  Future<List<QuizQuestion>> getQuizDetails(String quizId) async {
    if (quizId == 'mock-quiz-1') {
      return _getMockQuestions();
    }

    try {
      final result = await _apiClient.get(
        ApiEndpoints.quizDetail(quizId),
        parse: (data) {
          final questionsData = data['questions'] as List? ?? [];
          return questionsData.map((e) {
            final optionsList = e['options'] as List? ?? [];
            return QuizQuestion(
              id: e['questionId'] ?? '',
              question: e['questionText'] ?? '',
              // Map the API options to QuizOptionModel so we can retain optionId
              options: optionsList
                  .map(
                    (o) => QuizOptionModel(
                      id: (o['optionId'] ?? '').toString(),
                      text: (o['optionText'] ?? '').toString(),
                    ),
                  )
                  .toList(),
              correctIndex:
                  -1, // Correct index is withheld by the API until submit!
            );
          }).toList();
        },
      );

      if (result.isNotEmpty) return result;
    } catch (e) {
      print('API Error getting quiz details: $e, using fallback data.');
    }

    return _getMockQuestions();
  }

  @override
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  ) async {
    if (quizId == 'mock-quiz-1') {
      await Future.delayed(const Duration(seconds: 1));
      return QuizResult(
        correct: answers.length, // Simulate perfect score for mock
        wrong: 0,
        total: answers.length,
        timeTakenSeconds: 15,
        xpEarned: 50,
        coinsEarned: 20,
        accuracyPercent: 100,
      );
    }

    return _apiClient.post(
      ApiEndpoints.quizAttempt(quizId),
      body: {'answers': answers},
      parse: (data) {
        final resultsData = data['results'] as List? ?? const [];
        final results = resultsData
            .map(
              (e) => QuizQuestionResult(
                questionId: (e['questionId'] ?? '').toString(),
                selectedOptionId: (e['selectedOptionId'] ?? '').toString(),
                correctOptionId: (e['correctOptionId'] ?? '').toString(),
                correct: e['correct'] ?? false,
              ),
            )
            .toList();
        return QuizResult(
          correct: data['correctCount'] ?? 0,
          wrong: (data['totalQuestions'] ?? 0) - (data['correctCount'] ?? 0),
          total: data['totalQuestions'] ?? 0,
          timeTakenSeconds: 0, // Not provided by the API attempt response
          xpEarned: data['xpEarned'] ?? 0,
          coinsEarned:
              0, // Not provided by API, perhaps it's an app-only concept or handled differently
          accuracyPercent: data['score'] ?? 0,
          results: results,
        );
      },
    );
  }

  List<QuizQuestion> _getMockQuestions() {
    return [
      QuizQuestion(
        id: 'q1',
        question: 'What is the largest planet in our solar system?',
        options: [
          const QuizOptionModel(id: 'o1', text: 'Earth'),
          const QuizOptionModel(id: 'o2', text: 'Jupiter'),
          const QuizOptionModel(id: 'o3', text: 'Mars'),
          const QuizOptionModel(id: 'o4', text: 'Saturn'),
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'q2',
        question: 'What is the speed of light in vacuum?',
        options: [
          const QuizOptionModel(id: 'o1', text: '300,000 km/s'),
          const QuizOptionModel(id: 'o2', text: '150,000 km/s'),
          const QuizOptionModel(id: 'o3', text: '500,000 km/s'),
          const QuizOptionModel(id: 'o4', text: '200,000 km/s'),
        ],
        correctIndex: 0,
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    return _apiClient.get(
      ApiEndpoints.quizHistory,
      parse: (data) =>
          (data as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String category,
    String period,
  ) async {
    return _apiClient.get(
      ApiEndpoints.leaderboards,
      query: {'category': category, 'period': period},
      parse: (data) {
        final entries = data['entries'] as List? ?? [];
        return entries
            .map(
              (e) => LeaderboardEntry(
                rank: e['rank'] ?? 0,
                name: e['name'] ?? '',
                avatarUrl: e['avatarUrl'] ?? '',
                xp: (e['points'] as num?)?.toInt() ?? 0,
                isCurrentUser: false,
              ),
            )
            .toList();
      },
    );
  }
}
