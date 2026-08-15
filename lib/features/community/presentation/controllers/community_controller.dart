import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends GetxController {
  late final CommunityRepository repository;

  final ScrollController scrollController = ScrollController();

  final selectedCategory = 'Feed'.obs;
  final categories = ['Feed', 'Forum', 'Career', 'Event'];

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

  final stories = <StoryModel>[
    StoryModel(
      id: '1',
      name: 'Your Story',
      avatarText: 'S',
      isUser: true,
      hasActiveStory: false,
    ),
    StoryModel(
      id: 'sambo',
      name: 'Sum Sambo',
      avatarText: 'S',
      hasActiveStory: true,
      storyImage: 'https://i.pinimg.com/736x/ec/31/fb/ec31fb6bb86683cf4d2d1680f79f14cb.jpg',
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
      id: 'u_sambo',
      name: 'Sum Sambo',
      role: 'Cybersecurity Student',
      avatarUrl: 'https://i.pinimg.com/736x/ec/31/fb/ec31fb6bb86683cf4d2d1680f79f14cb.jpg',
    ),
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

  @override
  void onInit() {
    super.onInit();
    final dio =
        Get.isRegistered<Dio>() ? Get.find<Dio>() : DioProvider.create();
    final dataSource = CommunityRemoteDataSource(dio: dio);
    repository = CommunityRepositoryImpl(remoteDataSource: dataSource);

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
        posts.addAll(fetched);
        currentPage.value = nextPage;
        hasMorePosts.value = fetched.length >= 10;
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

      repository.toggleLike(postId, isCurrentlyLiked: previousState).catchError((_) {
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
          posts.insert(_recentlyDeletedIndex.clamp(0, posts.length), _recentlyDeletedPost!);
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
  }) =>
      addNewPost(
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
  }) =>
      editPostFull(
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
      );

  void repostPost(String postId, {String? caption}) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];
      original.sharesCount++;
      posts[idx] = original.copyWith();

      final repostPost = CommunityPostModel(
        id: 'repost_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_1',
        authorName: original.authorName,
        authorTag: original.authorTag,
        authorAvatar: original.authorAvatar,
        isVerified: original.isVerified,
        timeAgo: 'Just now',
        content: original.content,
        imageUrls: List.from(original.imageUrls),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        isOwner: true,
        repostedBy: 'Sokny Enat',
        repostCaption: caption,
        visibility: original.visibility,
        community: original.community,
      );
      posts.insert(0, repostPost);
    }
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

  void toggleUserFollow(String userId) {
    final idx = suggestedUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      suggestedUsers[idx].isFollowing = !suggestedUsers[idx].isFollowing;
      suggestedUsers.refresh();
    }
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void toggleFollowUser(String userId) => toggleUserFollow(userId);
}
