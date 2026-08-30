import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_models.dart';
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

  final List<ForumTopicModel> _mockDiscussions = [
    ForumTopicModel(
      id: 'latest_1',
      authorId: 'user_me',
      title: 'Best practices for GetX state management in Flutter Community App',
      authorName: 'Sokny Enat',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      category: 'Technology',
      content:
          'When structuring large Flutter apps with GetX, prefer domain separation, avoid calling Get.put inside build methods, and use bindings for deterministic lifecycle management.',
      repliesCount: 24,
      upvotes: 89,
      isLiked: false,
      isOwner: true,
    ),
    ForumTopicModel(
      id: 'latest_3',
      authorId: 'u2',
      title: 'Study group for CADT Data Structures and Algorithms exam next week',
      authorName: 'Heng Chansela',
      authorAvatar: 'assets/images/heng_chansela_profile.png',
      timeAgo: '5h ago',
      category: 'Study & Education',
      content:
          'We are organizing an online and on-campus study session for DSA. Topics include Dynamic Programming, Graph Traversals, and Complexity Analysis.',
      repliesCount: 31,
      upvotes: 67,
      isLiked: false,
      isOwner: false,
    ),
    ForumTopicModel(
      id: 'latest_4',
      authorId: 'u3',
      title: 'Sharing my AI project built with Python and Flutter Web',
      authorName: 'Ren Makara',
      authorAvatar: 'assets/images/ren_makara_profile.png',
      timeAgo: '7h ago',
      category: 'Projects',
      content:
          'Hey everyone! I just published my open-source project combining Flutter frontend with a FastAPI backend. Check out the demo and repo.',
      repliesCount: 14,
      upvotes: 53,
      isLiked: false,
      isOwner: false,
    ),
    ForumTopicModel(
      id: 'latest_5',
      authorId: 'u4',
      title: 'Campus Hackathon 2026 registration is officially open!',
      authorName: 'Chhaeng Sokuntheara',
      authorAvatar: 'assets/images/sokuntheara_profile.png',
      timeAgo: '12h ago',
      category: 'Events',
      content:
          'Excited to announce GenLink KH Campus Hackathon 2026! Over 50 teams will compete over 48 hours to solve real community challenges.',
      repliesCount: 42,
      upvotes: 110,
      isLiked: false,
      isOwner: false,
    ),
  ];

  Future<List<ForumTopicModel>> fetchDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page - 1,
        'size': limit,
      };
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
        dynamic rawData =
            body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        List<dynamic> content = [];
        if (rawData is Map<String, dynamic>) {
          content = (rawData['content'] as List<dynamic>?) ?? [];
        } else if (rawData is List) {
          content = rawData;
        }
        if (content.isNotEmpty) {
          return content
              .map((json) =>
                  ForumTopicModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    if (category != null && category.isNotEmpty && category != 'All') {
      return _mockDiscussions.where((d) => d.category == category).toList();
    }
    return _mockDiscussions;
  }

  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final newDiscussion = ForumTopicModel(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'user_me',
      title: title,
      authorName: 'Sokny Enat',
      authorAvatar: 'assets/images/user_profile.png',
      category: category,
      content: content,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
      isLiked: false,
      isPinned: false,
      isOwner: true,
    );

    try {
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
        final data =
            body is Map<String, dynamic> ? (body['data'] ?? body) : null;
        if (data is Map<String, dynamic>) {
          return ForumTopicModel.fromJson(data);
        }
      }
    } catch (_) {}

    _mockDiscussions.insert(0, newDiscussion);
    return newDiscussion;
  }

  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final response = await guardDio(
        () => dio.put<dynamic>(
          ApiEndpoints.communityDiscussionDetail(discussionId),
          data: {
            'title': title,
            'content': content,
            'category': category,
          },
        ),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        final data =
            body is Map<String, dynamic> ? (body['data'] ?? body) : null;
        if (data is Map<String, dynamic>) {
          return ForumTopicModel.fromJson(data);
        }
      }
    } catch (_) {}

    final idx = _mockDiscussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      final updated = _mockDiscussions[idx].copyWith(
        title: title,
        content: content,
        category: category,
      );
      _mockDiscussions[idx] = updated;
      return updated;
    }
    return ForumTopicModel(
      id: discussionId,
      authorId: 'user_me',
      title: title,
      authorName: 'Sokny Enat',
      category: category,
      content: content,
      timeAgo: 'Just now',
      isOwner: true,
    );
  }

  Future<bool> deleteDiscussion(String discussionId) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>(
          ApiEndpoints.communityDiscussionDetail(discussionId),
        ),
      );
    } catch (_) {}
    _mockDiscussions.removeWhere((d) => d.id == discussionId);
    return true;
  }

  Future<bool> toggleDiscussionLike(String discussionId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>(
          ApiEndpoints.communityDiscussionReact(discussionId),
        ),
      );
    } catch (_) {}
    final idx = _mockDiscussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      final d = _mockDiscussions[idx];
      d.isLiked = !d.isLiked;
      d.upvotes += d.isLiked ? 1 : -1;
    }
    return true;
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
