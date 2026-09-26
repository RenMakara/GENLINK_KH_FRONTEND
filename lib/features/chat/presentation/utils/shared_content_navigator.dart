import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../community/domain/models/community_models.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/presentation/screens/event_details_screen.dart';
import '../../../community/presentation/screens/forum_discussion_screen.dart';
import '../../../community/presentation/screens/post_detail_screen.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';
import '../../domain/models/chat_models.dart';

abstract final class SharedContentNavigator {
  const SharedContentNavigator._();

  /// Authoritative navigation router for shared content items.
  static Future<void> open(
    BuildContext context,
    SharedContentModel content,
  ) async {
    switch (content.type) {
      case SharedContentType.post:
        await _openPost(context, content);
        break;
      case SharedContentType.discussion:
        await _openDiscussion(context, content);
        break;
      case SharedContentType.event:
        await _openEvent(context, content);
        break;
      case SharedContentType.profile:
        await _openProfile(context, content);
        break;
    }
  }

  /// Deep-link parser and router for internal `genlink://` URIs.
  static Future<void> openDeepLink(
    BuildContext context,
    String uriString,
  ) async {
    final uri = Uri.tryParse(uriString.trim());
    if (uri == null) return;

    if (uri.scheme == 'genlink') {
      final host = uri.host.toLowerCase();
      final pathSegments = uri.pathSegments;
      final id = pathSegments.isNotEmpty ? pathSegments.first : '';

      if (id.isEmpty) return;

      switch (host) {
        case 'post':
          await open(
            context,
            SharedContentModel(
              type: SharedContentType.post,
              id: id,
              title: 'Post',
            ),
          );
          break;
        case 'discussion':
          await open(
            context,
            SharedContentModel(
              type: SharedContentType.discussion,
              id: id,
              title: 'Discussion',
            ),
          );
          break;
        case 'event':
          await open(
            context,
            SharedContentModel(
              type: SharedContentType.event,
              id: id,
              title: 'Event',
            ),
          );
          break;
        case 'profile':
          await open(
            context,
            SharedContentModel(
              type: SharedContentType.profile,
              id: id,
              title: 'Profile',
            ),
          );
          break;
      }
    }
  }

  static Future<void> _openPost(
    BuildContext context,
    SharedContentModel content,
  ) async {
    await Get.to<void>(
      () => PostDetailScreen(postId: content.id),
      transition: Transition.cupertino,
    );
  }

  static Future<void> _openDiscussion(
    BuildContext context,
    SharedContentModel content,
  ) async {
    final controller = _getOrPutCommunityController();

    try {
      final topic = await controller.fetchDiscussionDetails(content.id);
      if (topic != null) {
        await Get.to<void>(
          () => ForumDiscussionScreen(discussion: topic),
          transition: Transition.cupertino,
        );
      } else {
        if (context.mounted) _showUnavailableBanner(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      if (e is AppError && (e.statusCode == 403 || e.errorCode == 'FORBIDDEN')) {
        _showForbiddenBanner(context);
      } else {
        _showUnavailableBanner(context);
      }
    }
  }

  static Future<void> _openEvent(
    BuildContext context,
    SharedContentModel content,
  ) async {
    final controller = _getOrPutCommunityController();

    try {
      EventModel? event;
      if (controller.events.isEmpty) {
        await controller.fetchEvents();
      }
      try {
        event = controller.events.firstWhere((e) => e.id == content.id);
      } catch (_) {
        event = null;
      }

      event ??= EventModel(
        id: content.id,
        title: content.title,
        description: content.previewText ?? '',
        imageUrl: content.thumbnailUrl ?? '',
        location: content.subtitle ?? '',
      );

      await Get.to<void>(
        () => EventDetailsScreen(event: event!),
        transition: Transition.cupertino,
      );
    } catch (e) {
      if (!context.mounted) return;
      if (e is AppError && (e.statusCode == 403 || e.errorCode == 'FORBIDDEN')) {
        _showForbiddenBanner(context);
      } else {
        _showUnavailableBanner(context);
      }
    }
  }

  static Future<void> _openProfile(
    BuildContext context,
    SharedContentModel content,
  ) async {
    final rawUsername = content.subtitle?.replaceFirst('@', '').trim();
    await ProfileNavigation.open(
      userId: content.id,
      username: (rawUsername != null && rawUsername.isNotEmpty)
          ? rawUsername
          : null,
    );
  }

  static CommunityController _getOrPutCommunityController() {
    if (Get.isRegistered<CommunityController>()) {
      return Get.find<CommunityController>();
    }
    return Get.put(CommunityController());
  }

  static void _showUnavailableBanner(BuildContext context) {
    AppNotificationBanner.showInfo(
      context: context,
      title: 'chat.contentUnavailable'.tr.isNotEmpty &&
              'chat.contentUnavailable'.tr != 'chat.contentUnavailable'
          ? 'chat.contentUnavailable'.tr
          : 'Unavailable',
      message: 'chat.contentNoLongerAvailable'.tr.isNotEmpty &&
              'chat.contentNoLongerAvailable'.tr !=
                  'chat.contentNoLongerAvailable'
          ? 'chat.contentNoLongerAvailable'.tr
          : 'This content is no longer available.',
    );
  }

  static void _showForbiddenBanner(BuildContext context) {
    AppNotificationBanner.showWarning(
      context: context,
      title: 'chat.contentUnavailable'.tr.isNotEmpty &&
              'chat.contentUnavailable'.tr != 'chat.contentUnavailable'
          ? 'chat.contentUnavailable'.tr
          : 'Content unavailable',
      message: 'You do not have permission to view this content.',
    );
  }
}
