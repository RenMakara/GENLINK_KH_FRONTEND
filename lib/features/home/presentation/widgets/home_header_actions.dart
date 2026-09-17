import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
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
      final unread = notifController.totalUnreadCount.value > 0
          ? notifController.totalUnreadCount.value
          : notifController.unreadCount;

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
        onTap: () => Get.toNamed<void>(AppRoutes.chat),
        tooltip: effectiveTooltip,
      );
    }

    final chatController = Get.find<ChatController>();
    return Obx(() {
      final count = chatController.unreadCount.value > 0
          ? chatController.unreadCount.value
          : chatController.totalUnreadCount;

      return AppHeaderActionButton(
        icon: Icons.sms_outlined,
        badgeCount: count,
        onTap: () => Get.toNamed<void>(AppRoutes.chat),
        tooltip: effectiveTooltip,
      );
    });
  }
}
