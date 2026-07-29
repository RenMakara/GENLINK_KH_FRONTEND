import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends GetxController {
  late final CommunityRepository repository;

  final ScrollController scrollController = ScrollController();

  final selectedCategory = 'Feed'.obs;
  final categories = ['Feed', 'Forum', 'Career', 'Event'];

  final isLoadingFeed = false.obs;
  final isUploadingPost = false.obs;
  final uploadProgress = 0.0.obs;

  final posts = <CommunityPostModel>[].obs;
  final activeComments = <CommentModel>[].obs;
  final isLoadingComments = false.obs;

  final stories = <StoryModel>[
    StoryModel(id: '1', name: 'Your Story', avatarText: 'S', isUser: true, hasActiveStory: false),
    StoryModel(id: '2', name: 'Dary', avatarText: 'D', hasActiveStory: true),
    StoryModel(id: '3', name: 'AIS Tech Club', avatarText: 'AIS', hasActiveStory: true),
    StoryModel(id: '4', name: 'MayMay', avatarText: 'M', hasActiveStory: true),
  ].obs;

  final recommendedGroups = <RecommendedGroupModel>[
    RecommendedGroupModel(id: 'g1', name: 'IT Club Cambodia', memberCount: '1.2k Members', iconText: 'IT'),
    RecommendedGroupModel(id: 'g2', name: 'UI/UX Design KH', memberCount: '850 Members', iconText: 'UX'),
  ].obs;

  final suggestedUsers = <SuggestedUserModel>[
    SuggestedUserModel(
      id: 'u1',
      name: 'Rathana P.',
      role: 'Mobile Dev at CADT',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    SuggestedUserModel(
      id: 'u2',
      name: 'Sothea N.',
      role: 'Product Designer',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.genlink.kh/api/v1'));
    final dataSource = CommunityRemoteDataSource(dio: dio);
    repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
    fetchPosts();
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
  }

  Future<void> fetchPosts() async {
    isLoadingFeed.value = true;
    try {
      final fetched = await repository.getPosts(page: 1, limit: 10);
      posts.assignAll(fetched);
    } catch (_) {
    } finally {
      isLoadingFeed.value = false;
    }
  }

  Future<void> refreshFeed() async {
    await fetchPosts();
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
    uploadProgress.value = 0.2;

    await Future.delayed(const Duration(milliseconds: 200));
    uploadProgress.value = 0.6;
    await Future.delayed(const Duration(milliseconds: 200));
    uploadProgress.value = 1.0;

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
      isUploadingPost.value = false;
      return true;
    } catch (e) {
      isUploadingPost.value = false;
      Get.snackbar(
        "Upload Failed",
        "Could not publish post. Please check your internet connection.",
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  void toggleLike(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      p.isLiked = !p.isLiked;
      p.likesCount += p.isLiked ? 1 : -1;
      posts[idx] = p.copyWith();
      repository.toggleLike(postId);
    }
  }

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

  void deletePost(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _recentlyDeletedIndex = idx;
      _recentlyDeletedPost = posts[idx];
      posts.removeAt(idx);
      repository.deletePost(postId);
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
        repostedBy: 'Enat Sokny',
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
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;
    final comment = await repository.addComment(postId, text);
    activeComments.add(comment);

    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      p.commentsCount += 1;
      posts[idx] = p.copyWith();
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
