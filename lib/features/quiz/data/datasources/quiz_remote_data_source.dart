import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/quiz_models.dart';

abstract class QuizRemoteDataSource {
  Future<List<QuizSummary>> getQuizzes({String? category, String? difficulty});
  Future<List<QuizQuestion>> getQuizDetails(String quizId);
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  );
  Future<List<QuizAttemptSummary>> getQuizHistory();
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final ApiClient _apiClient;

  const QuizRemoteDataSourceImpl(this._apiClient);

  @override
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
  }

  @override
  Future<List<QuizQuestion>> getQuizDetails(String quizId) async {
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
  }

  @override
  Future<QuizResult> submitQuizAttempt(
    String quizId,
    List<Map<String, String>> answers,
  ) async {
    return _apiClient.post(
      ApiEndpoints.quizAttempt(quizId),
      body: {'answers': answers},
      parse: (data) {
        final response = ApiClient.asMap(data);
        final results = _asObjectList(
          response['results'],
        ).map(QuizQuestionResult.fromJson).toList(growable: false);
        final correct = (response['correctCount'] as num?)?.toInt() ?? 0;
        final total = (response['totalQuestions'] as num?)?.toInt() ?? 0;
        return QuizResult(
          attemptId: (response['attemptId'] ?? '').toString(),
          correct: correct,
          wrong: total - correct,
          total: total,
          timeTakenSeconds: 0,
          xpEarned: (response['xpEarned'] as num?)?.toInt() ?? 0,
          accuracyPercent: (response['score'] as num?)?.toInt() ?? 0,
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
          _asObjectList(data).map(QuizAttemptSummary.fromJson).toList(),
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
