import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/search_models.dart';

Future<T> _safeGuardDio<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) {
      rethrow;
    }
    throw AppError.fromDio(e);
  }
}

class SearchRemoteDataSource {
  final Dio dio;

  SearchRemoteDataSource({required this.dio});

  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.search,
        queryParameters: {
          'q': query,
          'type': category.toApiType(),
          'page': page,
          'size': size,
        },
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final Map<String, dynamic> data = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body)
          : <String, dynamic>{};

      return CombinedSearchResults.fromJson(
        data,
        query: query,
        category: category,
      );
    }

    return CombinedSearchResults(query: query, category: category);
  }

  Future<List<UserSearchResultModel>> searchPeople({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.searchPeople,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
        },
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }

      return content
          .whereType<Map<String, dynamic>>()
          .map(UserSearchResultModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.searchPosts,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
        },
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }

      return content
          .whereType<Map<String, dynamic>>()
          .map(CommunityPostModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.searchEvents,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
        },
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }

      return content
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.searchDiscussions,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
        },
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }

      return content
          .whereType<Map<String, dynamic>>()
          .map(ForumTopicModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<String>> getTrendingHashtags({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeGuardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.trendingHashtags,
        queryParameters: {'limit': limit},
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      if (rawData is List) {
        return rawData.map((e) => e.toString()).toList();
      }
    }
    return [];
  }
}
