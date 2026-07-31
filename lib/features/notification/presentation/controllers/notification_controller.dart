import 'package:get/get.dart';
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

  Future<void> markAsRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
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
}
