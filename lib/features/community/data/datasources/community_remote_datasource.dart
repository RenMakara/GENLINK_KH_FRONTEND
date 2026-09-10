import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../../../shared/utils/current_user.dart';

class CommunityRemoteDataSource {
  final Dio dio;

  CommunityRemoteDataSource({required this.dio});

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
      isOwner: false,
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
      id: 'post_flutter_workshop_event',
      userId: 'user_aub',
      authorName: 'AUB Digital Academy',
      authorTag: '@aub_academy',
      authorAvatar: 'assets/images/user_profile.png',
      isVerified: true,
      timeAgo: '3h ago',
      content:
          '🚀 Excited to announce our upcoming Flutter Workshop 2026! Learn how to build clean architecture mobile apps with reactive state management. Register below to secure your seat! 📱✨ #Flutter #MobileDev #AUB',
      likesCount: 88,
      commentsCount: 16,
      sharesCount: 12,
      isLiked: false,
      isBookmarked: false,
      isOwner: false,
      community: 'ACLEDA University of Business (AUB)',
      postType: 'event',
      attachedEvent: EventModel(
        id: 'ev1',
        title: 'Flutter Workshop 2026',
        subtitle: 'Build real-world mobile apps with Flutter from scratch.',
        organizerName: 'AUB Digital Academy',
        eventType: 'In person',
        location: 'ACLEDA University, Phnom Penh',
        dateString: '25 Jul 2026',
        timeString: '9:00 AM – 4:00 PM',
        description:
            'Join us for an intensive hands-on workshop where you will learn how to build beautiful and high-performance cross-platform applications using Flutter.\n\nWhether you are a beginner or looking to enhance your skills, this workshop covers clean architecture, reactive state management with GetX, and real-world backend API integration.',
        category: 'Workshop',
        imageUrl:
            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&auto=format&fit=crop&q=80',
        attendeesCount: 120,
        attendeeAvatars: [
          'assets/images/user_profile.png',
          'assets/images/heng_chansela_profile.png',
          'assets/images/ren_makara_profile.png',
        ],
      ),
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
    CommunityPostModel(
      id: 'post_ai_seminar_event',
      userId: 'user_cadt',
      authorName: 'CADT Innovation Lab',
      authorTag: '@cadt_lab',
      authorAvatar: 'assets/images/user_profile.png',
      isVerified: true,
      timeAgo: '1d ago',
      content:
          '🌐 Join us for an inspiring session on AI in Everyday Life! Explore practical LLM tooling and automation strategies for student builders. Free virtual attendance via Google Meet 🤖💡',
      likesCount: 142,
      commentsCount: 29,
      sharesCount: 22,
      isLiked: true,
      isBookmarked: false,
      isOwner: false,
      community: 'All GenLink',
      postType: 'event',
      attachedEvent: EventModel(
        id: 'ev2',
        title: 'AI in Everyday Life',
        subtitle: 'Exploring practical AI applications for students & creators.',
        organizerName: 'CADT Innovation Lab',
        eventType: 'Online',
        onlineLink: 'https://meet.google.com/genlink-ai-2026',
        location: '',
        dateString: '28 Jul 2026',
        timeString: '2:00 PM – 5:00 PM',
        description:
            'Discover how artificial intelligence is transforming everyday productivity, software development, and campus workflows. Live demos, Q&A with industry engineers, and resource giveaways.',
        category: 'Seminar',
        imageUrl:
            'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=1200&auto=format&fit=crop&q=80',
        attendeesCount: 245,
        attendeeAvatars: [
          'assets/images/user_profile.png',
          'assets/images/heng_chansela_profile.png',
        ],
      ),
    ),
  ];

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

      return content
          .map(
            (json) =>
                CommunityPostModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    return const <CommunityPostModel>[];
  }

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    String resolvedVisibility;
    switch (visibility.toUpperCase()) {
      case 'FRIENDS':
        resolvedVisibility = 'FRIENDS';
        break;
      case 'COMMUNITY':
        resolvedVisibility = 'COMMUNITY';
        break;
      default:
        resolvedVisibility = 'PUBLIC';
    }

    final postType = imageUrls.isNotEmpty ? 'IMAGE' : 'TEXT';

    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityPosts,
        data: {
          'contentText': content,
          'imageUrl': imageUrls.isNotEmpty ? imageUrls.join(',') : null,
          'visibility': resolvedVisibility,
          'postType': postType,
        },
      ),
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
      final currentUserName = CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
          ? CurrentUser.name
          : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'User');
      final effectiveReposterId = reposterId ?? (CurrentUser.id.isNotEmpty ? CurrentUser.id : 'current_user');
      final p = _mockPosts[idx];
      _mockPosts[idx] = p.copyWith(
        sharesCount: p.sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: currentUserName,
        repostCaption: caption,
        reposterId: effectiveReposterId,
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
    final currentUserName = CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
        ? CurrentUser.name
        : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'User');
    final comment = CommentModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: CurrentUser.id.isNotEmpty ? CurrentUser.id : 'current_user',
      userName: currentUserName,
      userAvatar: CurrentUser.avatarUrl ?? '',
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
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionComments(discussionId),
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

      return content
          .map(
            (json) => CommentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
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

  Future<List<ForumTopicModel>> fetchDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
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
      return content
          .map((json) =>
              ForumTopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
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
      final data =
          body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        return ForumTopicModel.fromJson(data);
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
  }) async {
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

  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityDiscussionDetail(discussionId),
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final data =
          body is Map<String, dynamic> ? (body['data'] ?? body) : null;
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

  Future<RsvpResponseModel> rsvpEvent(
    String eventId, {
    EventRegistrationRequest? request,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityEventRsvp(eventId),
        data: request?.toJson(),
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
}
