import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final ApiClient? _apiClient;

  StoryRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ??
            (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);

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
          mediaUrl:
              'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
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
    if (_apiClient != null) {
      try {
        final remoteGroups = await _apiClient.get(
          ApiEndpoints.stories,
          parse: (data) => ApiClient.asList(data, (json) {
            final author = json['author'] is Map<String, dynamic>
                ? json['author'] as Map<String, dynamic>
                : const <String, dynamic>{};
            final stories = json['stories'] as List? ?? const [];
            final userId = author['userId']?.toString() ?? '';
            final isOwner = json['isOwner'] as bool? ?? (userId == 'user_me');
            return StoryGroupModel(
              userId: userId,
              userName: (author['fullName'] as String?) ??
                  (author['username'] as String?) ??
                  'User',
              userAvatar: author['avatarUrl'] as String? ??
                  'assets/images/user_profile.png',
              isOwner: isOwner,
              hasUnseen: json['hasUnseen'] as bool? ?? false,
              stories: stories
                  .map((s) =>
                      _storyFromJson((s as Map).cast<String, dynamic>()))
                  .toList(),
            );
          }),
        );
        if (remoteGroups.isNotEmpty) {
          // Ensure owner group exists
          if (!remoteGroups.any((g) => g.isOwner)) {
            final ownerGroup = _mockStoryGroups.firstWhere(
              (g) => g.isOwner,
              orElse: () => StoryGroupModel(
                userId: 'user_me',
                userName: 'Sokny Enat',
                userAvatar: 'assets/images/user_profile.png',
                isOwner: true,
                stories: [],
              ),
            );
            return [ownerGroup, ...remoteGroups];
          }
          return remoteGroups;
        }
      } catch (_) {
        // Fallback to local mock data on network error
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    // Filter stories based on privacy rules:
    // If a story is 'Only Me', only the owner group (isOwner == true) contains it
    return _mockStoryGroups
        .map((group) {
          if (group.isOwner) return group;
          final visibleStories = group.stories
              .where((s) => s.storyPrivacy != StoryPrivacy.onlyMe)
              .toList();
          return StoryGroupModel(
            userId: group.userId,
            userName: group.userName,
            userAvatar: group.userAvatar,
            isOwner: group.isOwner,
            hasUnseen: group.hasUnseen,
            stories: visibleStories,
          );
        })
        .where((group) => group.isOwner || group.stories.isNotEmpty)
        .toList();
  }

  @override
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
  }) async {
    final resolvedSettings = settings ??
        StorySettings(
          visibility: StoryPrivacy.fromString(visibility),
          replyPermission: StoryReplyPermission.fromString(replyPrivacy),
          allowReactions: allowReactions,
        );

    final newStory = StoryItemModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      mediaUrl: mediaUrl,
      textContent: textContent,
      location: location,
      settings: resolvedSettings,
      bgGradientStart: bgGradientStart ?? '0xFF0F172A',
      bgGradientEnd: bgGradientEnd ?? '0xFF1E293B',
      layers: layers ?? const [],
      bgScale: bgScale,
      bgOffset: bgOffset ?? Offset.zero,
      bgRotation: bgRotation,
      templateId: templateId,
      templateSlots: templateSlots ?? const [],
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
    );

    // Insert into owner group
    final ownerGroup = _mockStoryGroups.firstWhere(
      (g) => g.isOwner,
      orElse: () => StoryGroupModel(
        userId: 'user_me',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [],
      ),
    );

    ownerGroup.stories.insert(0, newStory);

    if (_apiClient != null) {
      try {
        await _apiClient.post(
          ApiEndpoints.stories,
          body: {
            'mediaUrl': mediaUrl ?? '',
            'mediaType': type == StoryType.video ? 'VIDEO' : 'IMAGE',
            'caption': textContent,
            'location': location,
            'visibility': settings?.visibilityLabel ?? visibility,
            'replyPrivacy': settings?.replyPermissionLabel ?? replyPrivacy,
            'allowReactions': settings?.allowReactions ?? allowReactions,
            'templateId': templateId,
          },
          parse: (data) => _storyFromJson(ApiClient.asMap(data)),
        );
      } catch (_) {
        // Local state preserved even if backend fails
      }
    }

    return newStory;
  }

  @override
  Future<void> updateStory(String storyId, StoryItemModel updatedStory) async {
    final ownerGroup = _mockStoryGroups.firstWhere((g) => g.isOwner,
        orElse: () => _mockStoryGroups.first);
    final index = ownerGroup.stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      ownerGroup.stories[index] = updatedStory;
    }

    if (_apiClient != null) {
      try {
        await _apiClient.put(
          ApiEndpoints.storyItem(storyId),
          body: {
            'caption': updatedStory.textContent,
            'visibility': updatedStory.visibility,
            'replyPrivacy': updatedStory.replyPrivacy,
            'allowReactions': updatedStory.allowReactions,
          },
          parse: (_) {},
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    final ownerGroup = _mockStoryGroups.firstWhere((g) => g.isOwner,
        orElse: () => _mockStoryGroups.first);
    ownerGroup.stories.removeWhere((s) => s.id == storyId);

    if (_apiClient != null) {
      try {
        await _apiClient.delete(ApiEndpoints.storyItem(storyId));
      } catch (_) {}
    }
  }

  @override
  Future<void> markViewed(String storyId) async {
    if (_apiClient != null) {
      try {
        await _apiClient.post(ApiEndpoints.storyView(storyId), parse: (_) {});
      } catch (_) {}
    }
  }

  @override
  Future<List<StoryViewerModel>> getStoryViewers(String storyId) async {
    if (_apiClient != null) {
      try {
        return await _apiClient.get(
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
                DateTime.tryParse(json['viewedAt']?.toString() ?? ''),
              ),
            );
          }),
        );
      } catch (_) {}
    }

    return [
      StoryViewerModel(
        id: 'v1',
        userName: 'Chhaeng Sokuntheara',
        userAvatar: 'assets/images/sokuntheara_profile.png',
        viewedTimeAgo: '10m ago',
      ),
      StoryViewerModel(
        id: 'v2',
        userName: 'Heng Chansela',
        userAvatar: 'assets/images/heng_chansela_profile.png',
        viewedTimeAgo: '20m ago',
      ),
      StoryViewerModel(
        id: 'v3',
        userName: 'អំណត់',
        userAvatar: 'assets/images/amnot_profile.jpg',
        viewedTimeAgo: '25m ago',
      ),
      StoryViewerModel(
        id: 'v4',
        userName: 'Sum Sambo',
        userAvatar: 'assets/images/sum_sambo_profile.png',
        viewedTimeAgo: '40m ago',
      ),
    ];
  }

  @override
  Future<void> toggleLikeStory(String storyId) async {
    for (final group in _mockStoryGroups) {
      for (final story in group.stories) {
        if (story.id == storyId) {
          if (!story.allowReactions) return;
          story.isLiked = !story.isLiked;
          story.likesCount += story.isLiked ? 1 : -1;
          return;
        }
      }
    }
  }

  @override
  Future<void> replyToStory(String storyId, String message) async {
    for (final group in _mockStoryGroups) {
      for (final story in group.stories) {
        if (story.id == storyId) {
          if (story.storyReplyPermission == StoryReplyPermission.off) {
            throw Exception('Replies are disabled for this story.');
          }
          return;
        }
      }
    }
  }

  StoryItemModel _storyFromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final mediaType = (json['mediaType'] as String?) ?? 'IMAGE';
    return StoryItemModel(
      id: json['storyId']?.toString() ?? json['id']?.toString() ?? '',
      type: mediaType == 'VIDEO' ? StoryType.video : StoryType.photo,
      mediaUrl: json['mediaUrl'] as String?,
      textContent: json['caption'] as String? ?? json['textContent'] as String?,
      timeAgo: _timeAgo(createdAt),
      createdAt: createdAt,
      visibility: json['visibility'] as String? ?? 'Public',
      replyPrivacy: json['replyPrivacy'] as String? ?? 'Everyone',
      allowReactions: json['allowReactions'] as bool? ?? true,
      location: json['location'] as String?,
      templateId: json['templateId'] as String?,
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
