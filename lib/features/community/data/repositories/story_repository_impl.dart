import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final ApiClient _apiClient;

  StoryRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? Get.find<ApiClient>();

  @override
  Future<List<StoryGroupModel>> getStories() async {
    return _apiClient.get(
      ApiEndpoints.stories,
      parse: (data) => ApiClient.asList(data, (json) {
        final author = json['author'] is Map<String, dynamic>
            ? json['author'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final stories = json['stories'] as List? ?? const [];
        return StoryGroupModel(
          userId: author['userId']?.toString() ?? '',
          userName: (author['fullName'] as String?) ??
              (author['username'] as String?) ??
              'User',
          userAvatar: author['avatarUrl'] as String? ??
              'assets/images/user_profile.png',
          isOwner: false,
          hasUnseen: json['hasUnseen'] as bool? ?? false,
          stories: stories
              .map((s) => _storyFromJson((s as Map).cast<String, dynamic>()))
              .toList(),
        );
      }),
    );
  }

  @override
  Future<StoryItemModel> createStory({
    required StoryType type,
    String? mediaUrl,
    String? textContent,
    String? location,
    String visibility = 'Public',
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
    double bgScale = 1.0,
    dynamic bgOffset,
    double bgRotation = 0.0,
  }) async {
    return _apiClient.post(
      ApiEndpoints.stories,
      body: {
        'mediaUrl': mediaUrl ?? '',
        'mediaType': type == StoryType.video ? 'VIDEO' : 'IMAGE',
        'caption': textContent,
      },
      parse: (data) => _storyFromJson(ApiClient.asMap(data)),
    );
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _apiClient.delete(ApiEndpoints.storyItem(storyId));
  }

  @override
  Future<void> markViewed(String storyId) async {
    await _apiClient.post(
      ApiEndpoints.storyView(storyId),
      parse: (_) {},
    );
  }

  @override
  Future<List<StoryViewerModel>> getStoryViewers(String storyId) async {
    return _apiClient.get(
      ApiEndpoints.storyViewers(storyId),
      parse: (data) => ApiClient.asList(data, (json) {
        return StoryViewerModel(
          id: json['userId']?.toString() ?? '',
          userName: (json['fullName'] as String?) ??
              (json['username'] as String?) ??
              'User',
          userAvatar: json['avatarUrl'] as String? ??
              'assets/images/user_profile.png',
          viewedTimeAgo: _timeAgo(
              DateTime.tryParse(json['viewedAt']?.toString() ?? '')),
        );
      }),
    );
  }

  @override
  Future<void> toggleLikeStory(String storyId) async {}

  @override
  Future<void> replyToStory(String storyId, String message) async {}

  StoryItemModel _storyFromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final mediaType = (json['mediaType'] as String?) ?? 'IMAGE';
    return StoryItemModel(
      id: json['storyId']?.toString() ?? '',
      type: mediaType == 'VIDEO' ? StoryType.video : StoryType.photo,
      mediaUrl: json['mediaUrl'] as String?,
      textContent: json['caption'] as String?,
      timeAgo: _timeAgo(createdAt),
      createdAt: createdAt,
      visibility: 'Public',
    );
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}