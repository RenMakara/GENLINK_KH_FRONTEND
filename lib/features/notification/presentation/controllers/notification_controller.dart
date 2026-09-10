import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../community/presentation/controllers/story_controller.dart';
import '../../../community/presentation/screens/events_screen.dart';
import '../../../community/presentation/screens/friend_requests_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_screen.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import '../../../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../../../productivity/presentation/habit_feature/habit_home_screen.dart';
import '../../../productivity/presentation/task_feature/task_home_screen.dart';
import '../../../productivity/productivity_screen.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_model.dart';

class NotificationController extends GetxController {
  final NotificationRepositoryImpl repository;

  NotificationController({required this.repository});

  final notifications = <NotificationModel>[].obs;
  final selectedCategory = 'All'.obs;
  final isLoading = false.obs;

  /// Categories according to the Unified Notification Center specification:
  /// All, Social, Finance, Events, Reminders, Updates
  final categories = const [
    'All',
    'Social',
    'Finance',
    'Events',
    'Reminders',
    'Updates',
  ];

  /// Backward-compatible alias for existing tests and call-sites
  String get selectedTab => selectedCategory.value;
  set selectedTab(String val) => selectCategory(val);
  List<String> get tabs => categories;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  int unreadCountForCategory(String category) {
    if (category == 'All') return unreadCount;
    return notifications
        .where((n) => !n.isRead && _matchesCategory(n, category))
        .length;
  }

  bool _matchesCategory(NotificationModel n, String category) {
    switch (category) {
      case 'Social':
        return n.category == NotificationCategory.social;
      case 'Finance':
        return n.category == NotificationCategory.finance;
      case 'Events':
        return n.category == NotificationCategory.events;
      case 'Reminders':
        return n.category == NotificationCategory.reminders;
      case 'Updates':
        return n.category == NotificationCategory.updates;
      case 'Mentions':
        return n.type == NotificationType.mention;
      case 'Activity':
        return n.category == NotificationCategory.social;
      case 'System':
        return n.category == NotificationCategory.updates;
      case 'All':
      default:
        return true;
    }
  }

  List<NotificationModel> get filteredNotifications {
    final cat = selectedCategory.value;
    if (cat == 'All') return notifications;
    return notifications.where((n) => _matchesCategory(n, cat)).toList();
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
    final isDuplicate = notifications.any(
      (n) =>
          n.id == notif.id ||
          (n.targetId == notif.targetId &&
              n.senderName == notif.senderName &&
              n.type == notif.type &&
              DateTime.now().difference(n.timestamp).inSeconds < 60),
    );

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

  void selectCategory(String category) {
    // Handle backwards-compatible aliases
    if (category == 'Mentions') {
      selectedCategory.value = 'Social';
      return;
    }
    if (category == 'Activity') {
      selectedCategory.value = 'Social';
      return;
    }
    if (category == 'System') {
      selectedCategory.value = 'Updates';
      return;
    }
    selectedCategory.value = category;
  }

  void selectTab(String tab) => selectCategory(tab);

  /// Safe Navigation when tapping a notification item to its corresponding feature.
  Future<void> handleNotificationTap(
    NotificationModel notif,
    BuildContext context,
  ) async {
    // Mark ONLY this notification as read
    await markAsRead(notif.id);

    if (!context.mounted) return;

    final targetType = notif.targetType?.toLowerCase();
    final targetId = notif.targetId;

    // 1. Social / Friend Requests / Posts
    if (notif.category == NotificationCategory.social ||
        notif.type == NotificationType.friendRequest ||
        targetType == 'friend_request') {
      if (notif.type == NotificationType.friendRequest ||
          targetType == 'friend_request') {
        Get.to(() => const FriendRequestsScreen());
        return;
      }

      if (targetType == 'story' && targetId != null && targetId.isNotEmpty) {
        if (Get.isRegistered<StoryController>()) {
          final storyCtrl = Get.find<StoryController>();
          final hasTarget = storyCtrl.storyGroups
              .any((group) => group.stories.any((s) => s.id == targetId));
          if (hasTarget) {
            AppNotificationBanner.showInfo(
              context: context,
              title: notif.title.isNotEmpty ? notif.title : 'Story',
              message: notif.body,
            );
            return;
          }
        }
        AppNotificationBanner.showInfo(
          context: context,
          title: 'Story unavailable',
          message: 'This story has expired or was deleted.',
        );
        return;
      }

      // Safe fallback / banner for posts & comments
      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title,
        message: notif.body,
      );
      return;
    }

    // 2. Finance
    if (notif.category == NotificationCategory.finance) {
      if (notif.type == NotificationType.savingGoal ||
          targetType == 'saving_goal') {
        Get.to(() => const SavingGoalsScreen());
        return;
      }
      if (notif.type == NotificationType.budgetWarning ||
          notif.type == NotificationType.budgetExceeded ||
          targetType == 'budget') {
        Get.to(() => const BudgetScreen());
        return;
      }
      Get.to(() => const FinanceScreen());
      return;
    }

    // 3. Events
    if (notif.category == NotificationCategory.events ||
        notif.type == NotificationType.eventReminder ||
        notif.type == NotificationType.eventRsvp ||
        notif.type == NotificationType.eventUpdate ||
        targetType == 'event') {
      Get.to(() => const EventsScreen());
      return;
    }

    // 4. Reminders / Productivity
    if (notif.category == NotificationCategory.reminders) {
      if (notif.type == NotificationType.habitReminder ||
          targetType == 'habit') {
        Get.to(() => const HabitHomeScreen());
        return;
      }
      if (notif.type == NotificationType.taskReminder ||
          targetType == 'task') {
        Get.to(() => const TasksPage());
        return;
      }
      if (notif.type == NotificationType.goalReminder ||
          targetType == 'goal') {
        Get.to(() => const FocusPage());
        return;
      }
      Get.to(() => const ProductivityPage());
      return;
    }

    // 5. Updates / Entertainment / Quiz
    if (notif.category == NotificationCategory.updates) {
      if (notif.type == NotificationType.quizResult || targetType == 'quiz') {
        Get.toNamed(AppRoutes.quizDashboard);
        return;
      }
      if (notif.type == NotificationType.achievement ||
          targetType == 'achievement') {
        Get.toNamed(AppRoutes.profileAchievements);
        return;
      }
    }

    // Safe fallback for forum, chat, system and other notification types
    AppNotificationBanner.showInfo(
      context: context,
      title: notif.title.isNotEmpty ? notif.title : 'GenLink KH',
      message: notif.body,
    );
  }
}

