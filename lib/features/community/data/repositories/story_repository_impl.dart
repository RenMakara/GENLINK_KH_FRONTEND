import 'package:flutter/material.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final List<StoryGroupModel> _mockStoryGroups = [
    StoryGroupModel(
      userId: 'user_me',
      userName: 'Sokny Enat',
      userAvatar: 'assets/images/user_profile.png',
      isOwner: true,
      hasUnseen: false,
      stories: [],
    ),
    StoryGroupModel(
      userId: 'user_chansela',
      userName: 'Heng Chansela',
      userAvatar: 'assets/images/heng_chansela_profile.png',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_chansela_1',
          type: StoryType.photo,
          mediaUrl: 'assets/images/heng_chansela_post.png',
          textContent: '❤️ Coffee after class.',
          location: 'ACLEDA University of Business',
          timeAgo: '2h ago',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likesCount: 42,
        ),
      ],
    ),
    StoryGroupModel(
      userId: 'user_amnot',
      userName: 'អំណត់',
      userAvatar: 'assets/images/amnot_profile.jpg',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_chansela_km_1',
          type: StoryType.photo,
          mediaUrl: 'assets/images/heng_chansela_km_post.jpg',
          textContent: '⚡ Flutter Community Cambodia',
          location: 'ACLEDA University of Business',
          timeAgo: '1h ago',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likesCount: 88,
        ),
      ],
    ),
    StoryGroupModel(
      userId: 'user_meimei',
      userName: 'មហាពង្សសួស្តី សិរីឥន្រ្ទះទេវីនារីស្មោះស្នេហ៌ហៅកាត់មុីមុី',
      userAvatar: 'assets/images/meimei_profile.png',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_meimei_1',
          type: StoryType.photo,
          mediaUrl: 'assets/images/meimei_profile.png',
          textContent: '🌸 Hello GenLink KH Community!',
          location: 'Phnom Penh, Cambodia',
          timeAgo: '30m ago',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          likesCount: 99,
        ),
      ],
    ),
    StoryGroupModel(
      userId: 'user_makara',
      userName: 'Ren Makara',
      userAvatar: 'assets/images/ren_makara_profile.png',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_makara_1',
          type: StoryType.photo,
          mediaUrl: 'assets/images/authgate_project.png',
          textContent: '🚀 AuthGate Microservices System!',
          location: 'ACLEDA University of Business',
          timeAgo: '5h ago',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          likesCount: 65,
        ),
      ],
    ),
    StoryGroupModel(
      userId: 'user_sokuntheara',
      userName: 'Chhaeng Sokuntheara',
      userAvatar: 'assets/images/sokuntheara_profile.png',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_sokuntheara_1',
          type: StoryType.photo,
          mediaUrl: 'assets/images/sokuntheara_post.png',
          textContent: '🎨 Designing something exciting today!',
          location: 'ACLEDA University of Business',
          timeAgo: '1h ago',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likesCount: 54,
        ),
      ],
    ),
    StoryGroupModel(
      userId: 'user_sambo',
      userName: 'Sum Sambo',
      userAvatar: 'assets/images/sum_sambo_profile.png',
      hasUnseen: true,
      stories: [
        StoryItemModel(
          id: 'story_sambo_1',
          type: StoryType.photo,
          mediaUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
          textContent: '🛡️ Learning something new about cybersecurity today.',
          location: 'ACLEDA University of Business',
          timeAgo: '3h ago',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          likesCount: 61,
        ),
      ],
    ),
  ];

  @override
  Future<List<StoryGroupModel>> getStories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockStoryGroups;
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
    await Future.delayed(const Duration(milliseconds: 400));
    final newStory = StoryItemModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      mediaUrl: mediaUrl,
      textContent: textContent,
      location: location,
      visibility: visibility,
      bgGradientStart: bgGradientStart ?? '0xFF0F172A',
      bgGradientEnd: bgGradientEnd ?? '0xFF1E293B',
      layers: layers ?? const [],
      bgScale: bgScale,
      bgOffset: bgOffset ?? Offset.zero,
      bgRotation: bgRotation,
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
    );

    // Insert into owner group
    final ownerGroup = _mockStoryGroups.firstWhere(
      (g) => g.isOwner,
      orElse: () => StoryGroupModel(
        userId: 'user_me',
        userName: 'Your Story',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [],
      ),
    );

    ownerGroup.stories.insert(0, newStory);
    return newStory;
  }

  @override
  Future<void> deleteStory(String storyId) async {
    final ownerGroup = _mockStoryGroups.firstWhere((g) => g.isOwner);
    ownerGroup.stories.removeWhere((s) => s.id == storyId);
  }

  @override
  Future<void> toggleLikeStory(String storyId) async {
    for (final group in _mockStoryGroups) {
      for (final story in group.stories) {
        if (story.id == storyId) {
          story.isLiked = !story.isLiked;
          story.likesCount += story.isLiked ? 1 : -1;
          return;
        }
      }
    }
  }

  @override
  Future<void> replyToStory(String storyId, String message) async {}

  @override
  Future<List<StoryViewerModel>> getStoryViewers(String storyId) async {
    return [
      StoryViewerModel(id: 'v1', userName: 'Chhaeng Sokuntheara', userAvatar: 'assets/images/sokuntheara_profile.png', viewedTimeAgo: '10m ago'),
      StoryViewerModel(id: 'v2', userName: 'Heng Chansela', userAvatar: 'assets/images/heng_chansela_profile.png', viewedTimeAgo: '20m ago'),
      StoryViewerModel(id: 'v3', userName: 'អំណត់', userAvatar: 'assets/images/amnot_profile.jpg', viewedTimeAgo: '25m ago'),
      StoryViewerModel(id: 'v4', userName: 'Sum Sambo', userAvatar: 'assets/images/sum_sambo_profile.png', viewedTimeAgo: '40m ago'),
    ];
  }
}
