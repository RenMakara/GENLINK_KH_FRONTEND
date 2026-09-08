import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../finance/domain/entities/finance_entities.dart';
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
        subtitle:
            'Exploring practical AI applications for students & creators.',
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

  /// Fetches persisted events. Event reads intentionally do not fall back to
  /// mock data here; the controller may keep its seeded cards when the API is
  /// unavailable, but a successful response always reflects the backend.
  Future<List<EventModel>> fetchEvents({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.communityEvents,
        queryParameters: {
          'page': page - 1,
          'size': limit,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      ),
    );
    final data = _responseData(response);
    final content = data is Map ? data['content'] : data;
    if (content is! List) return const [];
    return content
        .whereType<Map>()
        .map((item) => _eventFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<EventModel> createEvent(EventCreateInput input) async {
    final isOnline = input.eventType.toLowerCase().contains('online');
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityEvents,
        data: {
          'title': input.title,
          'description': input.description,
          'category': input.category,
          'startDateTime': input.startDateTime.toIso8601String(),
          'endDateTime': input.endDateTime.toIso8601String(),
          'mode': isOnline ? 'ONLINE' : 'IN_PERSON',
          'meetingUrl': isOnline ? input.meetingUrl : null,
          'locationName': isOnline ? null : input.locationName,
          'latitude': input.latitude,
          'longitude': input.longitude,
          'attendeeLimit': input.attendeeLimit,
          'status': 'PUBLISHED',
          'language': 'ENGLISH',
          'paid': input.paid,
          'price': input.paid ? input.price : null,
          'currency': input.paid ? input.currency?.apiValue : null,
        },
      ),
    );
    final data = _responseData(response);
    if (data is! Map) {
      throw StateError('The event create response did not contain event data.');
    }
    return _eventFromJson(Map<String, dynamic>.from(data));
  }

  Future<EventRsvpResult> registerForEvent(
    String eventId,
    EventRegistrationInput input,
  ) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.communityEventRsvp(eventId),
        data: {
          'fullName': input.fullName,
          'email': input.email,
          'phoneNumber': input.phoneNumber,
          'university': input.university,
          'faculty': input.faculty,
          'studyYear': input.studyYear,
          'termsAccepted': input.termsAccepted,
        },
      ),
    );
    final data = _responseData(response);
    if (data is! Map) {
      throw StateError('The RSVP response did not contain confirmation data.');
    }
    final json = Map<String, dynamic>.from(data);
    return EventRsvpResult(
      eventId: (json['eventId'] ?? eventId).toString(),
      status: (json['status'] ?? 'JOINED').toString(),
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      chargedAmount: (json['amountPaid'] as num?)?.toDouble(),
      paymentSimulated: json['simulatedPayment'] == true,
    );
  }

  Future<void> cancelEventRegistration(String eventId) async {
    await guardDio(
      () => dio.delete<dynamic>(ApiEndpoints.communityEventRsvp(eventId)),
    );
  }

  dynamic _responseData(Response<dynamic> response) {
    final body = response.data;
    if (body is Map) return body['data'] ?? body;
    return body;
  }

  EventModel _eventFromJson(Map<String, dynamic> json) {
    final start = _parseDate(json['startDateTime'] ?? json['dateTime']);
    final end = _parseDate(json['endDateTime']);
    final mode = (json['mode'] ?? 'IN_PERSON').toString().toUpperCase();
    final organizer = json['organizer'] is Map
        ? Map<String, dynamic>.from(json['organizer'] as Map)
        : const <String, dynamic>{};
    final rsvpStatus = (json['myRsvpStatus'] ?? '').toString().toUpperCase();

    return EventModel(
      id: (json['eventId'] ?? json['id']).toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['description'] ?? '').toString().split('\n').first,
      organizerName: (organizer['fullName'] ?? '').toString(),
      eventType: mode == 'ONLINE' ? 'Online' : 'In person',
      location: (json['locationName'] ?? '').toString(),
      onlineLink: (json['meetingUrl'] ?? '').toString(),
      startDateTime: start,
      endDateTime: end,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateString: start == null ? '' : _formatEventDate(start),
      timeString: start == null ? '' : _formatEventTime(start, end),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      isPaid: json['paid'] == true,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: parseFinanceCurrency(json['currency'] ?? 'USD'),
      imageUrl: (json['coverImageUrl'] ?? '').toString(),
      attendeesCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      isRsvped: rsvpStatus == 'JOINED',
    );
  }

  DateTime? _parseDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  String _formatEventDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _formatEventTime(DateTime start, DateTime? end) {
    final startLabel = _formatClock(start);
    return end == null ? startLabel : '$startLabel – ${_formatClock(end)}';
  }

  String _formatClock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
        () => dio.delete<dynamic>(ApiEndpoints.communityPostRepost(postId)),
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
        data: {'content': content, 'parentCommentId': ?parentCommentId},
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
      title:
          'Best practices for GetX state management in Flutter Community App',
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
      title:
          'Study group for CADT Data Structures and Algorithms exam next week',
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
        dynamic rawData = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
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
                    ForumTopicModel.fromJson(json as Map<String, dynamic>),
              )
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
        final data = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : null;
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
          data: {'title': title, 'content': content, 'category': category},
        ),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : null;
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
