import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import 'story_controller.dart';

class CommunityController extends GetxController {
  late CommunityRepository repository;
  final CommunityRepository? _injectedRepository;

  CommunityController({CommunityRepository? repository})
      : _injectedRepository = repository {
    if (repository != null) {
      this.repository = repository;
    }
  }

  final ScrollController scrollController = ScrollController();

  String? get currentUserId {
    final id = CurrentUser.id;
    if (id.isNotEmpty) return id;
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.id;
    }
    return null;
  }

  String get currentUserName {
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser.value;
      if (user != null) {
        if (user.fullName.isNotEmpty) return user.fullName;
        if (user.username.isNotEmpty) return user.username;
      }
    }
    return '';
  }

  final selectedCategory = 'Feed'.obs;
  final selectedForumCategory = 'All'.obs;
  final categories = ['Feed', 'Forum', 'Event'];

  final isLoadingFeed = false.obs;
  final isRefreshingFeed = false.obs;
  final isLoadingMore = false.obs;
  final hasMorePosts = true.obs;
  final currentPage = 1.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  final isUploadingPost = false.obs;
  final uploadProgress = 0.0.obs;

  final posts = <CommunityPostModel>[].obs;
  final activeComments = <CommentModel>[].obs;
  final isLoadingComments = false.obs;
  final followLoadingUserIds = <String>{}.obs;

  final stories = <StoryModel>[
    StoryModel(
      id: '1',
      name: 'Your Story',
      avatarText: 'S',
      isUser: true,
      hasActiveStory: false,
    ),
    StoryModel(id: '2', name: 'Dary', avatarText: 'D', hasActiveStory: true),
    StoryModel(
      id: '3',
      name: 'AIS Tech Club',
      avatarText: 'AIS',
      hasActiveStory: true,
    ),
    StoryModel(id: '4', name: 'MayMay', avatarText: 'M', hasActiveStory: true),
  ].obs;

  final recommendedGroups = <RecommendedGroupModel>[
    RecommendedGroupModel(
      id: 'g1',
      name: 'IT Club Cambodia',
      memberCount: '1.2k Members',
      iconText: 'IT',
    ),
    RecommendedGroupModel(
      id: 'g2',
      name: 'UI/UX Design KH',
      memberCount: '850 Members',
      iconText: 'UX',
    ),
  ].obs;

  final suggestedUsers = <SuggestedUserModel>[
    SuggestedUserModel(
      id: 'u1',
      name: 'Rathana P.',
      role: 'Mobile Dev at CADT',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    SuggestedUserModel(
      id: 'u2',
      name: 'Sothea N.',
      role: 'Product Designer',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
  ].obs;

  final events = <EventModel>[
    EventModel(
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
    EventModel(
      id: 'ev2',
      title: 'AI in Everyday Life',
      subtitle: 'Explore the future of intelligent student & campus applications',
      organizerName: 'Cambodia Academy of Digital Technology',
      eventType: 'Online',
      onlineLink: 'https://meet.google.com/abc-defg-hij',
      dateString: '26 Jul 2026',
      timeString: '2:00 PM – 5:00 PM',
      description:
          'Discover how artificial intelligence is transforming daily life, academic research, and engineering. Explore the technology behind modern LLMs, neural networks, and computer vision.',
      category: 'Seminar',
      imageUrl:
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&auto=format&fit=crop&q=80',
      attendeesCount: 85,
      attendeeAvatars: [
        'assets/images/heng_chansela_profile.png',
        'assets/images/user_profile.png',
      ],
    ),
    EventModel(
      id: 'ev3',
      title: 'GenLink Hackathon 2026',
      subtitle: 'Code, collaborate, and build solutions for community challenges',
      organizerName: 'GenLink Developer Community',
      eventType: 'In person',
      location: 'Diamond Island Convention Center, Phnom Penh',
      dateString: '30 Jul 2026',
      timeString: '8:00 AM – 8:00 PM',
      description:
          '12 hours. Real problems. Real prizes. Join hundreds of Cambodia\'s brightest student developers, designers, and innovators to build products that solve real-world campus problems.',
      category: 'Hackathon',
      imageUrl:
          'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1200&auto=format&fit=crop&q=80',
      attendeesCount: 230,
      attendeeAvatars: [
        'assets/images/ren_makara_profile.png',
        'assets/images/user_profile.png',
        'assets/images/heng_chansela_profile.png',
      ],
    ),
    EventModel(
      id: 'ev4',
      title: 'Career Talk Series: Tech in Banking',
      subtitle: 'Navigating software engineering opportunities in Cambodia\'s leading financial institutions',
      organizerName: 'ACLEDA Bank Plc.',
      eventType: 'In person',
      location: 'ACLEDA University Campus, Phnom Penh',
      dateString: '2 Aug 2026',
      timeString: '9:30 AM – 12:00 PM',
      description:
          'Meet senior engineering leads, software architects, and product managers from ACLEDA Bank. Learn what it takes to land internships and junior developer roles.',
      category: 'Career',
      imageUrl:
          'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=1200&auto=format&fit=crop&q=80',
      attendeesCount: 94,
      attendeeAvatars: [
        'assets/images/user_profile.png',
        'assets/images/ren_makara_profile.png',
      ],
    ),
    EventModel(
      id: 'ev5',
      title: 'Cloud Architecture & DevOps',
      subtitle: 'Modern deployment pipelines with Docker and Kubernetes',
      organizerName: 'CADT Cloud Club',
      eventType: 'Online',
      onlineLink: 'https://meet.google.com/devops-mastery-kh',
      dateString: '8 Aug 2026',
      timeString: '3:00 PM – 5:30 PM',
      description:
          'Master modern containerization, CI/CD pipelines, and cloud native scaling strategies tailored for computer science students.',
      category: 'Technology',
      imageUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&auto=format&fit=crop&q=80',
      attendeesCount: 68,
      attendeeAvatars: [
        'assets/images/heng_chansela_profile.png',
      ],
    ),
  ].obs;

  final isCreatingEvent = false.obs;

  Future<EventModel> createEvent(
    EventCreateRequest request, {
    File? coverImageFile,
  }) async {
    isCreatingEvent.value = true;
    try {
      String? uploadedCoverUrl = request.coverImageUrl;

      if (coverImageFile != null && (uploadedCoverUrl == null || uploadedCoverUrl.isEmpty)) {
        if (Get.isRegistered<MediaUploadService>()) {
          final uploadService = Get.find<MediaUploadService>();
          final bytes = await coverImageFile.readAsBytes();
          final filename = coverImageFile.path.toLowerCase();
          final contentType = filename.endsWith('.png')
              ? 'image/png'
              : filename.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg';
          final media = await uploadService.upload(
            bytes: bytes,
            contentType: contentType,
            purpose: MediaPurpose.eventCover,
          );
          uploadedCoverUrl = media.url;
        }
      }

      final finalRequest = EventCreateRequest(
        title: request.title,
        description: request.description,
        category: request.category,
        coverImageUrl: uploadedCoverUrl,
        startDateTime: request.startDateTime,
        endDateTime: request.endDateTime,
        mode: request.mode,
        meetingUrl: request.meetingUrl,
        locationName: request.locationName,
        latitude: request.latitude,
        longitude: request.longitude,
        attendeeLimit: request.attendeeLimit,
        status: request.status,
        language: request.language,
        paid: request.paid,
        price: request.price,
        currency: request.currency,
      );

      EventModel createdEvent;
      try {
        createdEvent = await repository.createEvent(finalRequest);
      } catch (e) {
        if (e is NoSuchMethodError) {
          createdEvent = EventModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: finalRequest.title,
            description: finalRequest.description ?? '',
            category: finalRequest.category ?? '',
            eventType: finalRequest.mode == 'ONLINE' ? 'Online' : 'In person',
            mode: finalRequest.mode,
            location: finalRequest.locationName ?? '',
            locationName: finalRequest.locationName,
            onlineLink: finalRequest.meetingUrl ?? '',
            meetingUrl: finalRequest.meetingUrl,
            startDateTime: finalRequest.startDateTime,
            endDateTime: finalRequest.endDateTime,
            isPaid: finalRequest.paid,
            price: finalRequest.price,
            currency: finalRequest.currency,
            imageUrl: finalRequest.coverImageUrl ?? '',
            attendeesCount: 0,
          );
        } else {
          rethrow;
        }
      }

      final eventToStore = (coverImageFile != null && createdEvent.coverImageFile == null)
          ? createdEvent.copyWith(coverImageFile: coverImageFile)
          : createdEvent;

      events.insert(0, eventToStore);
      events.refresh();
      return eventToStore;
    } finally {
      isCreatingEvent.value = false;
    }
  }

  void addEventLocally(EventModel event) {
    events.insert(0, event);
    events.refresh();
  }

  void toggleRsvp(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final ev = events[idx];
    ev.isRsvped = !ev.isRsvped;
    ev.attendeesCount += ev.isRsvped ? 1 : -1;
    events.refresh();
  }

  final isRegisteringEvent = false.obs;

  Future<RsvpResponseModel> registerForEvent(
    String eventId,
    EventRegistrationRequest request,
  ) async {
    isRegisteringEvent.value = true;
    try {
      final response = await repository.rsvpEvent(eventId, request: request);
      final idx = events.indexWhere((e) => e.id == eventId);
      if (idx != -1) {
        final ev = events[idx];
        ev.isRsvped = true;
        ev.attendeesCount = response.attendeeCount > 0
            ? response.attendeeCount
            : ev.attendeesCount + 1;
        ev.myRsvpStatus = response.status;
        events.refresh();
      }
      return response;
    } finally {
      isRegisteringEvent.value = false;
    }
  }

  void toggleEventBookmark(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final ev = events[idx];
    ev.isBookmarked = !ev.isBookmarked;
    events.refresh();
  }

  Future<void> refreshEvents() async {
    events.refresh();
  }

  final selectedEventDate = 'All'.obs;
  final selectedEventCategories = <String>{}.obs;
  final selectedEventMode = 'All'.obs;
  final selectedEventPrice = 'All'.obs;

  bool get isEventFilterActive =>
      (selectedEventDate.value != 'All' && selectedEventDate.value.isNotEmpty) ||
      selectedEventCategories.isNotEmpty ||
      selectedEventMode.value != 'All' ||
      selectedEventPrice.value != 'All';

  List<EventModel> get filteredEvents {
    return events.where((e) {
      if (selectedEventCategories.isNotEmpty) {
        final catLower = e.category.toLowerCase();
        final matchesCategory = selectedEventCategories.any((cat) {
          final filterCatLower = cat.toLowerCase();
          return catLower.contains(filterCatLower) || filterCatLower.contains(catLower);
        });
        if (!matchesCategory) {
          return false;
        }
      }
      if (selectedEventMode.value != 'All') {
        final isOnline = e.eventType.toLowerCase().contains('online');
        final filterModeLower = selectedEventMode.value.toLowerCase();
        if (filterModeLower.contains('online') && !isOnline) {
          return false;
        }
        if ((filterModeLower.contains('in person') || filterModeLower.contains('campus')) && isOnline) {
          return false;
        }
      }
      if (selectedEventPrice.value == 'Free' && e.isPaid) {
        return false;
      }
      if (selectedEventPrice.value == 'Paid' && !e.isPaid) {
        return false;
      }
      if (selectedEventDate.value != 'All' && selectedEventDate.value.isNotEmpty) {
        final dateLower = e.dateString.toLowerCase();
        if (selectedEventDate.value == 'Today') {
          if (!dateLower.contains('today')) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  void resetEventFilter() {
    selectedEventDate.value = 'All';
    selectedEventCategories.clear();
    selectedEventMode.value = 'All';
    selectedEventPrice.value = 'All';
    events.refresh();
  }

  void applyEventFilter({
    String date = 'All',
    Set<String> categories = const {},
    String mode = 'All',
    String price = 'All',
  }) {
    selectedEventDate.value = date;
    selectedEventCategories.assignAll(categories);
    selectedEventMode.value = mode;
    selectedEventPrice.value = price;
    events.refresh();
  }

  final forumPinnedDiscussions = <ForumTopicModel>[].obs;

  final forumLatestDiscussions = <ForumTopicModel>[].obs;

  final isLoadingForumDiscussions = false.obs;
  RxBool get isLoadingDiscussions => isLoadingForumDiscussions;

  final isRefreshingForumDiscussions = false.obs;
  final hasForumError = false.obs;
  final forumErrorMessage = ''.obs;
  RxString get discussionsError => forumErrorMessage;

  final isPublishingDiscussion = false.obs;
  final inFlightDiscussionLikes = <String>{}.obs;
  final inFlightCommentLikes = <String>{}.obs;

  Future<void> fetchDiscussions({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshingForumDiscussions.value = true;
    } else {
      isLoadingForumDiscussions.value = true;
    }
    hasForumError.value = false;
    forumErrorMessage.value = '';

    try {
      final category = selectedForumCategory.value == 'All'
          ? null
          : selectedForumCategory.value;
      final fetched = await repository.getDiscussions(
        category: category,
        page: 1,
        limit: 20,
      );
      forumLatestDiscussions.assignAll(fetched);
    } catch (e) {
      hasForumError.value = true;
      forumErrorMessage.value = e is AppError
          ? e.message
          : 'Couldn\'t load discussions. Try again.';
    } finally {
      isLoadingForumDiscussions.value = false;
      isRefreshingForumDiscussions.value = false;
    }
  }

  Future<bool> toggleDiscussionLike(String discussionId) async {
    if (inFlightDiscussionLikes.contains(discussionId)) return false;
    inFlightDiscussionLikes.add(discussionId);

    final latestIdx =
        forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
    bool prevLiked = false;
    int prevUpvotes = 0;

    if (latestIdx != -1) {
      final item = forumLatestDiscussions[latestIdx];
      prevLiked = item.isLiked;
      prevUpvotes = item.upvotes;

      item.isLiked = !prevLiked;
      item.upvotes += item.isLiked ? 1 : -1;
      forumLatestDiscussions[latestIdx] = item.copyWith();
      forumLatestDiscussions.refresh();
    }

    try {
      final success = await repository.toggleDiscussionLike(
        discussionId,
        isCurrentlyLiked: prevLiked,
      );
      if (!success) {
        _rollbackDiscussionLike(discussionId, prevLiked, prevUpvotes);
      }
      return success;
    } catch (_) {
      _rollbackDiscussionLike(discussionId, prevLiked, prevUpvotes);
      return false;
    } finally {
      inFlightDiscussionLikes.remove(discussionId);
    }
  }

  void _rollbackDiscussionLike(
    String discussionId,
    bool prevLiked,
    int prevUpvotes,
  ) {
    final latestIdx =
        forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
    if (latestIdx != -1) {
      final item = forumLatestDiscussions[latestIdx];
      item.isLiked = prevLiked;
      item.upvotes = prevUpvotes;
      forumLatestDiscussions[latestIdx] = item.copyWith();
      forumLatestDiscussions.refresh();
    }
  }

  Future<ForumTopicModel> addDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    if (isPublishingDiscussion.value) {
      throw AppError(
        message: 'Publishing already in progress',
        errorCode: 'DUPLICATE_PUBLISH',
      );
    }

    isPublishingDiscussion.value = true;
    try {
      final createdTopic = await repository.createDiscussion(
        title: title,
        content: content,
        category: category,
        anonymous: anonymous,
      );

      forumLatestDiscussions.insert(0, createdTopic);
      forumLatestDiscussions.refresh();

      final existingIdx = posts.indexWhere((p) => p.id == createdTopic.id);
      if (existingIdx != -1) {
        posts[existingIdx] = posts[existingIdx].copyWith(
          content: content,
          discussionTitle: title,
          category: category,
        );
        posts.refresh();
      }

      return createdTopic;
    } finally {
      isPublishingDiscussion.value = false;
    }
  }

  Future<bool> updateDiscussion({
    required String discussionId,
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final updatedTopic = await repository.updateDiscussion(
        discussionId,
        title: title,
        content: content,
        category: category,
      );

      final forumIdx =
          forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
      if (forumIdx != -1) {
        forumLatestDiscussions[forumIdx] = updatedTopic;
        forumLatestDiscussions.refresh();
      }

      final feedIdx = posts.indexWhere((p) => p.id == discussionId);
      if (feedIdx != -1) {
        posts[feedIdx] = posts[feedIdx].copyWith(
          content: content,
          discussionTitle: title,
          category: category,
        );
        posts.refresh();
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteDiscussion(String discussionId) async {
    try {
      final success = await repository.deleteDiscussion(discussionId);
      if (success) {
        forumLatestDiscussions.removeWhere((d) => d.id == discussionId);
        forumLatestDiscussions.refresh();
        posts.removeWhere((p) => p.id == discussionId);
        posts.refresh();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  final isLoadingDiscussionDetail = false.obs;
  final discussionDetailError = ''.obs;

  Future<ForumTopicModel?> fetchDiscussionDetails(String discussionId) async {
    isLoadingDiscussionDetail.value = true;
    discussionDetailError.value = '';
    try {
      final detail = await repository.getDiscussionDetails(discussionId);
      final idx =
          forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
      if (idx != -1) {
        forumLatestDiscussions[idx] = detail;
        forumLatestDiscussions.refresh();
      }
      return detail;
    } catch (e) {
      discussionDetailError.value =
          e is AppError ? e.message : 'Failed to load discussion details';
      return null;
    } finally {
      isLoadingDiscussionDetail.value = false;
    }
  }

  ForumTopicModel? getDiscussionById(String id) {
    return forumLatestDiscussions.firstWhereOrNull((d) => d.id == id);
  }

  @override
  void onInit() {
    super.onInit();
    if (_injectedRepository != null) {
      repository = _injectedRepository;
    } else if (Get.isRegistered<CommunityRepository>()) {
      repository = Get.find<CommunityRepository>();
    } else {
      final dio =
          Get.isRegistered<Dio>() ? Get.find<Dio>() : DioProvider.create();
      final dataSource = CommunityRemoteDataSource(dio: dio);
      repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
    }

    scrollController.addListener(_onScrollListener);
    fetchPosts();
    fetchDiscussions();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _onScrollListener() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        !isLoadingFeed.value &&
        hasMorePosts.value &&
        selectedCategory.value == 'Feed') {
      loadMorePosts();
    }
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshingFeed.value = true;
    } else {
      isLoadingFeed.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      currentPage.value = 1;
      final fetched = await repository.getPosts(page: 1, limit: 10);
      posts.assignAll(fetched);
      hasMorePosts.value = fetched.length >= 10;
      _syncFollowStates(fetched);
    } catch (e) {
      hasError.value = true;
      if (e is AppError) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Failed to load community feed.';
      }
    } finally {
      isLoadingFeed.value = false;
      isRefreshingFeed.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMorePosts.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final fetched = await repository.getPosts(page: nextPage, limit: 10);
      if (fetched.isNotEmpty) {
        for (final item in fetched) {
          final existingIdx = posts.indexWhere((p) => p.id == item.id);
          if (existingIdx == -1) {
            posts.add(item);
          }
        }
        currentPage.value = nextPage;
        hasMorePosts.value = fetched.length >= 10;
        _syncFollowStates(fetched);
      } else {
        hasMorePosts.value = false;
      }
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (Get.isRegistered<StoryController>()) {
      Get.find<StoryController>().fetchStories();
    }
    await Future.wait([
      fetchPosts(isRefresh: true),
      fetchDiscussions(isRefresh: true),
    ]);
  }

  Future<List<String>> _resolveImageUrls(List<String> rawUrls) async {
    final resolved = <String>[];
    final total = rawUrls.length;
    int index = 0;

    for (final img in rawUrls) {
      if (img.startsWith('http://') ||
          img.startsWith('https://') ||
          img.startsWith('assets/')) {
        resolved.add(img);
      } else {
        final file = File(img);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final ext = img.split('.').last.toLowerCase();
          final contentType = (ext == 'png')
              ? 'image/png'
              : (ext == 'webp')
                  ? 'image/webp'
                  : 'image/jpeg';

          if (Get.isRegistered<MediaUploadService>()) {
            final uploadService = Get.find<MediaUploadService>();
            final media = await uploadService.upload(
              bytes: bytes,
              contentType: contentType,
              purpose: MediaPurpose.post,
              onProgress: (frac) {
                if (total > 0) {
                  final base = index / total;
                  final step = 1.0 / total;
                  uploadProgress.value = 0.2 + (base + frac * step) * 0.6;
                }
              },
            );
            resolved.add(media.url);
          } else {
            resolved.add(img);
          }
        } else {
          resolved.add(img);
        }
      }
      index++;
    }
    return resolved;
  }

  Future<bool> addNewPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool allowMultipleAnswers = false,
    EventModel? attachedEvent,
  }) async {
    isUploadingPost.value = true;
    uploadProgress.value = 0.1;

    try {
      final resolvedImageUrls = await _resolveImageUrls(imageUrls);
      uploadProgress.value = 0.8;

      final createdPost = await repository.createPost(
        content: content,
        imageUrls: resolvedImageUrls,
        visibility: visibility,
        community: community,
      );

      final richPost = createdPost.copyWith(
        imageUrls: resolvedImageUrls.isNotEmpty ? resolvedImageUrls : createdPost.imageUrls,
        location: location,
        linkUrl: linkUrl,
        linkPreviewTitle: linkPreviewTitle,
        linkPreviewDomain: linkPreviewDomain,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        pollDuration: pollDuration,
        allowMultipleAnswers: allowMultipleAnswers,
        attachedEvent: attachedEvent,
        postType: attachedEvent != null
            ? 'event'
            : (resolvedImageUrls.isNotEmpty ? 'IMAGE' : createdPost.postType),
      );

      posts.insert(0, richPost);
      uploadProgress.value = 1.0;
      isUploadingPost.value = false;
      return true;
    } catch (e) {
      isUploadingPost.value = false;
      final errorText = e is AppError ? e.message : 'Could not publish post.';
      Get.snackbar(
        "Upload Failed",
        errorText,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    }
  }

  void toggleLike(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      final previousState = p.isLiked;
      final previousCount = p.likesCount;

      p.isLiked = !p.isLiked;
      p.likesCount += p.isLiked ? 1 : -1;
      posts[idx] = p.copyWith();

      repository.toggleLike(postId).catchError((_) {
        final currentIdx = posts.indexWhere((item) => item.id == postId);
        if (currentIdx != -1) {
          final item = posts[currentIdx];
          item.isLiked = previousState;
          item.likesCount = previousCount;
          posts[currentIdx] = item.copyWith();
        }
        return false;
      });
    }
  }

  void toggleBookmark(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      p.isBookmarked = !p.isBookmarked;
      posts[idx] = p.copyWith();
      posts.refresh();
      repository.toggleBookmark(postId);
    }
  }

  CommunityPostModel? _recentlyDeletedPost;
  int _recentlyDeletedIndex = 0;

  void deletePost(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _recentlyDeletedIndex = idx;
      _recentlyDeletedPost = posts[idx];
      posts.removeAt(idx);

      repository.deletePost(postId).catchError((_) {
        if (_recentlyDeletedPost != null) {
          posts.insert(
            _recentlyDeletedIndex.clamp(0, posts.length),
            _recentlyDeletedPost!,
          );
          _recentlyDeletedPost = null;
        }
        return false;
      });
    }
  }

  void undoDeletePost() {
    if (_recentlyDeletedPost != null) {
      final insertIndex = _recentlyDeletedIndex.clamp(0, posts.length);
      posts.insert(insertIndex, _recentlyDeletedPost!);
      _recentlyDeletedPost = null;
    }
  }

  Future<void> editPost(String postId, String newContent) async {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = posts[idx].copyWith(content: newContent);
      await repository.updatePost(postId, content: newContent);
    }
  }

  Future<void> editPostFull({
    required String postId,
    required String content,
    required List<String> imageUrls,
    required String visibility,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    EventModel? attachedEvent,
  }) async {
    final resolvedImageUrls = await _resolveImageUrls(imageUrls);
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = posts[idx].copyWith(
        content: content,
        imageUrls: resolvedImageUrls,
        visibility: visibility,
        location: location,
        linkUrl: linkUrl,
        linkPreviewTitle: linkPreviewTitle,
        linkPreviewDomain: linkPreviewDomain,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        pollDuration: pollDuration,
        allowMultipleAnswers: allowMultipleAnswers,
        attachedEvent: attachedEvent,
        postType: attachedEvent != null ? 'event' : posts[idx].postType,
      );
      await repository.updatePost(postId, content: content);
    }
  }

  Future<bool> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool allowMultipleAnswers = false,
    EventModel? attachedEvent,
  }) => addNewPost(
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    community: community,
    location: location,
    linkUrl: linkUrl,
    linkPreviewTitle: linkPreviewTitle,
    linkPreviewDomain: linkPreviewDomain,
    pollQuestion: pollQuestion,
    pollOptions: pollOptions,
    pollDuration: pollDuration,
    allowMultipleAnswers: allowMultipleAnswers,
    attachedEvent: attachedEvent,
  );

  Future<void> updatePost({
    required String postId,
    required String content,
    required List<String> imageUrls,
    required String visibility,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    EventModel? attachedEvent,
  }) => editPostFull(
    postId: postId,
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    location: location,
    linkUrl: linkUrl,
    linkPreviewTitle: linkPreviewTitle,
    linkPreviewDomain: linkPreviewDomain,
    pollQuestion: pollQuestion,
    pollOptions: pollOptions,
    pollDuration: pollDuration,
    allowMultipleAnswers: allowMultipleAnswers,
    attachedEvent: attachedEvent,
  );

  void repostPost(String postId, {String? caption}) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];

      if (original.checkIsOwner(currentUserId)) {
        return;
      }

      if (original.isRepostedByMe) {
        return;
      }

      final updated = original.copyWith(
        sharesCount: original.sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: currentUserName,
        repostCaption: caption,
        reposterId: currentUserId,
        originalPostId: original.id,
      );
      posts[idx] = updated;

      repository.repostPost(
        postId,
        caption: caption,
        reposterId: currentUserId,
      ).catchError((_) => false);
    }
  }

  void unrepostPost(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];
      if (!original.isRepostedByMe) return;

      final updated = original.copyWith(
        sharesCount: original.sharesCount > 0 ? original.sharesCount - 1 : 0,
        clearRepostInfo: true,
      );
      posts[idx] = updated;

      repository.unrepostPost(
        postId,
        reposterId: currentUserId,
      ).catchError((_) => false);
    }
  }

  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) async {
    try {
      return await repository.reportPost(postId, reason: reason);
    } catch (_) {
      return false;
    }
  }

  List<CommunityPostModel> getUserPosts(String userId, {String? username}) {
    return posts.where((p) {
      if (userId.isNotEmpty && p.userId == userId) {
        return true;
      }
      if (username != null &&
          username.isNotEmpty &&
          p.authorName.trim().toLowerCase() == username.trim().toLowerCase()) {
        return true;
      }
      if (p.reposterId == userId ||
          (p.isRepostedByMe && userId.isNotEmpty && userId == currentUserId) ||
          (p.repostedBy != null &&
              username != null &&
              p.repostedBy!.trim().toLowerCase() == username.trim().toLowerCase())) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> fetchComments(String postId) async {
    isLoadingComments.value = true;
    try {
      final comments = await repository.getComments(postId);
      activeComments.assignAll(comments);
    } catch (_) {
    } finally {
      isLoadingComments.value = false;
    }
  }

  final discussionComments = <String, List<CommentModel>>{}.obs;
  final isLoadingDiscussionComments = false.obs;
  final isSendingDiscussionComment = false.obs;

  List<CommentModel> getCommentsForDiscussion(String discussionId) {
    return discussionComments[discussionId] ?? [];
  }

  Future<void> fetchDiscussionComments(String discussionId) async {
    isLoadingDiscussionComments.value = true;
    try {
      final comments = await repository.getDiscussionComments(discussionId);
      discussionComments[discussionId] = comments;
      discussionComments.refresh();
    } catch (_) {
    } finally {
      isLoadingDiscussionComments.value = false;
    }
  }

  Future<CommentModel?> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || isSendingDiscussionComment.value) return null;

    isSendingDiscussionComment.value = true;
    try {
      final comment = await repository.addDiscussionComment(
        discussionId,
        trimmed,
        parentCommentId: parentCommentId,
      );
      final current = List<CommentModel>.from(
        discussionComments[discussionId] ?? [],
      );
      current.add(comment);
      discussionComments[discussionId] = current;
      discussionComments.refresh();

      final forumIdx =
          forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
      if (forumIdx != -1) {
        final topic = forumLatestDiscussions[forumIdx];
        topic.repliesCount += 1;
        forumLatestDiscussions[forumIdx] = topic.copyWith();
        forumLatestDiscussions.refresh();
      }

      return comment;
    } catch (e) {
      rethrow;
    } finally {
      isSendingDiscussionComment.value = false;
    }
  }

  Future<bool> toggleDiscussionCommentLike(
    String discussionId,
    String commentId,
  ) async {
    if (inFlightCommentLikes.contains(commentId)) return false;
    inFlightCommentLikes.add(commentId);

    final comments = discussionComments[discussionId];
    if (comments == null) {
      inFlightCommentLikes.remove(commentId);
      return false;
    }

    final cIdx = comments.indexWhere((c) => c.id == commentId);
    if (cIdx == -1) {
      inFlightCommentLikes.remove(commentId);
      return false;
    }

    final comment = comments[cIdx];
    final prevLiked = comment.isLiked;
    final prevLikesCount = comment.likesCount;

    comment.isLiked = !prevLiked;
    comment.likesCount += comment.isLiked ? 1 : -1;
    discussionComments.refresh();

    try {
      final success = await repository.toggleDiscussionCommentLike(
        commentId,
        isCurrentlyLiked: prevLiked,
      );
      if (!success) {
        comment.isLiked = prevLiked;
        comment.likesCount = prevLikesCount;
        discussionComments.refresh();
      }
      return success;
    } catch (_) {
      comment.isLiked = prevLiked;
      comment.likesCount = prevLikesCount;
      discussionComments.refresh();
      return false;
    } finally {
      inFlightCommentLikes.remove(commentId);
    }
  }

  Future<CommentModel?> updateDiscussionComment(
    String discussionId,
    String commentId,
    String content,
  ) async {
    try {
      final updatedComment =
          await repository.updateDiscussionComment(commentId, content);
      final current = List<CommentModel>.from(
        discussionComments[discussionId] ?? [],
      );
      final idx = current.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        current[idx] = updatedComment;
        discussionComments[discussionId] = current;
        discussionComments.refresh();
      }
      return updatedComment;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteDiscussionComment(
    String discussionId,
    String commentId,
  ) async {
    try {
      final success = await repository.deleteDiscussionComment(commentId);
      if (success) {
        final current = List<CommentModel>.from(
          discussionComments[discussionId] ?? [],
        );
        current.removeWhere((c) => c.id == commentId);
        discussionComments[discussionId] = current;
        discussionComments.refresh();

        final forumIdx =
            forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
        if (forumIdx != -1) {
          final topic = forumLatestDiscussions[forumIdx];
          if (topic.repliesCount > 0) {
            topic.repliesCount -= 1;
            forumLatestDiscussions[forumIdx] = topic.copyWith();
            forumLatestDiscussions.refresh();
          }
        }
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  }) async {
    try {
      return await repository.reportDiscussion(
        discussionId,
        reason: reason,
        details: details,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final comment = await repository.addComment(postId, text);
      activeComments.add(comment);

      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final p = posts[idx];
        p.commentsCount += 1;
        posts[idx] = p.copyWith();
      }
    } catch (_) {}
  }

  void toggleCommentLike(String postId, String commentId) {
    final idx = activeComments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      final comment = activeComments[idx];
      comment.isLiked = !comment.isLiked;
      comment.likesCount += comment.isLiked ? 1 : -1;
      activeComments[idx] = comment;
      activeComments.refresh();
    }
  }

  void toggleGroupJoin(String groupId) {
    final idx = recommendedGroups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      recommendedGroups[idx].isJoined = !recommendedGroups[idx].isJoined;
      recommendedGroups.refresh();
    }
  }

  bool isOwnUserId(String userId) {
    final currentId = currentUserId;
    if (currentId != null && currentId.isNotEmpty) {
      return currentId == userId;
    }
    return false;
  }

  bool isFollowingUser(String userId) {
    final post = posts.firstWhereOrNull((p) => p.userId == userId);
    if (post != null) return post.isFollowing;
    final suggested = suggestedUsers.firstWhereOrNull((u) => u.id == userId);
    if (suggested != null) return suggested.isFollowing;
    return false;
  }

  void _setFollowStateForUser(String userId, bool isFollowing) {
    bool postUpdated = false;
    for (int i = 0; i < posts.length; i++) {
      if (posts[i].userId == userId) {
        posts[i] = posts[i].copyWith(isFollowing: isFollowing);
        postUpdated = true;
      }
    }
    if (postUpdated) {
      posts.refresh();
    }

    final suggestedIdx = suggestedUsers.indexWhere((u) => u.id == userId);
    if (suggestedIdx != -1) {
      suggestedUsers[suggestedIdx].isFollowing = isFollowing;
      suggestedUsers.refresh();
    }
  }

  Future<void> _syncFollowStates(List<CommunityPostModel> postList) async {
    final uniqueAuthorIds = postList
        .map((p) => p.userId)
        .where((id) => id.isNotEmpty && !isOwnUserId(id))
        .toSet();

    for (final authorId in uniqueAuthorIds) {
      try {
        final isFollowing = await repository.checkIsFollowing(authorId);
        _setFollowStateForUser(authorId, isFollowing);
      } catch (_) {}
    }
  }

  Future<bool> toggleFollowUser(String userId) async {
    if (userId.isEmpty) return false;

    if (isOwnUserId(userId)) {
      return false;
    }

    if (followLoadingUserIds.contains(userId)) {
      return false;
    }

    final currentlyFollowing = isFollowingUser(userId);
    final targetState = !currentlyFollowing;

    followLoadingUserIds.add(userId);

    _setFollowStateForUser(userId, targetState);

    try {
      final success = currentlyFollowing
          ? await repository.unfollowUser(userId)
          : await repository.followUser(userId);

      if (!success) {
        throw AppError(
          message: 'Failed to update follow status',
          errorCode: 'FOLLOW_FAILED',
        );
      }
      return true;
    } catch (e) {
      _setFollowStateForUser(userId, currentlyFollowing);

      final errorMsg = e is AppError ? e.message : 'common.error'.tr;
      Get.snackbar(
        'community.follow'.tr,
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      followLoadingUserIds.remove(userId);
    }
  }

  void toggleUserFollow(String userId) => toggleFollowUser(userId);

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }
}
