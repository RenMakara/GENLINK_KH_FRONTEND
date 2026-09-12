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
import '../../../productivity/presentation/habit_feature/habit_screen.dart';
import '../../../productivity/presentation/task_feature/task_home_screen.dart';
import '../../../productivity/productivity_screen.dart';
import '../../../chat/presentation/bindings/chat_binding.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_model.dart';

class NotificationController extends GetxController {
  final NotificationRepositoryImpl repository;

  NotificationController({required this.repository});

  final notifications = <NotificationModel>[].obs;
  final selectedCategory = 'All'.obs;
  final isLoading = false.obs;

  final categories = const [
    'All',
    'Social',
    'Finance',
    'Events',
    'Reminders',
    'Updates',
  ];

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

  Future<void> handleNotificationTap(
    NotificationModel notif,
    BuildContext context,
  ) async {
    await markAsRead(notif.id);

    if (!context.mounted) return;

    final targetType = notif.targetType?.toLowerCase();
    final targetId = notif.targetId;

    final isStoryReply = notif.title.toLowerCase().contains('story reply') ||
        targetType == 'story_reply';
    final isChatNotification = isStoryReply ||
        targetType == 'chat' ||
        targetType == 'chat_message';

    if (isChatNotification) {
      if (!Get.isRegistered<ChatController>()) {
        ChatBinding().dependencies();
      }
      final chatCtrl = Get.find<ChatController>();
      final isChansela = notif.senderName.toLowerCase().contains('chansela');
      final isSokny = notif.senderName.toLowerCase().contains('sokny');
      final contactId = isChansela
          ? 'user_chansela'
          : (isSokny
              ? 'user_sokny'
              : (notif.targetId != null && notif.targetId!.isNotEmpty && targetType == 'chat'
                  ? notif.targetId!
                  : notif.senderName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')));
      final avatar = notif.senderAvatar ??
          (isChansela
              ? 'assets/images/heng_chansela_profile.png'
              : 'assets/images/user_profile.png');
      await chatCtrl.openPrivateChat(
        contactId,
        name: notif.senderName,
        avatar: avatar,
      );
      Get.to(() => const ChatDetailScreen());
      return;
    }

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

      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title,
        message: notif.body,
      );
      return;
    }

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

    if (notif.category == NotificationCategory.events ||
        notif.type == NotificationType.eventReminder ||
        notif.type == NotificationType.eventRsvp ||
        notif.type == NotificationType.eventUpdate ||
        targetType == 'event') {
      Get.to(() => const EventsScreen());
      return;
    }

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

    AppNotificationBanner.showInfo(
      context: context,
      title: notif.title.isNotEmpty ? notif.title : 'GenLink KH',
      message: notif.body,
    );
  }
}

