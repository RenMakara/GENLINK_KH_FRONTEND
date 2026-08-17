import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';
import '../../data/repositories/story_repository_impl.dart';

class StoryController extends GetxController {
  final StoryRepository _repository = StoryRepositoryImpl();

  final RxList<StoryGroupModel> storyGroups = <StoryGroupModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStories();
  }

  Future<void> fetchStories() async {
    isLoading.value = true;
    try {
      final data = await _repository.getStories();
      storyGroups.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> publishStory({
    required StoryType type,
    String? mediaUrl,
    String? textContent,
    String? location,
    String visibility = 'Friends',
    String replyPrivacy = 'Everyone',
    bool allowReactions = true,
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
    double bgScale = 1.0,
    dynamic bgOffset,
    double bgRotation = 0.0,
  }) async {
    if (isUploading.value) return false;
    isUploading.value = true;
    try {
      final newStory = await _repository.createStory(
        type: type,
        mediaUrl: mediaUrl,
        textContent: textContent,
        location: location,
        visibility: visibility,
        replyPrivacy: replyPrivacy,
        allowReactions: allowReactions,
        bgGradientStart: bgGradientStart,
        bgGradientEnd: bgGradientEnd,
        layers: layers,
        bgScale: bgScale,
        bgOffset: bgOffset,
        bgRotation: bgRotation,
      );

      // Update owner story group in reactive tray list (preventing duplicates)
      final ownerGroupIdx = storyGroups.indexWhere((g) => g.isOwner);
      if (ownerGroupIdx != -1) {
        final group = storyGroups[ownerGroupIdx];
        if (!group.stories.any((s) => s.id == newStory.id)) {
          group.stories.insert(0, newStory);
        }
        storyGroups[ownerGroupIdx] = StoryGroupModel(
          userId: group.userId,
          userName: group.userName,
          userAvatar: group.userAvatar,
          isOwner: true,
          hasUnseen: false,
          stories: List.from(group.stories),
        );
      } else {
        storyGroups.insert(
          0,
          StoryGroupModel(
            userId: 'user_me',
            userName: 'Sokny Enat',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: true,
            hasUnseen: false,
            stories: [newStory],
          ),
        );
      }
      storyGroups.refresh();

      try {
        final bannerContext = Get.context ?? Get.overlayContext;
        if (bannerContext != null) {
          AppNotificationBanner.showSuccess(
            context: bannerContext,
            title: "✓ Story Live",
            message: "Your story has been shared with $visibility on CampusLink KH!",
            icon: Icons.auto_awesome_rounded,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (bannerErr) {
        debugPrint('[StoryController] Banner notification skipped: $bannerErr');
      }

      return true;
    } finally {
      isUploading.value = false;
    }
  }

  void markStoryAsViewed(String storyId) {
    bool modified = false;
    for (final group in storyGroups) {
      for (final story in group.stories) {
        if (story.id == storyId && !story.isViewed) {
          story.isViewed = true;
          modified = true;
        }
      }
    }
    if (modified) {
      storyGroups.refresh();
    }
  }

  void toggleLike(String storyId) {
    for (final group in storyGroups) {
      for (final story in group.stories) {
        if (story.id == storyId) {
          story.isLiked = !story.isLiked;
          story.likesCount += story.isLiked ? 1 : -1;
          storyGroups.refresh();
          _repository.toggleLikeStory(storyId);
          return;
        }
      }
    }
  }

  /// Sends the like/unlike API call without toggling local state.
  /// Used by StoryViewerScreen which already toggles the local story
  /// object directly (same reference as storyGroups entries).
  void syncLikeToBackend(String storyId) {
    _repository.toggleLikeStory(storyId);
    storyGroups.refresh();
  }

  void deleteStory(String storyId) {
    for (final group in storyGroups) {
      group.stories.removeWhere((s) => s.id == storyId);
    }
    storyGroups.removeWhere((group) => group.stories.isEmpty && !group.isOwner);
    storyGroups.refresh();
    _repository.deleteStory(storyId);
  }
}
