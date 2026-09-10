import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';
import '../../data/repositories/story_repository_impl.dart';

class StoryController extends GetxController {
  final StoryRepository _repository;

  StoryController({StoryRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<StoryRepository>()
                ? Get.find<StoryRepository>()
                : StoryRepositoryImpl());

  final RxList<StoryGroupModel> storyGroups = <StoryGroupModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.testMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchStories();
      });
    }
  }

  Future<void> fetchStories() async {
    if (!isLoading.value) {
      isLoading.value = true;
    }
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
    StorySettings? storySettings,
    String visibility = 'Friends',
    String replyPrivacy = 'Everyone',
    bool allowReactions = true,
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
    double bgScale = 1.0,
    dynamic bgOffset,
    double bgRotation = 0.0,
    String? templateId,
    List<StoryTemplateSlot>? templateSlots,
  }) async {
    if (isUploading.value) return false;
    isUploading.value = true;
    try {
      final effectiveSettings =
          storySettings ??
          StorySettings(
            visibility: StoryPrivacy.fromString(visibility),
            replyPermission: StoryReplyPermission.fromString(replyPrivacy),
            allowReactions: allowReactions,
          );

      final newStory = await _repository.createStory(
        type: type,
        mediaUrl: mediaUrl,
        textContent: textContent,
        location: location,
        settings: effectiveSettings,
        visibility: effectiveSettings.visibilityLabel,
        replyPrivacy: effectiveSettings.replyPermissionLabel,
        allowReactions: effectiveSettings.allowReactions,
        bgGradientStart: bgGradientStart,
        bgGradientEnd: bgGradientEnd,
        layers: layers,
        bgScale: bgScale,
        bgOffset: bgOffset,
        bgRotation: bgRotation,
        templateId: templateId,
        templateSlots: templateSlots,
      );

      final ownerGroupIdx = storyGroups.indexWhere((g) =>
          g.isOwner || (CurrentUser.id.isNotEmpty && g.userId == CurrentUser.id));
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
            userId: CurrentUser.id.isNotEmpty ? CurrentUser.id : 'current_user',
            userName: CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
                ? CurrentUser.name
                : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'You'),
            userAvatar: CurrentUser.avatarUrl?.isNotEmpty == true
                ? CurrentUser.avatarUrl!
                : '',
            isOwner: true,
            hasUnseen: false,
            stories: [newStory],
          ),
        );
      }
      storyGroups.refresh();
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

  Future<void> toggleLike(String storyId) async {
    for (final group in storyGroups) {
      final isOwn = group.isOwner ||
          (CurrentUser.id.isNotEmpty && group.userId == CurrentUser.id);
      for (final story in group.stories) {
        if (story.id == storyId) {
          if (isOwn) return;
          final previousLiked = story.isLiked;
          final previousCount = story.likesCount;
          story.isLiked = !story.isLiked;
          story.likesCount += story.isLiked ? 1 : -1;
          storyGroups.refresh();
          try {
            await _repository.toggleLikeStory(storyId);
          } catch (e) {
            story.isLiked = previousLiked;
            story.likesCount = previousCount;
            storyGroups.refresh();
            rethrow;
          }
          return;
        }
      }
    }
    await _repository.toggleLikeStory(storyId);
  }

  Future<void> syncLikeToBackend(String storyId) async {
    bool foundInGroups = false;
    for (final group in storyGroups) {
      final isOwn = group.isOwner ||
          (CurrentUser.id.isNotEmpty && group.userId == CurrentUser.id);
      for (final story in group.stories) {
        if (story.id == storyId) {
          if (isOwn) return;
          foundInGroups = true;
          break;
        }
      }
    }
    await _repository.toggleLikeStory(storyId);
    if (foundInGroups) {
      storyGroups.refresh();
    }
  }

  Future<bool> updateStory(String storyId, StoryItemModel updatedStory) async {
    if (isUploading.value) return false;
    isUploading.value = true;
    try {
      await _repository.updateStory(storyId, updatedStory);

      final ownerGroup = storyGroups.firstWhere((g) => g.isOwner);
      final index = ownerGroup.stories.indexWhere((s) => s.id == storyId);
      if (index != -1) {
        ownerGroup.stories[index] = updatedStory;
        storyGroups.refresh();
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  void updateStoryPrivacy(String storyId, String newPrivacy) {
    final ownerGroup = storyGroups.firstWhere((g) => g.isOwner);
    final index = ownerGroup.stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final oldStory = ownerGroup.stories[index];
      final newSettings = StorySettings(
        visibility: newPrivacy == 'Public' ? StoryPrivacy.public : (newPrivacy == 'Only Me' ? StoryPrivacy.onlyMe : StoryPrivacy.friends),
        replyPermission: oldStory.settings.replyPermission,
        allowReactions: oldStory.settings.allowReactions,
      );
      final updatedStory = StoryItemModel(
        id: oldStory.id,
        type: oldStory.type,
        mediaUrl: oldStory.mediaUrl,
        textContent: oldStory.textContent,
        bgGradientStart: oldStory.bgGradientStart,
        bgGradientEnd: oldStory.bgGradientEnd,
        location: oldStory.location,
        timeAgo: oldStory.timeAgo,
        createdAt: oldStory.createdAt,
        settings: newSettings,
        layers: List.from(oldStory.layers),
        bgScale: oldStory.bgScale,
        bgOffset: oldStory.bgOffset,
        bgRotation: oldStory.bgRotation,
        viewers: List.from(oldStory.viewers),
        templateId: oldStory.templateId,
        templateSlots: List.from(oldStory.templateSlots),
      );
      updatedStory.likesCount = oldStory.likesCount;
      updatedStory.isLiked = oldStory.isLiked;
      updatedStory.isViewed = oldStory.isViewed;
      updatedStory.viewersCount = oldStory.viewersCount;

      ownerGroup.stories[index] = updatedStory;
      storyGroups.refresh();
      _repository.updateStory(storyId, updatedStory);
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      await _repository.deleteStory(storyId);
      for (final group in storyGroups) {
        group.stories.removeWhere((s) => s.id == storyId);
      }
      storyGroups.removeWhere((group) => group.stories.isEmpty && !group.isOwner);
      storyGroups.refresh();
      return true;
    } catch (e) {
      debugPrint('[StoryController] Delete story error: $e');
      return false;
    }
  }

  Future<void> markStoryViewed(String storyId) async {
    try {
      await _repository.markViewed(storyId);
    } catch (_) {}
  }
}
