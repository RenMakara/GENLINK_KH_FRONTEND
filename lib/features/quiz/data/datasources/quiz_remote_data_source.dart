import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/quiz_models.dart';

abstract class QuizRemoteDataSource {
<<<<<<< Updated upstream
  Future<List<Map<String, dynamic>>> getQuizzes({
    String? category,
    String? difficulty,
  });
=======
  Future<List<QuizSummary>> getQuizzes({String? category, String? difficulty});
>>>>>>> Stashed changes
  Future<List<QuizQuestion>> getQuizDetails(String quizId);
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );
<<<<<<< Updated upstream
  Future<List<Map<String, dynamic>>> getQuizHistory();
=======
  Future<List<QuizAttemptSummary>> getQuizHistory();
>>>>>>> Stashed changes
  Future<List<LeaderboardEntry>> getLeaderboard(String category, String period);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final ApiClient _apiClient;

  const QuizRemoteDataSourceImpl(this._apiClient);

  @override
<<<<<<< Updated upstream
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
=======
  Future<List<QuizSummary>> getQuizzes({
    String? category,
    String? difficulty,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }

    _debugQuizLog(
      'Quiz API request: GET ${_apiClient.raw.options.baseUrl}${ApiEndpoints.quizzes}'
      '${query.isEmpty ? '' : ' query=$query'}',
    );

    try {
      return await _apiClient.get(
        ApiEndpoints.quizzes,
        query: query.isEmpty ? null : query,
        parse: (data) {
          _debugQuizLog('[Quiz API] Response type: ${_describeData(data)}');
          try {
            final quizzes = _asObjectList(data)
                .map(QuizSummary.fromJson)
                .where((quiz) => quiz.quizId.isNotEmpty)
                .toList();
            _debugQuizLog('[Quiz API] Quiz count: ${quizzes.length}');
            return quizzes;
          } catch (e, stackTrace) {
            _debugQuizLog('[Quiz PARSING ERROR] $e\n$stackTrace');
            rethrow;
          }
        },
>>>>>>> Stashed changes
      );
    } on AppError catch (e) {
      _debugQuizLog(
        '[Quiz API ERROR] Status: ${e.statusCode ?? 'unknown'}; '
        'Code: ${e.errorCode}; Message: ${e.message}',
      );
      rethrow;
    } catch (e) {
      _debugQuizLog('[Quiz API ERROR] $e');
      rethrow;
    }
<<<<<<< Updated upstream

    // Fallback Mock Data
    return [
      {
        'quizId': 'mock-quiz-1',
        'title': 'Mock Quiz ($category)',
        'category': category ?? 'General',
      },
    ];
=======
>>>>>>> Stashed changes
  }

  @override
  Future<List<QuizQuestion>> getQuizDetails(String quizId) async {
<<<<<<< Updated upstream
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
=======
    return _apiClient.get(
      ApiEndpoints.quizDetail(quizId),
      parse: (data) {
        final quiz = ApiClient.asMap(data);
        final questionsData = _asObjectList(quiz['questions']);
        return questionsData
            .map((questionJson) {
              final optionsList = _asObjectList(questionJson['options']);
              return QuizQuestion(
                id: (questionJson['questionId'] ?? '').toString(),
                question: (questionJson['questionText'] ?? '').toString(),
                options: optionsList
                    .map(
                      (optionJson) => QuizOptionModel(
                        id: (optionJson['optionId'] ?? '').toString(),
                        text: (optionJson['optionText'] ?? '').toString(),
                      ),
                    )
                    .toList(growable: false),
              );
            })
            .toList(growable: false);
      },
    );
>>>>>>> Stashed changes
  }

  @override
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  ) async {
<<<<<<< Updated upstream
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

=======
>>>>>>> Stashed changes
    return _apiClient.post(
      ApiEndpoints.quizAttempt(quizId),
      body: {'answers': answers},
      parse: (data) {
<<<<<<< Updated upstream
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
=======
        final response = ApiClient.asMap(data);
        final results = _asObjectList(response['results'])
            .map(
              (resultJson) => QuizQuestionResult(
                questionId: (resultJson['questionId'] ?? '').toString(),
                selectedOptionId: (resultJson['selectedOptionId'] ?? '')
                    .toString(),
                correctOptionId: (resultJson['correctOptionId'] ?? '')
                    .toString(),
                correct: resultJson['correct'] == true,
              ),
            )
            .toList(growable: false);
        final correct =
            (response['correctCount'] as num?)?.toInt() ??
            results.where((result) => result.correct).length;
        final total =
            (response['totalQuestions'] as num?)?.toInt() ??
            (results.isNotEmpty ? results.length : answers.length);
        final score =
            (response['score'] as num?)?.toInt() ??
            (total == 0 ? 0 : (correct * 100 / total).round());
        return QuizResult(
          attemptId: (response['attemptId'] ?? '').toString(),
          correct: correct,
          wrong: total - correct,
          total: total,
          timeTakenSeconds: 0,
          xpEarned: (response['xpEarned'] as num?)?.toInt() ?? 0,
          coinsEarned: (response['coinsEarned'] as num?)?.toInt() ?? 0,
          accuracyPercent: score,
>>>>>>> Stashed changes
          results: results,
        );
      },
    );
  }

  @override
  Future<List<QuizAttemptSummary>> getQuizHistory() async {
    return _apiClient.get(
      ApiEndpoints.quizHistory,
      parse: (data) =>
<<<<<<< Updated upstream
          (data as List).map((e) => e as Map<String, dynamic>).toList(),
=======
          _asObjectList(data).map(QuizAttemptSummary.fromJson).toList(),
>>>>>>> Stashed changes
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

  static List<Map<String, dynamic>> _asObjectList(dynamic data) {
    final List<dynamic> rawList;
    if (data is List<dynamic>) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final value =
          data['content'] ??
          data['items'] ??
          data['quizzes'] ??
          data['attempts'];
      rawList = value is List<dynamic> ? value : const <dynamic>[];
    } else if (data is Map) {
      final value =
          data['content'] ??
          data['items'] ??
          data['quizzes'] ??
          data['attempts'];
      rawList = value is List<dynamic> ? value : const <dynamic>[];
    } else {
      rawList = const <dynamic>[];
    }

    return rawList
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  static String _describeData(dynamic data) {
    if (data is List) return 'List(length=${data.length})';
    if (data is Map) {
      final keys = data.keys.map((key) => key.toString()).join(',');
      final nestedCounts = <String>[];
      for (final key in const ['content', 'items', 'quizzes', 'attempts']) {
        final value = data[key];
        if (value is List) nestedCounts.add('$key.length=${value.length}');
      }
      return 'Map(keys=[$keys]${nestedCounts.isEmpty ? '' : ', ${nestedCounts.join(', ')})'}';
    }
    return data == null ? 'null' : data.runtimeType.toString();
  }

  static void _debugQuizLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
