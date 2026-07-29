import 'package:get/get.dart';
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
    String visibility = 'Public',
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
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
        bgGradientStart: bgGradientStart,
        bgGradientEnd: bgGradientEnd,
        layers: layers,
      );

      // Optimistically update owner story group in reactive tray list
      final ownerGroupIdx = storyGroups.indexWhere((g) => g.isOwner);
      if (ownerGroupIdx != -1) {
        final group = storyGroups[ownerGroupIdx];
        group.stories.insert(0, newStory);
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
      return true;
    } finally {
      isUploading.value = false;
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

  void deleteStory(String storyId) {
    for (final group in storyGroups) {
      group.stories.removeWhere((s) => s.id == storyId);
    }
    storyGroups.removeWhere((group) => group.stories.isEmpty && !group.isOwner);
    storyGroups.refresh();
    _repository.deleteStory(storyId);
  }
}
