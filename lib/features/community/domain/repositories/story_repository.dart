import '../models/story_model.dart';

abstract class StoryRepository {
  Future<List<StoryGroupModel>> getStories();
  Future<StoryItemModel> createStory({
    required StoryType type,
    String? mediaUrl,
    String? textContent,
    String? location,
    String visibility = 'Public',
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
  });
  Future<void> deleteStory(String storyId);
  Future<void> toggleLikeStory(String storyId);
  Future<void> replyToStory(String storyId, String message);
  Future<List<StoryViewerModel>> getStoryViewers(String storyId);
}
