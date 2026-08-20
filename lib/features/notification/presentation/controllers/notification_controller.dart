import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../community/presentation/controllers/story_controller.dart';
import '../../../community/presentation/screens/story_viewer_screen.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_model.dart';

class NotificationController extends GetxController {
  final NotificationRepositoryImpl repository;

  NotificationController({required this.repository});

  final notifications = <NotificationModel>[].obs;
  final selectedTab = 'All'.obs;
  final isLoading = false.obs;

  final tabs = const ['All', 'Mentions', 'Activity', 'System'];

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    switch (selectedTab.value) {
      case 'Mentions':
        return notifications
            .where((n) => n.type == NotificationType.mention)
            .toList();
      case 'Activity':
        return notifications
            .where((n) =>
                n.type == NotificationType.like ||
                n.type == NotificationType.comment ||
                n.type == NotificationType.follow)
            .toList();
      case 'System':
        return notifications
            .where((n) =>
                n.type == NotificationType.system ||
                n.type == NotificationType.event ||
                n.type == NotificationType.group)
            .toList();
      case 'All':
      default:
        return notifications;
    }
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final list = await repository.getNotifications();
      notifications.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addActivityNotification(NotificationModel notif) async {
    // Deduplication check: prevent creating duplicate entries within short window
    final isDuplicate = notifications.any((n) =>
        n.id == notif.id ||
        (n.targetId == notif.targetId &&
            n.senderName == notif.senderName &&
            n.type == notif.type &&
            DateTime.now().difference(n.timestamp).inSeconds < 60));

    if (isDuplicate) return;

    notifications.insert(0, notif);
    notifications.refresh();
    await repository.addNotification(notif);
  }

  Future<void> markAsRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      notifications.refresh();
      await repository.markAsRead(id);
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifications.refresh();
    await repository.markAllAsRead();
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await repository.deleteNotification(id);
  }

  void selectTab(String tab) {
    selectedTab.value = tab;
  }

  /// Safe Navigation when tapping a notification item
  Future<void> handleNotificationTap(NotificationModel notif, BuildContext context) async {
    // Mark ONLY this notification as read
    await markAsRead(notif.id);

    if (!context.mounted) return;

    final targetType = notif.targetType?.toLowerCase();
    final targetId = notif.targetId;

    if (targetType == 'story' && targetId != null && targetId.isNotEmpty) {
      if (!Get.isRegistered<StoryController>()) {
        Get.put(StoryController());
      }
      final storyCtrl = Get.find<StoryController>();

      // Locate the group containing the target story
      int targetGroupIdx = -1;
      for (int i = 0; i < storyCtrl.storyGroups.length; i++) {
        final group = storyCtrl.storyGroups[i];
        if (group.stories.any((s) => s.id == targetId)) {
          targetGroupIdx = i;
          break;
        }
      }

      if (targetGroupIdx != -1 && storyCtrl.storyGroups.isNotEmpty) {
        Get.to(
          () => StoryViewerScreen(
            initialGroupIndex: targetGroupIdx,
            groups: storyCtrl.storyGroups,
          ),
        );
      } else {
        AppNotificationBanner.showInfo(
          context: context,
          title: 'Story unavailable',
          message: 'This story has expired or was deleted.',
        );
      }
      return;
    }

    if (targetType == 'post') {
      // Safe fallback if target post exists
      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title,
        message: notif.body,
      );
      return;
    }

    if (targetType == 'event') {
      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title,
        message: notif.body,
      );
      return;
    }
  }
}
