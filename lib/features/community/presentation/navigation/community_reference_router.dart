import 'package:get/get.dart';

import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../chat/chat_navigation.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';
import '../bindings/community_binding.dart';
import '../controllers/community_controller.dart';
import '../controllers/story_controller.dart';
import '../screens/community_screen.dart';
import '../screens/event_details_screen.dart';
import '../screens/events_screen.dart';
import '../screens/forum_discussion_screen.dart';
import '../screens/friend_requests_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/story_viewer_screen.dart';

/// Shared notification and external-link routing for Community references.
abstract final class CommunityReferenceRouter {
  static Future<bool> open({
    required String referenceType,
    String? referenceId,
    String? commentId,
    bool openComments = false,
  }) async {
    final type = _normalize(referenceType);
    final id = referenceId?.trim();

    switch (type) {
      case 'CHAT':
      case 'CHATROOM':
        if (id == null || id.isEmpty) return false;
        ChatNavigation.openChatDetail(id);
        return true;
      case 'POST':
      case 'COMMENT':
        if (id == null || id.isEmpty) return false;
        Get.to<void>(
          () => PostDetailScreen(
            postId: id,
            autoOpenComments:
                openComments || type == 'COMMENT' || commentId != null,
            highlightCommentId: commentId,
          ),
        );
        return true;
      case 'EVENT':
        if (id == null || id.isEmpty) {
          Get.to<void>(() => const EventsScreen());
          return true;
        }
        final controller = _communityController();
        try {
          final event = await controller.fetchEventDetails(id);
          Get.to<void>(() => EventDetailsScreen(event: event));
        } catch (_) {
          _showUnavailable('This event is no longer available.');
        }
        return true;
      case 'STORY':
        if (id == null || id.isEmpty) return false;
        return _openStory(id);
      case 'DISCUSSION':
        if (id == null || id.isEmpty) return false;
        final controller = _communityController();
        final discussion = await controller.fetchDiscussionDetails(id);
        if (discussion == null) {
          _showUnavailable('This discussion is no longer available.');
        } else {
          Get.to<void>(() => ForumDiscussionScreen(discussion: discussion));
        }
        return true;
      case 'USER':
      case 'FRIENDREQUEST':
        Get.to<void>(() => FriendRequestsScreen(highlightUserId: id));
        return true;
      case 'COMMUNITY':
        Get.to<void>(() => const CommunityScreen());
        return true;
      default:
        return false;
    }
  }

  static Future<bool> openStory(String storyId) => _openStory(storyId);

  static Future<bool> _openStory(String storyId) async {
    final repository = Get.isRegistered<StoryRepository>()
        ? Get.find<StoryRepository>()
        : null;
    if (repository == null) {
      _showUnavailable('This story is no longer available.');
      return true;
    }

    // This detail request validates expiry and viewer visibility on the server.
    final validatedStory = await repository.getStoryById(storyId);
    if (validatedStory == null) {
      _showUnavailable('This story is no longer available.');
      return true;
    }

    final controller = Get.isRegistered<StoryController>()
        ? Get.find<StoryController>()
        : Get.put(StoryController(repository: repository));
    await controller.fetchStories();
    final groupIndex = controller.storyGroups.indexWhere(
      (group) => group.stories.any((story) => story.id == storyId),
    );
    if (groupIndex == -1) {
      _showUnavailable('This story is no longer available.');
      return true;
    }

    final storyIndex = controller.storyGroups[groupIndex].stories.indexWhere(
      (story) => story.id == storyId,
    );
    final group = controller.storyGroups[groupIndex];
    final stories = List.of(group.stories);
    stories[storyIndex] = validatedStory;
    final groups = List.of(controller.storyGroups);
    groups[groupIndex] = StoryGroupModel(
      userId: group.userId,
      userName: group.userName,
      userAvatar: group.userAvatar,
      userHandle: group.userHandle,
      isOwner: group.isOwner,
      stories: stories,
    );
    Get.to<void>(
      () => StoryViewerScreen(
        initialGroupIndex: groupIndex,
        groups: groups,
        initialStoryIndex: storyIndex,
      ),
    );
    return true;
  }

  static CommunityController _communityController() {
    if (!Get.isRegistered<CommunityController>()) {
      CommunityBinding().dependencies();
    }
    return Get.find<CommunityController>();
  }

  static void _showUnavailable(String message) {
    final context = Get.context;
    if (context == null) return;
    AppNotificationBanner.showInfo(
      context: context,
      title: 'Content unavailable',
      message: message,
    );
  }

  static String _normalize(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
