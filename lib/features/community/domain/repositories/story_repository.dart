import '../models/story_model.dart';

abstract class StoryRepository {
  Future<List<StoryGroupModel>> getStories();
  Future<StoryItemModel> createStory({
    required StoryType type,
    String? mediaUrl,
    String? textContent,
    String? location,
    StorySettings? settings,
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
  });
  Future<StoryItemModel?> getStoryById(String storyId);
  Future<void> updateStory(String storyId, StoryItemModel updatedStory);
  Future<void> deleteStory(String storyId);
  Future<void> likeStory(String storyId);
  Future<void> unlikeStory(String storyId);
  Future<void> replyToStory(String storyId, String message);
  Future<void> markViewed(String storyId);
  Future<List<StoryViewerModel>> getStoryViewers(String storyId);
  Future<List<StoryMentionUser>> searchMentionUsers({
    String query = '',
  }) async => const [];
}
