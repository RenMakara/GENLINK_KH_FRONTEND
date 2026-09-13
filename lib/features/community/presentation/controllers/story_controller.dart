import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    if (!Get.testMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchStories();
      });
    }
  }

  Future<void> fetchStories({bool force = false}) async {
    if (_isFetching && !force) return;
    if (isClosed) return;
    _isFetching = true;
    if (!isLoading.value && storyGroups.isEmpty) {
      isLoading.value = true;
    }
    try {
      final data = await _repository.getStories();
      if (isClosed) return;
      _applyStoryGroups(data);
    } catch (e) {
      debugPrint('[StoryController] fetchStories error: $e');
      if (storyGroups.isEmpty && !isClosed) {
        _applyFallbackOwnerGroup();
      }
    } finally {
      _isFetching = false;
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _applyStoryGroups(List<StoryGroupModel> data) {
    if (isClosed) return;
    final currentUserId = CurrentUser.id;
    final currentUserAvatar = CurrentUser.avatarUrl;
    final currentUserName = CurrentUser.name;

    final sanitizedGroups = <StoryGroupModel>[];
    for (final group in data) {
      final activeStories = group.stories.where((s) => !s.isExpired).toList();
      final isOwner = group.isOwner ||
          (currentUserId.isNotEmpty && group.userId == currentUserId);
      if (isOwner || activeStories.isNotEmpty) {
        sanitizedGroups.add(
          StoryGroupModel(
            userId: group.userId,
            userName: group.userName,
            userAvatar: (isOwner && currentUserAvatar != null && currentUserAvatar.isNotEmpty)
                ? currentUserAvatar
                : group.userAvatar,
            isOwner: isOwner,
            hasUnseen: activeStories.any((s) => !s.isViewed),
            stories: activeStories,
          ),
        );
      }
    }

    final hasOwner = sanitizedGroups.any((g) => g.isOwner);
    if (!hasOwner) {
      sanitizedGroups.insert(
        0,
        StoryGroupModel(
          userId: currentUserId.isNotEmpty ? currentUserId : 'current_user',
          userName: currentUserName.isNotEmpty && currentUserName != 'Guest'
              ? currentUserName
              : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'community.yourStory'.tr),
          userAvatar: currentUserAvatar ?? '',
          isOwner: true,
          hasUnseen: false,
          stories: [],
        ),
      );
    }

    storyGroups.assignAll(sanitizedGroups);
  }

  void _applyFallbackOwnerGroup() {
    if (isClosed) return;
    final currentUserId = CurrentUser.id;
    final currentUserAvatar = CurrentUser.avatarUrl;
    final currentUserName = CurrentUser.name;
    storyGroups.assignAll([
      StoryGroupModel(
        userId: currentUserId.isNotEmpty ? currentUserId : 'current_user',
        userName: currentUserName.isNotEmpty && currentUserName != 'Guest'
            ? currentUserName
            : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'community.yourStory'.tr),
        userAvatar: currentUserAvatar ?? '',
        isOwner: true,
        hasUnseen: false,
        stories: [],
      ),
    ]);
  }

  void purgeExpiredStories() {
    if (isClosed) return;
    bool modified = false;
    final currentGroups = List<StoryGroupModel>.from(storyGroups);
    final updatedGroups = <StoryGroupModel>[];

    for (final group in currentGroups) {
      final unexpired = group.stories.where((s) => !s.isExpired).toList();
      if (unexpired.length != group.stories.length) {
        modified = true;
      }
      if (group.isOwner || unexpired.isNotEmpty) {
        updatedGroups.add(
          StoryGroupModel(
            userId: group.userId,
            userName: group.userName,
            userAvatar: group.userAvatar,
            isOwner: group.isOwner,
            hasUnseen: unexpired.any((s) => !s.isViewed),
            stories: unexpired,
          ),
        );
      } else {
        modified = true;
      }
    }

    if (modified && !isClosed) {
      storyGroups.assignAll(updatedGroups);
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

      if (isClosed) return true;
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
          userAvatar: (CurrentUser.avatarUrl?.isNotEmpty == true)
              ? CurrentUser.avatarUrl!
              : group.userAvatar,
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
      if (!isClosed) {
        _safeRefreshGroups();
      }
      return true;
    } finally {
      if (!isClosed) {
        isUploading.value = false;
      }
    }
  }

  void _safeRefreshGroups() {
    if (isClosed) return;
    try {
      final binding = WidgetsBinding.instance;
      if (binding.buildOwner?.debugBuilding == true ||
          binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        binding.addPostFrameCallback((_) {
          if (!isClosed) {
            storyGroups.refresh();
          }
        });
        return;
      }
    } catch (_) {}
    storyGroups.refresh();
  }

  void markStoryAsViewed(String storyId) {
    if (isClosed) return;
    bool modified = false;
    for (final group in storyGroups) {
      for (final story in group.stories) {
        if (story.id == storyId && !story.isViewed) {
          story.isViewed = true;
          modified = true;
        }
      }
    }
    if (modified && !isClosed) {
      _safeRefreshGroups();
    }
  }

  Future<void> toggleLike(String storyId) async {
    if (isClosed) return;
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
          if (!isClosed) {
            _safeRefreshGroups();
          }
          try {
            await _repository.toggleLikeStory(storyId);
          } catch (e) {
            story.isLiked = previousLiked;
            story.likesCount = previousCount;
            if (!isClosed) {
              _safeRefreshGroups();
            }
            rethrow;
          }
          return;
        }
      }
    }
    await _repository.toggleLikeStory(storyId);
  }

  Future<void> syncLikeToBackend(String storyId) async {
    if (isClosed) return;
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
    if (foundInGroups && !isClosed) {
      _safeRefreshGroups();
    }
  }

  Future<bool> updateStory(String storyId, StoryItemModel updatedStory) async {
    if (isClosed) return false;
    if (isUploading.value) return false;
    isUploading.value = true;
    try {
      await _repository.updateStory(storyId, updatedStory);
      if (isClosed) return true;

      final ownerGroupIdx = storyGroups.indexWhere((g) => g.isOwner);
      if (ownerGroupIdx != -1) {
        final ownerGroup = storyGroups[ownerGroupIdx];
        final index = ownerGroup.stories.indexWhere((s) => s.id == storyId);
        if (index != -1) {
          ownerGroup.stories[index] = updatedStory;
          _safeRefreshGroups();
        }
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      if (!isClosed) {
        isUploading.value = false;
      }
    }
  }

  void updateStoryPrivacy(String storyId, String newPrivacy) {
    if (isClosed) return;
    final ownerGroupIdx = storyGroups.indexWhere((g) => g.isOwner);
    if (ownerGroupIdx == -1) return;
    final ownerGroup = storyGroups[ownerGroupIdx];
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
      if (!isClosed) {
        _safeRefreshGroups();
      }
      _repository.updateStory(storyId, updatedStory);
    }
  }

  Future<bool> deleteStory(String storyId) async {
    if (isClosed) return false;
    try {
      await _repository.deleteStory(storyId);
      if (isClosed) return true;
      for (final group in storyGroups) {
        group.stories.removeWhere((s) => s.id == storyId);
      }
      storyGroups.removeWhere((group) => group.stories.isEmpty && !group.isOwner);
      if (!isClosed) {
        _safeRefreshGroups();
      }
      return true;
    } catch (e) {
      debugPrint('[StoryController] Delete story error: $e');
      return false;
    }
  }

  Future<void> markStoryViewed(String storyId) async {
    if (isClosed) return;
    try {
      await _repository.markViewed(storyId);
    } catch (e) {
      debugPrint('[StoryController] markStoryViewed error: $e');
    }
  }

  void updateStoryViewers(String storyId, List<StoryViewerModel> viewers) {
    if (isClosed) return;
    bool modified = false;
    for (final group in storyGroups) {
      for (final story in group.stories) {
        if (story.id == storyId) {
          story.viewers = List.from(viewers);
          story.viewersCount = viewers.length;
          modified = true;
        }
      }
    }
    if (modified && !isClosed) {
      _safeRefreshGroups();
    }
  }

  Future<List<StoryViewerModel>> fetchStoryViewers(String storyId) async {
    if (isClosed) return [];
    try {
      final viewers = await _repository.getStoryViewers(storyId);
      updateStoryViewers(storyId, viewers);
      return viewers;
    } catch (e) {
      debugPrint('[StoryController] fetchStoryViewers error: $e');
      return [];
    }
  }
}
