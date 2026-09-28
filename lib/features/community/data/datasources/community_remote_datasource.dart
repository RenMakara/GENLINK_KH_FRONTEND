import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_models.dart';
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
    if (response.statusCode != 200 || response.data == null) {
      throw const AppError(
        message: 'The community feed response could not be loaded.',
        errorCode: 'FEED_RESPONSE_INVALID',
      );
    }
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    final content = _requirePageContent(
      rawData,
      code: 'FEED_RESPONSE_INVALID',
      message: 'The community feed response is invalid.',
    );
    return content
        .map(
          (json) => CommunityPostModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<CommunityPostModel>> fetchRepostedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityReposts,
        queryParameters: {'page': page - 1, 'size': limit},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const AppError(
        message: 'The repost response could not be loaded.',
        errorCode: 'POST_REPOSTS_RESPONSE_INVALID',
      );
    }
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    final content = _requirePageContent(
      rawData,
      code: 'POST_REPOSTS_RESPONSE_INVALID',
      message: 'The repost response is invalid.',
    );
    return content
        .map(
          (json) => CommunityPostModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? eventId,
  }) async {
    final resolvedVisibility = _normalizePostVisibility(visibility);

    final postType = videoUrl != null && videoUrl.isNotEmpty
        ? 'VIDEO'
        : (imageUrls.isNotEmpty ? 'IMAGE' : 'TEXT');
    final imageMediaIds = imageUrls
        .map(_mediaIdFromReference)
        .whereType<String>()
        .toList();
    final legacyImageUrls = imageUrls
        .where((url) => _mediaIdFromReference(url) == null)
        .toList();
    final videoMediaId = videoUrl == null
        ? null
        : _mediaIdFromReference(videoUrl);
    final requestData = <String, dynamic>{
      'contentText': content,
      'imageUrl': legacyImageUrls.isNotEmpty ? legacyImageUrls.join(',') : null,
      'videoUrl':
          videoUrl != null && videoUrl.isNotEmpty && videoMediaId == null
          ? videoUrl
          : null,
      'visibility': resolvedVisibility,
      'postType': postType,
    };
    if (location != null) requestData['location'] = location;
    if (linkUrl != null) requestData['linkUrl'] = linkUrl;
    if (linkPreviewTitle != null) {
      requestData['linkPreviewTitle'] = linkPreviewTitle;
    }
    if (linkPreviewDomain != null) {
      requestData['linkPreviewDomain'] = linkPreviewDomain;
    }
    if (eventId != null) requestData['attachedEventId'] = eventId;
    if (imageMediaIds.isNotEmpty) requestData['imageMediaIds'] = imageMediaIds;
    if (videoMediaId != null) requestData['videoMediaId'] = videoMediaId;

    final response = await guardDio(
      () => dio.post<dynamic>(ApiEndpoints.communityPosts, data: requestData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(data);
      }
      if (body is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(body);
      }
    }

    throw const AppError(
      message: 'Failed to create post on server.',
      errorCode: 'POST_CREATION_FAILED',
    );
  }

  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
    int? durationDays,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? eventId,
  }) async {
    final resolvedVisibility = _normalizePostVisibility(visibility);
    final imageMediaIds = imageUrls
        .map(_mediaIdFromReference)
        .whereType<String>()
        .toList();
    final legacyImageUrls = imageUrls
        .where((url) => _mediaIdFromReference(url) == null)
        .toList();
    final videoMediaId = videoUrl == null
        ? null
        : _mediaIdFromReference(videoUrl);
    final payload = <String, dynamic>{
      'question': question.trim(),
      'options': options
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList(),
      'visibility': resolvedVisibility,
    };
    if (caption != null && caption.trim().isNotEmpty) {
      payload['caption'] = caption.trim();
    }
    if (durationDays != null) payload['durationDays'] = durationDays;
    if (legacyImageUrls.isNotEmpty) {
      payload['imageUrl'] = legacyImageUrls.join(',');
    }
    if (videoUrl != null && videoMediaId == null) {
      payload['videoUrl'] = videoUrl;
    }
    if (imageMediaIds.isNotEmpty) payload['imageMediaIds'] = imageMediaIds;
    if (videoMediaId != null) payload['videoMediaId'] = videoMediaId;
    if (location != null) payload['location'] = location;
    if (linkUrl != null) payload['linkUrl'] = linkUrl;
    if (linkPreviewTitle != null) {
      payload['linkPreviewTitle'] = linkPreviewTitle;
    }
    if (linkPreviewDomain != null) {
      payload['linkPreviewDomain'] = linkPreviewDomain;
    }
    if (eventId != null) payload['attachedEventId'] = eventId;
    if (communityId != null && communityId.isNotEmpty) {
      payload['communityId'] = communityId;
    }

    final response = await guardDio(
      () => dio.post<dynamic>(ApiEndpoints.communityPoll, data: payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(data);
      }
      if (body is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(body);
      }
    }

    throw const AppError(
      message: 'Failed to create poll on server.',
      errorCode: 'POLL_CREATION_FAILED',
    );
  }

  String? _mediaIdFromReference(String value) {
    const prefix = 'genlink-media://';
    if (!value.startsWith(prefix)) return null;
    final id = value.substring(prefix.length).trim();
    return id.isEmpty ? null : id;
  }

  String _normalizePostVisibility(String visibility) {
    final normalized = visibility
        .trim()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .toUpperCase();
    return switch (normalized) {
      'PUBLIC' => 'PUBLIC',
      'FRIENDS' => 'FRIENDS',
      'COMMUNITY' => 'COMMUNITY',
      'ONLY_ME' => 'ONLY_ME',
      _ => throw const AppError(
        message: 'Choose a valid post audience before continuing.',
        errorCode: 'INVALID_POST_VISIBILITY',
      ),
    };
  }

  Future<CommunityPostModel> votePoll({
    required String postId,
    required String optionId,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPollVote(postId),
        data: {'optionId': optionId},
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('pollId') || data.containsKey('options')) {
          return CommunityPostModel.fromJson({'postId': postId, 'poll': data});
        }
        return CommunityPostModel.fromJson(data);
      }
      if (body is Map<String, dynamic>) {
        return CommunityPostModel.fromJson({'postId': postId, 'poll': body});
      }
    }

    throw const AppError(
      message: 'Failed to record vote on server.',
      errorCode: 'POLL_VOTE_FAILED',
    );
  }

  Future<CommunityPostModel> fetchPostDetail(String postId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityPostDetail(postId)),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(rawData);
      }
    }
    throw const AppError(
      message: 'Failed to load post details.',
      errorCode: 'POST_DETAIL_INVALID_RESPONSE',
    );
  }

  Future<bool> deletePost(String postId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityPostDetail(postId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to delete post',
      errorCode: 'POST_DELETE_FAILED',
    );
  }

  Future<CommunityPostModel> updatePost(
    String postId, {
    required String content,
    List<String>? imageUrls,
    String? videoUrl,
    String? visibility,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<String>? pollOptions,
    int? pollDurationDays,
    String? eventId,
    bool replaceRichFields = false,
  }) async {
    final request = <String, dynamic>{'contentText': content};
    if (imageUrls != null) {
      final mediaIds = imageUrls
          .map(_mediaIdFromReference)
          .whereType<String>()
          .toList();
      final legacyUrls = imageUrls
          .where((url) => _mediaIdFromReference(url) == null)
          .toList();
      request['imageUrl'] = legacyUrls.isEmpty ? '' : legacyUrls.join(',');
      request['imageMediaIds'] = mediaIds;
    }
    if (videoUrl != null) {
      final mediaId = _mediaIdFromReference(videoUrl);
      request['videoUrl'] = mediaId == null ? videoUrl : null;
      request['videoMediaId'] = mediaId;
    } else if (replaceRichFields) {
      // Rich edits replace the complete media set. Explicitly clear the legacy
      // URL too, otherwise a removed video can reappear after the refresh.
      request['videoUrl'] = '';
      request['videoMediaId'] = null;
    }
    if (visibility != null) {
      request['visibility'] = _normalizePostVisibility(visibility);
    }
    if (replaceRichFields) {
      request.addAll({
        'replaceRichFields': true,
        'location': location,
        'linkUrl': linkUrl,
        'linkPreviewTitle': linkPreviewTitle,
        'linkPreviewDomain': linkPreviewDomain,
        'attachedEventId': eventId,
        'pollQuestion': pollQuestion,
        'pollOptions': pollOptions,
        'pollDurationDays': pollDurationDays,
      });
    }
    final response = await guardDio(
      () => dio.put<dynamic>(
        ApiEndpoints.communityPostDetail(postId),
        data: request,
      ),
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data != null) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        return CommunityPostModel.fromJson(data);
      }
    }
    throw const AppError(
      message: 'Failed to update post',
      errorCode: 'POST_UPDATE_FAILED',
    );
  }

  Future<bool> toggleLike(
    String postId, {
    bool isCurrentlyLiked = false,
  }) async {
    final response = await guardDio(
      () => isCurrentlyLiked
          ? dio.delete<dynamic>(ApiEndpoints.communityPostLike(postId))
          : dio.post<dynamic>(ApiEndpoints.communityPostLike(postId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw AppError(
      message: 'Failed to update post like',
      errorCode: 'POST_LIKE_FAILED',
    );
  }

  Future<List<PostLikerModel>> fetchPostLikers(
    String postId, {
    int page = 0,
    int size = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return [];
    }
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityPostLikes(postId),
        queryParameters: {'page': page, 'size': size},
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
          .map(PostLikerModel.fromJson)
          .toList();
    }
    throw AppError(
      message: 'Failed to fetch post likes',
      errorCode: 'FETCH_POST_LIKES_FAILED',
    );
  }

  Future<bool> toggleBookmark(
    String postId, {
    bool? isCurrentlyBookmarked,
  }) async {
    final response = await guardDio(
      () => isCurrentlyBookmarked == true
          ? dio.delete<dynamic>(ApiEndpoints.profileSavedItem('POST', postId))
          : dio.post<dynamic>(
              ApiEndpoints.profileSaved,
              data: {'itemType': 'POST', 'itemId': postId},
            ),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return true;
    }

    throw const AppError(
      message: 'Failed to update bookmark',
      errorCode: 'BOOKMARK_UPDATE_FAILED',
    );
  }

  Future<bool> isPostBookmarked(String postId) async {
    final cleanId = postId.trim();
    if (cleanId.isEmpty) return false;
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.profileSavedCheck,
        queryParameters: {'itemType': 'POST', 'itemId': cleanId},
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic> && data['saved'] is bool) {
        return data['saved'] as bool;
      }
    }
    throw const AppError(
      message: 'Post bookmark status could not be loaded.',
      errorCode: 'POST_BOOKMARK_STATUS_FETCH_FAILED',
    );
  }

  Future<bool> repostPost(
    String postId, {
    String? caption,
    String? reposterId,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPostRepost(postId),
        data: (caption != null && caption.trim().isNotEmpty)
            ? {'caption': caption.trim()}
            : <String, dynamic>{},
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw const AppError(
      message: 'Failed to repost post',
      errorCode: 'POST_REPOST_FAILED',
    );
  }

  Future<bool> unrepostPost(String postId, {String? reposterId}) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityPostRepost(postId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw const AppError(
      message: 'Failed to undo repost',
      errorCode: 'POST_UNREPOST_FAILED',
    );
  }

  Future<bool> repostDiscussion(
    String discussionId, {
    String? caption,
    String? reposterId,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityDiscussionRepost(discussionId),
        data: (caption != null && caption.trim().isNotEmpty)
            ? {'caption': caption.trim()}
            : <String, dynamic>{},
      ),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> unrepostDiscussion(
    String discussionId, {
    String? reposterId,
  }) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(
        ApiEndpoints.communityDiscussionRepost(discussionId),
      ),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPostReport(postId),
        data: {'reason': reason},
      ),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to report post',
      errorCode: 'POST_REPORT_FAILED',
    );
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityPostComments(postId)),
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

      final parsed = content.whereType<Map<String, dynamic>>().map((json) {
        final map = Map<String, dynamic>.from(json);
        if (map['postId'] == null && map['discussionId'] == null) {
          map['postId'] = postId;
        }
        return CommentModel.fromJson(map);
      }).toList();

      final reconstructed = _reconstructCommentHierarchy(parsed);

      final commentsWithReplies = await Future.wait(
        reconstructed.map((comment) async {
          if (comment.replies.isNotEmpty) return comment;
          final replies = await fetchCommentReplies(comment.id);
          return replies.isEmpty ? comment : comment.copyWith(replies: replies);
        }),
      );

      return commentsWithReplies;
    }
    throw const AppError(
      message: 'The comments response could not be loaded.',
      errorCode: 'COMMENTS_RESPONSE_INVALID',
    );
  }

  Future<List<CommentModel>> fetchCommentReplies(String commentId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityCommentReplies(commentId)),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      final content = rawData is Map<String, dynamic>
          ? rawData['content']
          : rawData;
      if (content is List) {
        return content.whereType<Map<String, dynamic>>().map((json) {
          final map = Map<String, dynamic>.from(json);
          if (map['parentCommentId'] == null) {
            map['parentCommentId'] = commentId;
          }
          return CommentModel.fromJson(map);
        }).toList();
      }
    }
    throw const AppError(
      message: 'The comment replies response could not be loaded.',
      errorCode: 'COMMENT_REPLIES_RESPONSE_INVALID',
    );
  }

  List<CommentModel> _reconstructCommentHierarchy(List<CommentModel> comments) {
    if (comments.isEmpty) return const [];

    final Map<String, List<CommentModel>> repliesByParent = {};
    final List<CommentModel> topLevelComments = [];

    for (final comment in comments) {
      final parentId = comment.parentCommentId;
      if (parentId != null && parentId.isNotEmpty) {
        repliesByParent.putIfAbsent(parentId, () => []).add(comment);
      } else {
        topLevelComments.add(comment);
      }
    }

    if (repliesByParent.isEmpty) {
      return comments;
    }

    List<CommentModel> buildReplies(String parentId) {
      final direct = repliesByParent[parentId] ?? [];
      return direct.map((reply) {
        final nested = buildReplies(reply.id);
        final merged = [
          ...reply.replies,
          ...nested.where((n) => !reply.replies.any((r) => r.id == n.id)),
        ];
        return reply.copyWith(replies: merged);
      }).toList();
    }

    final result = topLevelComments.map((parent) {
      final replies = buildReplies(parent.id);
      final merged = [
        ...parent.replies,
        ...replies.where(
          (r) => !parent.replies.any((existing) => existing.id == r.id),
        ),
      ];
      return parent.copyWith(replies: merged);
    }).toList();

    // Include any orphaned replies whose parent was not in the top-level list
    final accountedIds = <String>{
      ...result.map((c) => c.id),
      ...result.expand((c) => _allCommentDescendantIds(c)),
    };
    for (final comment in comments) {
      if (!accountedIds.contains(comment.id)) {
        result.add(comment);
      }
    }

    return result;
  }

  Set<String> _allCommentDescendantIds(CommentModel comment) {
    final ids = <String>{};
    for (final r in comment.replies) {
      ids.add(r.id);
      ids.addAll(_allCommentDescendantIds(r));
    }
    return ids;
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
          'content': text,
          if (parentCommentId != null && parentCommentId.isNotEmpty)
            'parentCommentId': parentCommentId,
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      Map<String, dynamic>? dataMap;
      if (body is Map<String, dynamic> &&
          body['data'] is Map<String, dynamic>) {
        dataMap = body['data'] as Map<String, dynamic>;
      } else if (body is Map<String, dynamic>) {
        dataMap = body;
      }

      if (dataMap != null) {
        if (dataMap['postId'] == null && dataMap['discussionId'] == null) {
          dataMap['postId'] = postId;
        }
        return CommentModel.fromJson(dataMap);
      }
    }

    throw AppError(
      message: 'Failed to add comment',
      errorCode: 'COMMENT_CREATE_FAILED',
    );
  }

  Future<bool> deleteComment(String commentId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityComment(commentId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to delete comment',
      errorCode: 'COMMENT_DELETE_FAILED',
    );
  }

  Future<List<CommentModel>> fetchDiscussionComments(
    String discussionId,
  ) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionComments(discussionId),
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

      final topLevelComments = content
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentModel.fromJson(json))
          .toList();

      final commentsWithReplies = await Future.wait(
        topLevelComments.map((comment) async {
          if (comment.replies.isNotEmpty) return comment;
          final replies = await fetchDiscussionCommentReplies(comment.id);
          return replies.isEmpty ? comment : comment.copyWith(replies: replies);
        }),
      );
      return commentsWithReplies;
    }
    throw const AppError(
      message: 'The discussion comments response could not be loaded.',
      errorCode: 'DISCUSSION_COMMENTS_RESPONSE_INVALID',
    );
  }

  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityDiscussionComments(discussionId),
        data: {
          'content': content,
          if (parentCommentId != null && parentCommentId.isNotEmpty)
            'parentCommentId': parentCommentId,
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      if (body is Map<String, dynamic> &&
          body['data'] is Map<String, dynamic>) {
        return CommentModel.fromJson(body['data'] as Map<String, dynamic>);
      } else if (body is Map<String, dynamic>) {
        return CommentModel.fromJson(body);
      }
    }

    throw AppError(
      message: 'Failed to add comment',
      errorCode: 'COMMENT_CREATE_FAILED',
    );
  }

  Future<List<CommentModel>> fetchDiscussionCommentReplies(
    String commentId,
  ) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionCommentReplies(commentId),
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      final content = rawData is Map<String, dynamic>
          ? rawData['content']
          : rawData;
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(CommentModel.fromJson)
            .toList();
      }
    }
    throw const AppError(
      message: 'The discussion replies response could not be loaded.',
      errorCode: 'DISCUSSION_REPLIES_RESPONSE_INVALID',
    );
  }

  Future<CommentModel> updateDiscussionComment(
    String commentId,
    String content,
  ) async {
    final response = await guardDio(
      () => dio.put<dynamic>(
        ApiEndpoints.communityDiscussionCommentDetail(commentId),
        data: {'content': content},
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        return CommentModel.fromJson(data);
      }
    }

    throw const AppError(
      message: 'Failed to update comment',
      errorCode: 'COMMENT_UPDATE_FAILED',
    );
  }

  Future<List<ForumTopicModel>> fetchDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async => (await fetchDiscussionsPage(
    category: category,
    page: page,
    limit: limit,
  )).content;

  Future<EventPageModel<ForumTopicModel>> fetchDiscussionsPage({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': page - 1, 'size': limit};
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussions,
        queryParameters: query,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      _requirePageContent(
        rawData,
        code: 'DISCUSSIONS_RESPONSE_INVALID',
        message: 'The discussion response is invalid.',
      );
      return EventPageModel<ForumTopicModel>.fromJson(
        rawData,
        ForumTopicModel.fromJson,
      );
    }
    throw const AppError(
      message: 'The discussions response could not be loaded.',
      errorCode: 'DISCUSSIONS_RESPONSE_INVALID',
    );
  }

  Future<List<ForumTopicModel>> fetchDiscussionReposts({
    String? userId,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': page - 1, 'size': limit};
    if (userId != null && userId.trim().isNotEmpty) {
      query['userId'] = userId.trim();
    }
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionReposts,
        queryParameters: query,
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const AppError(
        message: 'The discussion repost response could not be loaded.',
        errorCode: 'DISCUSSION_REPOSTS_RESPONSE_INVALID',
      );
    }
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    final content = _requirePageContent(
      rawData,
      code: 'DISCUSSION_REPOSTS_RESPONSE_INVALID',
      message: 'The discussion repost response is invalid.',
    );
    return content
        .whereType<Map<String, dynamic>>()
        .map(ForumTopicModel.fromJson)
        .toList();
  }

  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityDiscussions,
        data: {
          'title': title,
          'content': content,
          'category': category,
          'anonymous': anonymous,
        },
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        final topic = ForumTopicModel.fromJson(data);
        if (anonymous) {
          return topic.copyWith(
            isAnonymous: true,
            authorName: 'Anonymous',
            authorAvatar: '',
          );
        }
        return topic;
      }
    }
    throw AppError(
      message: 'Failed to create discussion',
      errorCode: 'DISCUSSION_CREATE_FAILED',
    );
  }

  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
    bool? anonymous,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      'category': category,
      'anonymous': ?anonymous,
    };
    final response = await guardDio(
      () => dio.put<dynamic>(
        ApiEndpoints.communityDiscussionDetail(discussionId),
        data: payload,
      ),
    );
    if (response.statusCode == 200) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        final topic = ForumTopicModel.fromJson(data);
        if (anonymous == true || (anonymous == null && topic.isAnonymous)) {
          return topic.copyWith(
            isAnonymous: true,
            authorName: 'Anonymous',
            authorAvatar: '',
          );
        }
        return topic;
      }
    }
    throw AppError(
      message: 'Failed to update discussion',
      errorCode: 'DISCUSSION_UPDATE_FAILED',
    );
  }

  Future<bool> deleteDiscussion(String discussionId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(
        ApiEndpoints.communityDiscussionDetail(discussionId),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw AppError(
      message: 'Failed to delete discussion',
      errorCode: 'DISCUSSION_DELETE_FAILED',
    );
  }

  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async {
    final response = await guardDio(
      () => isCurrentlyLiked
          ? dio.delete<dynamic>(
              ApiEndpoints.communityDiscussionReact(discussionId),
            )
          : dio.post<dynamic>(
              ApiEndpoints.communityDiscussionReact(discussionId),
            ),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw AppError(
      message: 'Failed to update reaction',
      errorCode: 'DISCUSSION_REACT_FAILED',
    );
  }

  Future<List<ForumLikerModel>> fetchDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) async {
    final cleanId = discussionId.trim();
    if (cleanId.isEmpty) {
      return [];
    }
    Response<dynamic> response;
    try {
      response = await guardDio(
        () => dio.get<dynamic>(
          ApiEndpoints.communityDiscussionReactions(cleanId),
          queryParameters: {'page': page, 'size': size},
        ),
      );
    } on AppError catch (e) {
      if (e.statusCode == 404) {
        try {
          response = await guardDio(
            () => dio.get<dynamic>(
              '/api/v1/community/discussions/$cleanId/likes',
              queryParameters: {'page': page, 'size': size},
            ),
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
    if (response.statusCode == 200 && response.data != null) {
      dynamic body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {}
      }

      dynamic rawData = body;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        if (map['success'] == false) {
          throw AppError(
            message:
                map['message']?.toString() ??
                'Failed to fetch discussion reactions',
            errorCode:
                map['errorCode']?.toString() ??
                'FETCH_DISCUSSION_REACTIONS_FAILED',
          );
        }
        rawData = map['data'] ?? map;
      }

      List<dynamic> content = [];
      if (rawData is Map) {
        final dataMap = Map<String, dynamic>.from(rawData);
        final list =
            dataMap['content'] ??
            dataMap['items'] ??
            dataMap['likers'] ??
            dataMap['reactions'];
        if (list is List) {
          content = list;
        }
      } else if (rawData is List) {
        content = rawData;
      }

      final List<ForumLikerModel> likers = [];
      for (final item in content) {
        if (item is Map) {
          likers.add(ForumLikerModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return likers;
    }
    throw AppError(
      message: 'Failed to fetch discussion reactions',
      errorCode: 'FETCH_DISCUSSION_REACTIONS_FAILED',
    );
  }

  Future<bool> toggleDiscussionBookmark(
    String discussionId, {
    required bool isCurrentlyBookmarked,
  }) async {
    final response = await guardDio(
      () => isCurrentlyBookmarked
          ? dio.delete<dynamic>(
              ApiEndpoints.profileSavedItem('DISCUSSION', discussionId),
            )
          : dio.post<dynamic>(
              ApiEndpoints.profileSaved,
              data: {'itemType': 'DISCUSSION', 'itemId': discussionId},
            ),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to update bookmark',
      errorCode: 'BOOKMARK_UPDATE_FAILED',
    );
  }

  Future<bool> isDiscussionBookmarked(String discussionId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.profileSavedCheck,
        queryParameters: {'itemType': 'DISCUSSION', 'itemId': discussionId},
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic> && data['saved'] is bool) {
        return data['saved'] as bool;
      }
    }
    throw const AppError(
      message: 'Discussion bookmark status could not be loaded.',
      errorCode: 'DISCUSSION_BOOKMARK_STATUS_FETCH_FAILED',
    );
  }

  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionDetail(discussionId),
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        return ForumTopicModel.fromJson(data);
      }
    }
    throw AppError(
      message: 'Failed to load discussion details',
      errorCode: 'DISCUSSION_NOT_FOUND',
    );
  }

  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityDiscussionReport(discussionId),
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw AppError(
      message: 'Failed to report discussion',
      errorCode: 'DISCUSSION_REPORT_FAILED',
    );
  }

  Future<bool> toggleDiscussionCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  }) async {
    final response = await guardDio(
      () => isCurrentlyLiked
          ? dio.delete<dynamic>(
              ApiEndpoints.communityDiscussionCommentLike(commentId),
            )
          : dio.post<dynamic>(
              ApiEndpoints.communityDiscussionCommentLike(commentId),
            ),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw AppError(
      message: 'Failed to update comment reaction',
      errorCode: 'COMMENT_LIKE_FAILED',
    );
  }

  Future<bool> deleteDiscussionComment(String commentId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(
        ApiEndpoints.communityDiscussionCommentDetail(commentId),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw AppError(
      message: 'Failed to delete comment',
      errorCode: 'COMMENT_DELETE_FAILED',
    );
  }

  Future<bool> followUser(String userId) async {
    final response = await guardDio(
      () => dio.post<dynamic>(ApiEndpoints.communityFollowUser(userId)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw const AppError(
      message: 'Failed to follow user',
      errorCode: 'FOLLOW_FAILED',
    );
  }

  Future<bool> unfollowUser(String userId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityFollowUser(userId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw const AppError(
      message: 'Failed to unfollow user',
      errorCode: 'UNFOLLOW_FAILED',
    );
  }

  Future<bool> checkIsFollowing(String userId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityFollowStats(userId)),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map<String, dynamic>) {
        final followStatus = data['followStatus'];
        return followStatus == 'ACCEPTED' || followStatus == 'PENDING';
      }
    }
    throw const AppError(
      message: 'Failed to check follow status',
      errorCode: 'FOLLOW_STATUS_FAILED',
    );
  }

  Future<List<FollowUserModel>> getFollowers(
    String userId, {
    int page = 0,
    int size = 50,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityFollowers(userId),
        queryParameters: {'page': page, 'size': size},
      ),
    );
    final list = _extractContentList(response.data);
    return list
        .whereType<Map>()
        .map((item) => FollowUserModel.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  Future<List<FollowUserModel>> getFollowing(
    String userId, {
    int page = 0,
    int size = 50,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityFollowing(userId),
        queryParameters: {'page': page, 'size': size},
      ),
    );
    final list = _extractContentList(response.data);
    return list
        .whereType<Map>()
        .map((item) => FollowUserModel.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  Future<List<FollowUserModel>> getPendingFollowRequests({
    int page = 0,
    int size = 50,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityFollowRequests,
        queryParameters: {'page': page, 'size': size},
      ),
    );
    final list = _extractContentList(response.data);
    return list
        .whereType<Map>()
        .map((item) => FollowUserModel.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  Future<bool> acceptFollowRequest(String followerUserId) async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.communityFollowRequestAccept(followerUserId),
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectFollowRequest(String followerUserId) async {
    try {
      final response = await guardDio(
        () => dio.delete<dynamic>(
          ApiEndpoints.communityFollowRequestReject(followerUserId),
        ),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static List<dynamic> _extractContentList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final payload = body['data'] ?? body;
      if (payload is Map) {
        final content =
            payload['content'] ?? payload['items'] ?? payload['list'];
        if (content is List) return content;
      }
      if (payload is List) return payload;
    }
    throw const AppError(
      message: 'The community list response is invalid.',
      errorCode: 'COMMUNITY_LIST_RESPONSE_INVALID',
    );
  }

  static List<dynamic> _requirePageContent(
    dynamic rawData, {
    required String code,
    required String message,
  }) {
    if (rawData is List) return rawData;
    if (rawData is Map<String, dynamic> && rawData['content'] is List) {
      return rawData['content'] as List<dynamic>;
    }
    throw AppError(message: message, errorCode: code);
  }

  Future<RsvpResponseModel> rsvpEvent(
    String eventId, {
    EventRegistrationRequest? request,
  }) async {
    if (request == null) {
      // The backend requires a complete @RequestBody. Do not send a null body
      // and let a transport/server error obscure the client contract.
      throw const AppError(
        message: 'Complete event registration is required.',
        errorCode: 'RSVP_REQUEST_REQUIRED',
      );
    }
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityEventRsvp(eventId),
        data: request.toJson(),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      dynamic rawData;
      if (body is Map<String, dynamic>) {
        rawData = body['data'] ?? body;
      } else {
        rawData = body;
      }
      if (rawData is Map<String, dynamic>) {
        return RsvpResponseModel.fromJson(rawData);
      }
    }

    throw const AppError(
      message: 'Failed to complete event RSVP.',
      errorCode: 'RSVP_FAILED',
    );
  }

  Future<bool> cancelRsvpEvent(String eventId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityEventRsvp(eventId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }

    throw const AppError(
      message: 'Failed to cancel event RSVP.',
      errorCode: 'CANCEL_RSVP_FAILED',
    );
  }

  Future<EventModel> createEvent(EventCreateRequest request) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityEvents,
        data: request.toJson(),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return EventModel.fromJson(rawData);
      }
    }

    throw const AppError(
      message: 'Failed to create event.',
      errorCode: 'EVENT_CREATION_FAILED',
    );
  }

  Future<List<EventModel>> fetchEvents({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final result = await fetchEventsPage(
      page: page,
      limit: limit,
      category: category,
    );
    return result.content;
  }

  Future<EventPageModel<EventModel>> fetchEventsPage({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final query = <String, dynamic>{'page': page - 1, 'size': limit};
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityEvents,
        queryParameters: query,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      return EventPageModel<EventModel>.fromJson(rawData, EventModel.fromJson);
    }
    throw const AppError(
      message: 'Failed to load events.',
      errorCode: 'EVENT_LIST_FAILED',
    );
  }

  Future<List<EventModel>> fetchMyEvents({int page = 1, int limit = 20}) async {
    final result = await fetchMyEventsPage(page: page, limit: limit);
    return result.content;
  }

  Future<EventPageModel<EventModel>> fetchMyEventsPage({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityMyEvents,
        queryParameters: {'page': page - 1, 'size': limit},
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      return EventPageModel<EventModel>.fromJson(rawData, EventModel.fromJson);
    }
    throw const AppError(
      message: 'Failed to load your events.',
      errorCode: 'MY_EVENTS_FAILED',
    );
  }

  Future<EventModel> getEventDetails(String eventId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.communityEventDetail(eventId)),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return EventModel.fromJson(rawData);
      }
    }

    throw const AppError(
      message: 'Failed to load event details.',
      errorCode: 'EVENT_DETAIL_FAILED',
    );
  }

  Future<bool> deleteEvent(String eventId) async {
    final response = await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityEventDetail(eventId)),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to delete event.',
      errorCode: 'EVENT_DELETE_FAILED',
    );
  }

  Future<EventModel> updateEvent(
    String eventId,
    EventCreateRequest request,
  ) async {
    final response = await guardDio(
      () => dio.put<dynamic>(
        ApiEndpoints.communityEventDetail(eventId),
        data: request.toJson(),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return EventModel.fromJson(rawData);
      }
    }
    throw const AppError(
      message: 'Failed to update event.',
      errorCode: 'EVENT_UPDATE_FAILED',
    );
  }

  Future<List<EventAttendeeModel>> getEventAttendees(
    String eventId, {
    int page = 1,
    int limit = 50,
  }) async {
    final result = await getEventAttendeesPage(
      eventId,
      page: page,
      limit: limit,
    );
    return result.content;
  }

  Future<EventPageModel<EventAttendeeModel>> getEventAttendeesPage(
    String eventId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityEventAttendees(eventId),
        queryParameters: {'page': page - 1, 'size': limit},
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      return EventPageModel<EventAttendeeModel>.fromJson(
        rawData,
        EventAttendeeModel.fromJson,
      );
    }
    throw const AppError(
      message: 'Failed to load event attendees.',
      errorCode: 'EVENT_ATTENDEES_FAILED',
    );
  }

  Future<bool> toggleEventBookmark(
    String eventId, {
    required bool isCurrentlyBookmarked,
  }) async {
    final response = await guardDio(
      () => isCurrentlyBookmarked
          ? dio.delete<dynamic>(ApiEndpoints.profileSavedItem('EVENT', eventId))
          : dio.post<dynamic>(
              ApiEndpoints.profileSaved,
              data: {'itemType': 'EVENT', 'itemId': eventId},
            ),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return true;
    }
    throw const AppError(
      message: 'Failed to update bookmark',
      errorCode: 'BOOKMARK_UPDATE_FAILED',
    );
  }

  Future<Set<String>> getSavedEventIds() async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.profileSaved,
        queryParameters: {'type': 'EVENT'},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const AppError(
        message: 'Saved event status could not be loaded.',
        errorCode: 'SAVED_EVENT_IDS_FETCH_FAILED',
      );
    }
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    final list = rawData is List
        ? rawData
        : (rawData is Map<String, dynamic> ? rawData['content'] : null);
    if (list is! List) {
      throw const AppError(
        message: 'Saved event status response is invalid.',
        errorCode: 'SAVED_EVENT_IDS_RESPONSE_INVALID',
      );
    }
    final set = <String>{};
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final id = item['itemId']?.toString() ?? item['id']?.toString();
        if (id != null && id.isNotEmpty) {
          set.add(id);
        }
      }
    }
    return set;
  }

  // ── Opportunities (Career) ──────────────────────────────────────────

  Future<List<OpportunityModel>> getOpportunities({
    String? type,
    bool includeExpired = false,
    int page = 0,
    int size = 20,
  }) async => (await getOpportunitiesPage(
    type: type,
    includeExpired: includeExpired,
    page: page + 1,
    size: size,
  )).content;

  Future<EventPageModel<OpportunityModel>> getOpportunitiesPage({
    String? type,
    bool includeExpired = false,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'includeExpired': includeExpired,
        'page': page - 1,
        'size': size,
      };
      if (type != null &&
          type.trim().isNotEmpty &&
          type.toUpperCase() != 'ALL') {
        queryParams['type'] = type.trim().toUpperCase();
      }

      final response = await guardDio(
        () => dio.get<dynamic>(
          ApiEndpoints.communityOpportunities,
          queryParameters: queryParams,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final rawData = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
        _requirePageContent(
          rawData,
          code: 'OPPORTUNITIES_RESPONSE_INVALID',
          message: 'The opportunities response is invalid.',
        );
        return EventPageModel<OpportunityModel>.fromJson(
          rawData,
          OpportunityModel.fromJson,
        );
      }
      throw const AppError(
        message: 'The opportunities response could not be loaded.',
        errorCode: 'OPPORTUNITIES_RESPONSE_INVALID',
      );
    } catch (e) {
      debugPrint('[CommunityRemoteDataSource] getOpportunities error: $e');
      rethrow;
    }
  }

  Future<OpportunityModel> getOpportunityById(String opportunityId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityOpportunityDetail(opportunityId),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return OpportunityModel.fromJson(rawData);
      }
    }
    throw const AppError(
      message: 'Failed to load opportunity',
      errorCode: 'OPPORTUNITY_NOT_FOUND',
    );
  }

  Future<bool> toggleSaveOpportunity(
    String opportunityId,
    bool currentlySaved,
  ) async {
    if (currentlySaved) {
      final response = await guardDio(
        () => dio.delete<dynamic>(
          ApiEndpoints.profileSavedItem('OPPORTUNITY', opportunityId),
        ),
      );
      return response.statusCode == 200 || response.statusCode == 204
          ? false
          : true;
    } else {
      final response = await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.profileSaved,
          data: {'itemType': 'OPPORTUNITY', 'itemId': opportunityId},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201
          ? true
          : false;
    }
  }

  Future<OpportunityModel> createOpportunity({
    required String title,
    String? organization,
    String? type,
    String? description,
    DateTime? deadline,
    String? location,
    String? applyLink,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityOpportunities,
        data: {
          'title': title.trim(),
          if (organization != null && organization.trim().isNotEmpty)
            'organization': organization.trim(),
          if (type != null && type.trim().isNotEmpty)
            'type': type.trim().toUpperCase(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (deadline != null)
            'deadline':
                '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
          if (location != null && location.trim().isNotEmpty)
            'location': location.trim(),
          if (applyLink != null && applyLink.trim().isNotEmpty)
            'applyLink': applyLink.trim(),
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        return OpportunityModel.fromJson(rawData);
      }
    }
    throw const AppError(
      message: 'Failed to create opportunity',
      errorCode: 'CREATE_OPPORTUNITY_FAILED',
    );
  }
}
