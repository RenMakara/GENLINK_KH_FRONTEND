import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_post_model.dart';

class CommunityRemoteDataSource {
  final Dio dio;

  CommunityRemoteDataSource({required this.dio});

  // Local fallback memory store for optimistic updates & dev testing
  final List<CommunityPostModel> _mockPosts = [
    CommunityPostModel(
      id: 'post_me',
      userId: 'user_me',
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
      authorAvatar: 'assets/images/user_profile.png',
      isVerified: false,
      timeAgo: '15m ago',
      content:
          'Building cross-platform mobile apps with Flutter & Cloud Infrastructure at ACLEDA University of Business! 🚀💻 #Flutter #CloudComputing #CampusLink',
      imageUrls: [
        'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
      ],
      likesCount: 42,
      commentsCount: 8,
      sharesCount: 2,
      isLiked: false,
      isBookmarked: false,
      isOwner: true,
      community: 'ACLEDA University of Business',
    ),
    CommunityPostModel(
      id: 'post_chansela',
      userId: 'user_chansela',
      authorName: 'Heng Chansela',
      authorTag: '@hengchansela',
      authorAvatar: 'assets/images/heng_chansela_profile.png',
      isVerified: false,
      timeAgo: '2h ago',
      content:
          '❤️ Creating beautiful memories together after classes at AUB.\nCampus life is more meaningful when you have someone to share every moment with. ☕📸',
      imageUrls: ['assets/images/heng_chansela_post.png'],
      location: 'ACLEDA University of Business, Phnom Penh',
      likesCount: 42,
      commentsCount: 8,
      sharesCount: 3,
      isLiked: true,
      isBookmarked: false,
      isOwner: false,
      community: 'ACLEDA University of Business (AUB)',
    ),
    CommunityPostModel(
      id: 'post_makara',
      userId: 'user_makara',
      authorName: 'Ren Makara',
      authorTag: '@renmakara',
      authorAvatar: 'assets/images/ren_makara_profile.png',
      isVerified: false,
      timeAgo: '5h ago',
      content:
          '🚀 មកស្គាល់គម្រោង «AuthGate»\n\nAuthGate គឺជាប្រព័ន្ធគ្រប់គ្រងសិទ្ធិចូលប្រើប្រាស់ និងផ្ទៀងផ្ទាត់អត្តសញ្ញាណ (Authentication & Access Control System) ដែលអភិវឌ្ឍដោយប្រើ Spring Boot Microservices។\n\nFeatures:\n• Secure Login & Authentication\n• Role-Based Access Control (RBAC)\n• JWT Authentication\n• Refresh Token\n• REST API\n• Spring Boot Microservices\n• Docker\n• Swagger API Documentation\n\n#SpringBoot #Microservices #Java #BackendDevelopment #Docker #JWT #AuthGate',
      imageUrls: ['assets/images/authgate_project.png'],
      location: 'ACLEDA University of Business',
      likesCount: 65,
      commentsCount: 14,
      sharesCount: 8,
      isLiked: false,
      isBookmarked: false,
      isOwner: false,
      community: 'ACLEDA University of Business (AUB)',
    ),
  ];

  Future<List<CommunityPostModel>> fetchPosts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
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
                (json) =>
                    CommunityPostModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (_) {}
    return _mockPosts;
  }

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    final newPost = CommunityPostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
      authorAvatar: 'assets/images/user_profile.png',
      isVerified: false,
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isLiked: false,
      isBookmarked: false,
      isOwner: true,
      visibility: visibility,
      community: community,
    );

    try {
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
    } catch (_) {}

    _mockPosts.insert(0, newPost);
    return newPost;
  }

  Future<bool> deletePost(String postId) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>(ApiEndpoints.communityPostDetail(postId)),
      );
    } catch (_) {}
    _mockPosts.removeWhere((p) => p.id == postId);
    return true;
  }

  Future<bool> toggleLike(String postId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>(ApiEndpoints.communityPostLike(postId)),
      );
    } catch (_) {}
    final idx = _mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = _mockPosts[idx];
      p.isLiked = !p.isLiked;
      p.likesCount += p.isLiked ? 1 : -1;
    }
    return true;
  }

  Future<bool> toggleBookmark(String postId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>(ApiEndpoints.communityPostBookmark(postId)),
      );
    } catch (_) {}
    final idx = _mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _mockPosts[idx].isBookmarked = !_mockPosts[idx].isBookmarked;
    }
    return true;
  }

  Future<bool> repostPost(
    String postId, {
    String? caption,
    String? reposterId,
  }) async {
    try {
      await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.communityPostRepost(postId),
          data: {'caption': caption},
        ),
      );
    } catch (_) {}
    final idx = _mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = _mockPosts[idx];
      _mockPosts[idx] = p.copyWith(
        sharesCount: p.sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: 'Sokny Enat',
        repostCaption: caption,
        reposterId: reposterId ?? 'user_me',
        originalPostId: p.id,
      );
    }
    return true;
  }

  Future<bool> unrepostPost(String postId, {String? reposterId}) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>(
          ApiEndpoints.communityPostRepost(postId),
        ),
      );
    } catch (_) {}
    final idx = _mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = _mockPosts[idx];
      _mockPosts[idx] = p.copyWith(
        sharesCount: p.sharesCount > 0 ? p.sharesCount - 1 : 0,
        clearRepostInfo: true,
      );
    }
    return true;
  }

  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) async {
    try {
      await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.communityPostReport(postId),
          data: {'reason': reason},
        ),
      );
    } catch (_) {}
    return true;
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(ApiEndpoints.communityPostComments(postId)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final rawData = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
        if (rawData is List) {
          return rawData
              .map(
                (json) => CommentModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (_) {}

    return [
      CommentModel(
        id: 'c_1',
        postId: postId,
        userId: 'u_10',
        userName: 'Rathana P.',
        userAvatar: 'assets/images/user_profile.png',
        text: 'Awesome post! Looking forward to seeing more updates 🔥',
        timeAgo: '1h ago',
        likesCount: 3,
      ),
      CommentModel(
        id: 'c_2',
        postId: postId,
        userId: 'u_11',
        userName: 'Sothea N.',
        userAvatar: 'assets/images/user_profile.png',
        text: 'Great work team! Keep it up 👏',
        timeAgo: '30m ago',
        likesCount: 1,
      ),
    ];
  }

  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final comment = CommentModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: 'current_user',
      userName: 'Sokny Enat',
      userAvatar: 'assets/images/user_profile.png',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );

    try {
      await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.communityPostComments(postId),
          data: {'text': text, 'parentCommentId': parentCommentId},
        ),
      );
    } catch (_) {}

    final idx = _mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _mockPosts[idx].commentsCount += 1;
    }
    return comment;
  }

  Future<List<CommentModel>> fetchDiscussionComments(
    String discussionId,
  ) async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(
          ApiEndpoints.communityDiscussionComments(discussionId),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        dynamic rawData;
        if (body is Map<String, dynamic>) {
          rawData = body['data'] ?? body;
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
                (json) => CommentModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (_) {}

    return [];
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
          'parentCommentId': ?parentCommentId,
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

    return CommentModel(
      id: 'dc_${DateTime.now().millisecondsSinceEpoch}',
      postId: discussionId,
      userId: 'current_user',
      userName: 'Sokny Enat',
      userAvatar: 'assets/images/user_profile.png',
      text: content,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );
  }

  final Set<String> _mockFollowedUserIds = <String>{};

  Future<bool> followUser(String userId) async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>(ApiEndpoints.communityFollowUser(userId)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _mockFollowedUserIds.add(userId);
        _updateMockPostsFollowStatus(userId, true);
        return true;
      }
    } catch (e) {
      if (e is AppError && e.errorCode == 'NETWORK_ERROR') {
        _mockFollowedUserIds.add(userId);
        _updateMockPostsFollowStatus(userId, true);
        return true;
      }
      rethrow;
    }
    _mockFollowedUserIds.add(userId);
    _updateMockPostsFollowStatus(userId, true);
    return true;
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      final response = await guardDio(
        () => dio.delete<dynamic>(ApiEndpoints.communityFollowUser(userId)),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _mockFollowedUserIds.remove(userId);
        _updateMockPostsFollowStatus(userId, false);
        return true;
      }
    } catch (e) {
      if (e is AppError && e.errorCode == 'NETWORK_ERROR') {
        _mockFollowedUserIds.remove(userId);
        _updateMockPostsFollowStatus(userId, false);
        return true;
      }
      rethrow;
    }
    _mockFollowedUserIds.remove(userId);
    _updateMockPostsFollowStatus(userId, false);
    return true;
  }

  Future<bool> checkIsFollowing(String userId) async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(ApiEndpoints.communityFollowStats(userId)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          final followStatus = data['followStatus'];
          final isFollowing =
              followStatus == 'ACCEPTED' || followStatus == 'PENDING';
          if (isFollowing) {
            _mockFollowedUserIds.add(userId);
          } else {
            _mockFollowedUserIds.remove(userId);
          }
          _updateMockPostsFollowStatus(userId, isFollowing);
          return isFollowing;
        }
      }
    } catch (_) {}
    return _mockFollowedUserIds.contains(userId);
  }

  void _updateMockPostsFollowStatus(String userId, bool isFollowing) {
    for (int i = 0; i < _mockPosts.length; i++) {
      if (_mockPosts[i].userId == userId) {
        _mockPosts[i].isFollowing = isFollowing;
      }
    }
  }
}
