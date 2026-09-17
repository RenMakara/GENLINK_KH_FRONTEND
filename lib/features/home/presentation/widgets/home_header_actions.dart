import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../notification/domain/models/notification_model.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';

/// Reusable top-bar notification button displaying synchronized live unread badge.
class AppHeaderNotificationButton extends StatelessWidget {
  const AppHeaderNotificationButton({super.key, this.tooltip});

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final effectiveTooltip = tooltip ??
        (('community.notifications'.tr.isNotEmpty &&
                'community.notifications'.tr != 'community.notifications')
            ? 'community.notifications'.tr
            : (('settings.notifications'.tr.isNotEmpty &&
                    'settings.notifications'.tr != 'settings.notifications')
                ? 'settings.notifications'.tr
                : 'Notifications'));

    if (!Get.isRegistered<NotificationController>()) {
      return AppHeaderActionButton(
        icon: Icons.notifications_none_rounded,
        onTap: () => Get.toNamed<void>(AppRoutes.notifications),
        tooltip: effectiveTooltip,
      );
    }

    final notifController = Get.find<NotificationController>();
    return Obx(() {
      final serverUnread = notifController.totalUnreadCount.value;
      final localUnread = notifController.notifications
          .where((n) => !n.isRead && n.type != NotificationType.chat)
          .length;
      final unreadChatCount = notifController.notifications
          .where((n) => !n.isRead && n.type == NotificationType.chat)
          .length;
      final adjustedServerUnread = serverUnread > unreadChatCount
          ? serverUnread - unreadChatCount
          : localUnread;
      final unread = adjustedServerUnread > localUnread
          ? adjustedServerUnread
          : localUnread;

      return AppHeaderActionButton(
        icon: Icons.notifications_none_rounded,
        badgeCount: unread,
        onTap: () => Get.toNamed<void>(AppRoutes.notifications),
        tooltip: effectiveTooltip,
      );
    });
  }
}

/// Reusable top-bar chat button displaying synchronized live unread message badge.
class AppHeaderChatButton extends StatelessWidget {
  const AppHeaderChatButton({super.key, this.tooltip});

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final effectiveTooltip = tooltip ??
        (('community.chat'.tr.isNotEmpty &&
                'community.chat'.tr != 'community.chat')
            ? 'community.chat'.tr
            : 'Chat');

    if (!Get.isRegistered<ChatController>()) {
      return AppHeaderActionButton(
        icon: Icons.sms_outlined,
        onTap: () {
          debugPrint('[CHAT-NAV] source = Header, currentRoute = ${Get.currentRoute}');
          Get.toNamed<void>(AppRoutes.chat);
        },
        tooltip: effectiveTooltip,
      );
    }

    final chatController = Get.find<ChatController>();
    return Obx(() {
      final serverCount = chatController.unreadCount.value;
      final localCount = chatController.conversations
          .fold(0, (sum, item) => sum + item.unreadCount);
      final count = serverCount > localCount ? serverCount : localCount;

      return AppHeaderActionButton(
        icon: Icons.sms_outlined,
        badgeCount: count,
        onTap: () {
          debugPrint('[CHAT-NAV] source = Header, currentRoute = ${Get.currentRoute}, controller = ${identityHashCode(chatController)}');
          Get.toNamed<void>(AppRoutes.chat);
        },
        tooltip: effectiveTooltip,
      );
    });
  }
}
