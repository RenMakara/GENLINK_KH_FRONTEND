import 'package:flutter/material.dart';
import '../../domain/models/story_model.dart';

export '../../domain/models/story_model.dart' show StoryAuthor;

/// Established demo authors whose identities are consistent with the GenLink Feed.
abstract final class DemoStoryAuthors {
  static const renMakara = StoryAuthor(
    id: 'user_makara',
    name: 'Ren Makara',
    avatarUrl: 'assets/images/ren_makara_profile.png',
    handle: '@renmakara',
    university: 'ACLEDA University of Business (AUB)',
  );

  static const hengChansela = StoryAuthor(
    id: 'user_chansela',
    name: 'Heng Chansela',
    avatarUrl: 'assets/images/heng_chansela_profile.png',
    handle: '@hengchansela',
    university: 'ACLEDA University of Business (AUB)',
  );
}

/// Temporary frontend demo story model for evaluating the Stories UI.
///
/// NOTE: Uses a complete [StoryAuthor] as the single source of truth for
/// user identity across Feed, Stories, and Profile.
class DemoStoryModel {
  final StoryAuthor author;
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
    required this.author,
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

  // Source-of-truth author properties
  String get userId => author.id;
  String get userName => author.name;
  String get avatarUrl => author.avatarUrl;
  String get id => 'demo_${author.id}';
  String get userAvatar => author.avatarUrl;
  String get content => storyContent;

  /// Converts this demo story model into a [StoryGroupModel] compatible with
  /// the shared Story Viewer and tray components.
  StoryGroupModel toStoryGroup() {
    final startHex = gradientColors.isNotEmpty
        ? '0x${gradientColors.first.toARGB32().toRadixString(16).padLeft(8, '0')}'
        : '0xFF0F172A';
    final endHex = gradientColors.length > 1
        ? '0x${gradientColors.last.toARGB32().toRadixString(16).padLeft(8, '0')}'
        : '0xFF1E293B';

    return StoryGroupModel(
      userId: author.id,
      userName: author.name,
      userAvatar: author.avatarUrl,
      isOwner: false,
      hasUnseen: !isViewed,
      stories: [
        StoryItemModel(
          id: 'demo_${author.id}',
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

/// Pre-populated list of demo stories using established Feed authors.
final List<DemoStoryModel> kDemoStories = [
  DemoStoryModel(
    author: DemoStoryAuthors.renMakara,
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
    author: DemoStoryAuthors.hengChansela,
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
];

/// Returns all demo stories formatted as [StoryGroupModel]s.
List<StoryGroupModel> getDemoStoryGroups() {
  return kDemoStories.map((d) => d.toStoryGroup()).toList();
}

/// Finds a demo story by story id, author id, or author name.
DemoStoryModel? getDemoStoryById(String storyId) {
  final normalized = storyId.replaceFirst('demo_', '').toLowerCase();
  for (final story in kDemoStories) {
    if (story.id.toLowerCase() == storyId.toLowerCase() ||
        story.userId.toLowerCase() == storyId.toLowerCase() ||
        story.userId.toLowerCase() == normalized ||
        story.userId.toLowerCase() == 'user_$normalized' ||
        story.userId.toLowerCase() == 'demo_user_$normalized' ||
        story.userName.toLowerCase() == normalized ||
        story.author.name.toLowerCase() == normalized ||
        story.author.id.toLowerCase() == normalized) {
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
