import 'package:flutter/material.dart';
import '../../domain/models/story_model.dart';

/// Temporary frontend demo story model for evaluating the Stories UI.
///
/// NOTE: This is frontend-only mock data. It has no backend persistence
/// and can be safely removed once backend Story retrieval is fully active.
class DemoStoryModel {
  final String userId;
  final String userName;
  final String avatarUrl;
  final String storyContent;
  final DateTime createdAt;
  final String timeAgo;
  final String? location;
  final List<Color> gradientColors;
  final IconData? icon;
  final String? tag;
  int likesCount;
  bool isLiked;
  bool isViewed;

  DemoStoryModel({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.storyContent,
    required this.createdAt,
    this.timeAgo = '2h ago',
    this.location,
    this.gradientColors = const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    this.icon,
    this.tag,
    this.likesCount = 12,
    this.isLiked = false,
    this.isViewed = false,
  });

  // Backward compatibility getters
  String get id => 'demo_$userId';
  String get userAvatar => avatarUrl;
  String get content => storyContent;

  /// Converts this demo story model into a [StoryGroupModel] compatible with
  /// the existing Story Viewer and tray components.
  StoryGroupModel toStoryGroup() {
    final startHex = gradientColors.isNotEmpty
        ? '0x${gradientColors.first.value.toRadixString(16).padLeft(8, '0')}'
        : '0xFF0F172A';
    final endHex = gradientColors.length > 1
        ? '0x${gradientColors.last.value.toRadixString(16).padLeft(8, '0')}'
        : '0xFF1E293B';

    return StoryGroupModel(
      userId: userId,
      userName: userName,
      userAvatar: avatarUrl,
      isOwner: false,
      hasUnseen: !isViewed,
      stories: [
        StoryItemModel(
          id: 'demo_$userId',
          type: StoryType.text,
          textContent: storyContent,
          location: location,
          timeAgo: timeAgo,
          createdAt: createdAt,
          bgGradientStart: startHex,
          bgGradientEnd: endHex,
          likesCount: likesCount,
          isLiked: isLiked,
          isViewed: isViewed,
          settings: const StorySettings(
            visibility: StoryPrivacy.public,
            replyPermission: StoryReplyPermission.everyone,
            allowReactions: true,
          ),
        ),
      ],
    );
  }
}

/// Pre-populated list of demo stories for UI/UX evaluation.
final List<DemoStoryModel> kDemoStories = [
  DemoStoryModel(
    userId: 'demo_user_dara',
    userName: 'Dara',
    avatarUrl: 'assets/images/ren_makara_profile.png',
    storyContent:
        'Working on the Flutter mobile design system today! 🚀💻 Loving the new GenLink dark theme tokens.',
    location: 'CADT Innovation Hub',
    timeAgo: '2h ago',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    icon: Icons.code_rounded,
    tag: '#Flutter #DesignSystem',
    likesCount: 14,
  ),
  DemoStoryModel(
    userId: 'demo_user_lina',
    userName: 'Lina',
    avatarUrl: 'assets/images/meimei_profile.png',
    storyContent:
        'Study session at the library until 5 PM! Exam prep is in full swing. Join our study table! 📚☕',
    location: 'Central Campus Library',
    timeAgo: '3h ago',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    gradientColors: const [Color(0xFFE11D48), Color(0xFFF43F5E)],
    icon: Icons.menu_book_rounded,
    tag: '#StudyGroup #Exams',
    likesCount: 21,
  ),
  DemoStoryModel(
    userId: 'demo_user_sokha',
    userName: 'Sokha',
    avatarUrl: 'assets/images/heng_chansela_profile.png',
    storyContent:
        'Campus Hackathon 2026 kick-off this Saturday! Who wants to build AI agents with us? 🤖💡',
    location: 'Main Auditorium',
    timeAgo: '5h ago',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    gradientColors: const [Color(0xFFEA580C), Color(0xFFF59E0B)],
    icon: Icons.rocket_launch_rounded,
    tag: '#Hackathon #Innovation',
    likesCount: 35,
  ),
  DemoStoryModel(
    userId: 'demo_user_visal',
    userName: 'Visal',
    avatarUrl: 'assets/images/amnot_profile.jpg',
    storyContent:
        'Great football match this afternoon! Champions league vibe on the campus pitch ⚽🏆',
    location: 'University Sports Field',
    timeAgo: '6h ago',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
    icon: Icons.sports_soccer_rounded,
    tag: '#CampusSports #Football',
    likesCount: 18,
  ),
  DemoStoryModel(
    userId: 'demo_user_sreyneang',
    userName: 'Sreyneang',
    avatarUrl: 'assets/images/heng_chansela_km_profile.jpg',
    storyContent:
        'Photography club workshop photos are out! Golden hour shots around campus look magical 📸🌅',
    location: 'Campus Arts & Culture Center',
    timeAgo: '8h ago',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    gradientColors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
    icon: Icons.camera_alt_rounded,
    tag: '#Photography #GoldenHour',
    likesCount: 29,
  ),
];

/// Returns all demo stories formatted as [StoryGroupModel]s.
List<StoryGroupModel> getDemoStoryGroups() {
  return kDemoStories.map((d) => d.toStoryGroup()).toList();
}

/// Finds a demo story by story id or user id.
DemoStoryModel? getDemoStoryById(String storyId) {
  final normalized = storyId.replaceFirst('demo_', '');
  for (final story in kDemoStories) {
    if (story.id == storyId ||
        story.userId == storyId ||
        story.userId == normalized ||
        story.userId == 'demo_user_$normalized' ||
        story.userName.toLowerCase() == normalized.toLowerCase()) {
      return story;
    }
  }
  return null;
}

/// Updates the local like state for a demo story.
void updateDemoStoryLike(String storyId, bool isLiked, int likesCount) {
  final demo = getDemoStoryById(storyId);
  if (demo != null) {
    demo.isLiked = isLiked;
    demo.likesCount = likesCount;
  }
}

/// Marks a demo story as viewed.
void markDemoStoryViewed(String storyId) {
  final demo = getDemoStoryById(storyId);
  if (demo != null) {
    demo.isViewed = true;
  }
}
