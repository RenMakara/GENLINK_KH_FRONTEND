import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends GetxController {
  late CommunityRepository repository;
  final CommunityRepository? _injectedRepository;

  CommunityController({CommunityRepository? repository})
      : _injectedRepository = repository;

  final ScrollController scrollController = ScrollController();

  /// Resolved current user ID from AuthController if available
  String? get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.id;
    }
    return null;
  }

  /// Resolved current user full name from AuthController if available
  String get currentUserName {
    if (Get.isRegistered<AuthController>()) {
      final name = Get.find<AuthController>().currentUser.value?.fullName;
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Sokny Enat';
  }

  final selectedCategory = 'Feed'.obs;
  final selectedForumCategory = 'All'.obs;
  final categories = ['Feed', 'Forum', 'Event'];

  // Feed State & Pagination
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

  // ── Event State ───────────────────────────────────────────────────────────
  /// Local-first reactive event list. Prepend newly created events at index 0.
  final events = <EventModel>[
    EventModel(
      id: 'ev1',
      title: 'Flutter Workshop 2026',
      subtitle: 'Build Cross-platform Apps with Flutter',
      organizerName: 'GenLink Cambodia',
      eventType: 'In person',
      location: 'ACLEDA University, Phnom Penh',
      dateString: '25 Jul 2026',
      timeString: '9:00 AM – 4:00 PM',
      description:
          'Join us for an intensive hands-on workshop where you will learn how to build beautiful and high-performance cross-platform applications using Flutter.\n\nWhether you are a beginner or looking to enhance your skills, this workshop covers clean architecture, state management, and real-world backend API integration.',
      category: 'Workshop',
      imageUrl:
          'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
      attendeesCount: 120,
    ),
    EventModel(
      id: 'ev2',
      title: 'AI in Everyday Life',
      subtitle: 'Explore how AI is changing the world',
      organizerName: 'Institute of Technology',
      eventType: 'Online',
      onlineLink: 'https://meet.google.com/abc-defg-hij',
      dateString: '26 Jul 2026',
      timeString: '2:00 PM – 5:00 PM',
      description:
          'Discover how artificial intelligence is transforming daily life. From smart assistants to recommendation systems, explore the technology behind the future.',
      category: 'Seminar',
      imageUrl:
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
      attendeesCount: 85,
    ),
    EventModel(
      id: 'ev3',
      title: 'GenLink Hackathon 2026',
      subtitle: 'Code. Solve. Impact.',
      organizerName: 'GenLink Cambodia',
      eventType: 'In person',
      location: 'Diamond Island Convention Center',
      dateString: '30 Jul 2026',
      timeString: '8:00 AM – 8:00 PM',
      description:
          '12 hours. Real problems. Real prizes. Join hundreds of Cambodia\'s brightest minds and build solutions that matter.',
      category: 'Hackathon',
      imageUrl:
          'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
      attendeesCount: 230,
    ),
  ].obs;

  /// Prepends a newly created event to the top of [events].
  void createEvent(EventModel event) {
    events.insert(0, event);
  }

  /// Toggles RSVP state for the event with [eventId].
  void toggleRsvp(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final ev = events[idx];
    ev.isRsvped = !ev.isRsvped;
    ev.attendeesCount += ev.isRsvped ? 1 : -1;
    events.refresh();
  }

  /// Refreshes the events list
  Future<void> refreshEvents() async {
    events.refresh();
  }

  // ── Event Filter State ──────────────────────────────────────────────────
  final selectedEventDate = 'All'.obs;
  final selectedEventCategories = <String>{}.obs;
  final selectedEventMode = 'All'.obs; // 'All', 'In person', 'Online'
  final selectedEventPrice = 'All'.obs; // 'All', 'Free', 'Paid'

  /// Whether any non-default filter is currently applied
  bool get isEventFilterActive =>
      (selectedEventDate.value != 'All' && selectedEventDate.value.isNotEmpty) ||
      selectedEventCategories.isNotEmpty ||
      selectedEventMode.value != 'All' ||
      selectedEventPrice.value != 'All';

  /// Returns events filtered by the current filter criteria
  List<EventModel> get filteredEvents {
    return events.where((e) {
      // 1. Category filter
      if (selectedEventCategories.isNotEmpty &&
          !selectedEventCategories.contains(e.category)) {
        return false;
      }
      // 2. Format / Mode filter (In person vs Online)
      if (selectedEventMode.value != 'All') {
        final isOnline = e.eventType.toLowerCase().contains('online');
        if (selectedEventMode.value == 'Online' && !isOnline) {
          return false;
        }
        if (selectedEventMode.value == 'In person' && isOnline) {
          return false;
        }
      }
      // 3. Price filter
      if (selectedEventPrice.value == 'Free' && e.isPaid) {
        return false;
      }
      if (selectedEventPrice.value == 'Paid' && !e.isPaid) {
        return false;
      }
      // 4. Date filter
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

  /// Clears all applied event filters
  void resetEventFilter() {
    selectedEventDate.value = 'All';
    selectedEventCategories.clear();
    selectedEventMode.value = 'All';
    selectedEventPrice.value = 'All';
    events.refresh();
  }

  /// Sets event filter criteria and triggers reactivity
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

  // ── Forum State ───────────────────────────────────────────────────────────
  final forumPinnedDiscussions = <ForumTopicModel>[
    ForumTopicModel(
      id: 'pinned_1',
      title: 'Guidelines for GenLink KH Annual Student Project Showcase 2026',
      authorName: 'Admin Team',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '1d ago',
      category: 'Technology',
      content:
          'Welcome to the 2026 Annual Student Project Showcase! Please review our submission deadlines, presentation criteria, and judging rubric before submitting your entries.',
      repliesCount: 48,
      upvotes: 142,
      isPinned: true,
      isLiked: false,
    ),
    ForumTopicModel(
      id: 'pinned_2',
      title: 'Best practices for GetX state management in Flutter Community App',
      authorName: 'Sokny Enat',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      category: 'Technology',
      content:
          'When structuring large Flutter apps with GetX, prefer domain separation, avoid calling Get.put inside build methods, and use bindings for deterministic lifecycle management.',
      repliesCount: 24,
      upvotes: 89,
      isPinned: true,
      isLiked: false,
    ),
  ].obs;

  final forumLatestDiscussions = <ForumTopicModel>[
    ForumTopicModel(
      id: 'latest_1',
      title: 'How to prepare for junior software engineer interviews in Phnom Penh?',
      authorName: 'Rathana P.',
      authorAvatar: 'assets/images/heng_chansela_profile.png',
      timeAgo: '3h ago',
      category: 'Career',
      content:
          'Preparing for tech interviews at local tech companies and banks? Focus on Data Structures, RESTful APIs, Git workflow, and real portfolio projects.',
      repliesCount: 19,
      upvotes: 45,
      isPinned: false,
      isLiked: false,
    ),
    ForumTopicModel(
      id: 'latest_2',
      title: 'Study group for CADT Data Structures and Algorithms exam next week',
      authorName: 'Heng Chansela',
      authorAvatar: 'assets/images/heng_chansela_profile.png',
      timeAgo: '5h ago',
      category: 'Study & Education',
      content:
          'We are organizing an online and on-campus study session for DSA. Topics include Dynamic Programming, Graph Traversals, and Complexity Analysis.',
      repliesCount: 31,
      upvotes: 67,
      isPinned: false,
      isLiked: false,
    ),
    ForumTopicModel(
      id: 'latest_3',
      title: 'Sharing my AI project built with Python and Flutter Web',
      authorName: 'Ren Makara',
      authorAvatar: 'assets/images/ren_makara_profile.png',
      timeAgo: '7h ago',
      category: 'Projects',
      content:
          'Hey everyone! I just published my open-source project combining Flutter frontend with a FastAPI backend. Check out the demo and repo.',
      repliesCount: 14,
      upvotes: 53,
      isPinned: false,
      isLiked: false,
    ),
    ForumTopicModel(
      id: 'latest_4',
      title: 'Campus Hackathon 2026 registration is officially open!',
      authorName: 'Chhaeng Sokuntheara',
      authorAvatar: 'assets/images/sokuntheara_profile.png',
      timeAgo: '12h ago',
      category: 'Events',
      content:
          'Excited to announce GenLink KH Campus Hackathon 2026! Over 50 teams will compete over 48 hours to solve real community challenges.',
      repliesCount: 42,
      upvotes: 110,
      isPinned: false,
      isLiked: false,
    ),
  ].obs;

  /// Optimistically toggle like on a forum discussion
  void toggleDiscussionLike(String discussionId) {
    final pinIdx = forumPinnedDiscussions.indexWhere((d) => d.id == discussionId);
    if (pinIdx != -1) {
      final item = forumPinnedDiscussions[pinIdx];
      item.isLiked = !item.isLiked;
      item.upvotes += item.isLiked ? 1 : -1;
      forumPinnedDiscussions[pinIdx] = item.copyWith();
      forumPinnedDiscussions.refresh();
      return;
    }

    final latestIdx = forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
    if (latestIdx != -1) {
      final item = forumLatestDiscussions[latestIdx];
      item.isLiked = !item.isLiked;
      item.upvotes += item.isLiked ? 1 : -1;
      forumLatestDiscussions[latestIdx] = item.copyWith();
      forumLatestDiscussions.refresh();
    }
  }

  /// Adds a new discussion to the top of latest discussions
  void addDiscussion({
    required String title,
    required String content,
    required String category,
  }) {
    final newDiscussion = ForumTopicModel(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authorName: currentUserName,
      authorAvatar: 'assets/images/user_profile.png',
      category: category,
      content: content,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
      isLiked: false,
      isPinned: false,
    );
    forumLatestDiscussions.insert(0, newDiscussion);
    forumLatestDiscussions.refresh();
  }

  /// Retrieves discussion topic by id if present
  ForumTopicModel? getDiscussionById(String id) {
    return forumPinnedDiscussions.firstWhereOrNull((d) => d.id == id) ??
        forumLatestDiscussions.firstWhereOrNull((d) => d.id == id);
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

  /// Initial or fresh load of posts
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

  /// Pagination: load next page of posts
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
      // Keep existing posts on pagination error
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Pull-to-refresh handler
  Future<void> refreshFeed() async {
    await fetchPosts(isRefresh: true);
  }

  /// Optimistic post creation: Inserts at TOP of feed immediately
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
    uploadProgress.value = 0.3;

    await Future.delayed(const Duration(milliseconds: 150));
    uploadProgress.value = 0.7;

    try {
      final createdPost = await repository.createPost(
        content: content,
        imageUrls: imageUrls,
        visibility: visibility,
        community: community,
      );

      final richPost = createdPost.copyWith(
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

  /// Optimistic toggle like with network sync
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
        // Revert on error
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

  /// Optimistic toggle bookmark with network sync
  void toggleBookmark(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      p.isBookmarked = !p.isBookmarked;
      posts[idx] = p.copyWith();
      repository.toggleBookmark(postId);
    }
  }

  CommunityPostModel? _recentlyDeletedPost;
  int _recentlyDeletedIndex = 0;

  /// Delete post with optimistic removal & instant undo support
  void deletePost(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _recentlyDeletedIndex = idx;
      _recentlyDeletedPost = posts[idx];
      posts.removeAt(idx);

      repository.deletePost(postId).catchError((_) {
        // Revert on deletion failure
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
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = posts[idx].copyWith(
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

  /// Repost another user's post without creating duplicate copies in feed
  void repostPost(String postId, {String? caption}) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];

      // 1. Current user must NOT repost their own post
      if (original.checkIsOwner(currentUserId)) {
        return;
      }

      // 2. Prevent duplicate reposts of the same original post
      if (original.isRepostedByMe) {
        return;
      }

      // 3. Update the original post in-place as a repost reference
      final updated = original.copyWith(
        sharesCount: original.sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: currentUserName,
        repostCaption: caption,
        reposterId: currentUserId ?? 'user_me',
        originalPostId: original.id,
      );
      posts[idx] = updated;

      repository.repostPost(
        postId,
        caption: caption,
        reposterId: currentUserId ?? 'user_me',
      ).catchError((_) => false);
    }
  }

  /// Remove a repost made by the current user
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
        reposterId: currentUserId ?? 'user_me',
      ).catchError((_) => false);
    }
  }

  /// Report a post for moderation review
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

  /// Returns posts authored by or reposted by the specified user for Profile viewing
  List<CommunityPostModel> getUserPosts(String userId, {String? username}) {
    return posts.where((p) {
      // 1. Authored by user
      if (p.userId == userId ||
          (p.isOwner &&
              (userId == 'user_me' ||
                  userId == 'demo_user_1' ||
                  userId == 'current_user'))) {
        return true;
      }
      // 2. Reposted by user
      if (p.reposterId == userId ||
          (p.isRepostedByMe &&
              (userId == 'user_me' ||
                  userId == 'demo_user_1' ||
                  userId == 'current_user')) ||
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
    String content,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || isSendingDiscussionComment.value) return null;

    isSendingDiscussionComment.value = true;
    try {
      final comment = await repository.addDiscussionComment(
        discussionId,
        trimmed,
      );
      final current = List<CommentModel>.from(
        discussionComments[discussionId] ?? [],
      );
      current.add(comment);
      discussionComments[discussionId] = current;
      discussionComments.refresh();
      return comment;
    } catch (e) {
      rethrow;
    } finally {
      isSendingDiscussionComment.value = false;
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
    if (currentId != null && currentId.isNotEmpty && currentId == userId) {
      return true;
    }
    if (userId == 'user_me' || userId == 'current_user' || userId == 'demo_user_1') {
      return true;
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
      if (posts[i].userId == userId && posts[i].isFollowing != isFollowing) {
        posts[i] = posts[i].copyWith(isFollowing: isFollowing);
        postUpdated = true;
      }
    }
    if (postUpdated) {
      posts.refresh();
    }

    final suggestedIdx = suggestedUsers.indexWhere((u) => u.id == userId);
    if (suggestedIdx != -1 && suggestedUsers[suggestedIdx].isFollowing != isFollowing) {
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

    // Current user should never be able to follow themselves
    if (isOwnUserId(userId)) {
      return false;
    }

    // Prevent rapid duplicate requests
    if (followLoadingUserIds.contains(userId)) {
      return false;
    }

    final currentlyFollowing = isFollowingUser(userId);
    final targetState = !currentlyFollowing;

    followLoadingUserIds.add(userId);

    // Optimistic UI state update
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
      // Revert state on failure
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
