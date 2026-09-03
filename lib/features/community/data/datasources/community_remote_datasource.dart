import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_post_model.dart';

class CommunityRemoteDataSource {
  final Dio dio;

  CommunityRemoteDataSource({required this.dio});

  Future<List<CommunityPostModel>> fetchPosts({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityFeed,
        queryParameters: {'page': page - 1, 'size': limit},
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      dynamic rawData;
      if (body is Map<String, dynamic>) {
        rawData = body['data'];
      } else {
        rawData = body;
      }

      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }

      if (content.isNotEmpty) {
        return content
            .map(
              (json) => CommunityPostModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    }
    return [];
  }

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPosts,
        data: {
          'contentText': content,
          'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
          'visibility': visibility.toUpperCase(),
          'postType': 'NORMAL',
        },
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(data);
      }
    }
    throw AppError(message: 'Failed to parse post response', errorCode: 'PARSE_ERROR');
  }

  Future<bool> deletePost(String postId) async {
    await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityPostDetail(postId)),
    );
    return true;
  }

  Future<bool> toggleLike(String postId, {required bool isCurrentlyLiked}) async {
    if (isCurrentlyLiked) {
      await guardDio(
        () => dio.delete<dynamic>(ApiEndpoints.communityPostUnlike(postId)),
      );
    } else {
      await guardDio(
        () => dio.post<dynamic>(ApiEndpoints.communityPostLike(postId)),
      );
    }
    return true;
  }

  Future<bool> toggleBookmark(String postId) async {
    // 🔴 NOT BUILT: Backend does not have a bookmark endpoint yet
    // Throw error or silently succeed. Silently succeeding for UI optimism:
    return true;
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityPostComments(postId)),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData =
          body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      
      List<dynamic> content = [];
      if (rawData is Map<String, dynamic>) {
        content = (rawData['content'] as List<dynamic>?) ?? [];
      } else if (rawData is List) {
        content = rawData;
      }
      
      return content
          .map(
            (json) => CommentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPostComments(postId),
        data: {
          'text': text,
          'parentCommentId': parentCommentId,
        },
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        return CommentModel.fromJson(data);
      }
    }
    throw AppError(message: 'Failed to parse comment response', errorCode: 'PARSE_ERROR');
  }
}
