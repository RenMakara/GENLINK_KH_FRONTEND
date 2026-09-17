import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../community/presentation/bindings/community_binding.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/presentation/controllers/story_controller.dart';
import '../../../community/presentation/screens/events_screen.dart';
import '../../../community/presentation/screens/friend_requests_screen.dart';
import '../../../community/presentation/widgets/comments_bottom_sheet.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_screen.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import '../../../finance/presentation/controllers/budget_controller.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../finance/presentation/controllers/saving_goal_controller.dart';
import '../../../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../../../productivity/presentation/habit_feature/habit_screen.dart';
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
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 0.obs;
  final totalUnreadCount = 0.obs;
  final isError = false.obs;
  final errorMessage = ''.obs;

  final ScrollController scrollController = ScrollController();
  static const int pageSize = 20;

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
    scrollController.addListener(_onScroll);
    fetchNotifications();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (!isLoading.value && !isLoadingMore.value && hasMore.value) {
        loadMoreNotifications();
      }
    }
  }

  int get unreadCount {
    if (totalUnreadCount.value > 0) return totalUnreadCount.value;
    return notifications.where((n) => !n.isRead).length;
  }

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
    isError.value = false;
    errorMessage.value = '';
    currentPage.value = 0;

    try {
      final pageResult = await repository.getNotifications(
        page: 0,
        size: pageSize,
      );
      notifications.assignAll(pageResult.items);
      hasMore.value = pageResult.hasNext;

      try {
        final count = await repository.getUnreadCount();
        totalUnreadCount.value = count > 0
            ? count
            : notifications.where((n) => !n.isRead).length;
      } catch (_) {
        totalUnreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      if (notifications.isEmpty) {
        isError.value = true;
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await repository.getUnreadCount();
      totalUnreadCount.value = count;
    } catch (_) {
      totalUnreadCount.value = notifications.where((n) => !n.isRead).length;
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    try {
      final pageResult = await repository.getNotifications(
        page: nextPage,
        size: pageSize,
      );

      final existingIds = notifications.map((n) => n.id).toSet();
      final newItems =
          pageResult.items.where((n) => !existingIds.contains(n.id)).toList();

      notifications.addAll(newItems);
      currentPage.value = nextPage;
      hasMore.value = pageResult.hasNext;
    } catch (_) {
      // Keep existing list on load more error
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
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
    if (!notif.isRead) {
      totalUnreadCount.value++;
    }
    notifications.refresh();
  }

  Future<void> markAsRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      if (totalUnreadCount.value > 0) {
        totalUnreadCount.value--;
      }
      notifications.refresh();
      try {
        await repository.markAsRead(id);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in notifications) {
      n.isRead = true;
    }
    totalUnreadCount.value = 0;
    notifications.refresh();
    try {
      await repository.markAllAsRead();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      if (!notifications[idx].isRead && totalUnreadCount.value > 0) {
        totalUnreadCount.value--;
      }
      notifications.removeAt(idx);
      try {
        await repository.deleteNotification(id);
      } catch (_) {}
    }
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

    final targetType = notif.targetType?.toUpperCase() ?? '';
    final targetId = notif.targetId;

    // ── Chat Navigation ───────────────────────────────────────────────────
    if (notif.type == NotificationType.chat ||
        targetType == 'CHAT' ||
        targetType == 'CHAT_ROOM' ||
        targetType == 'CHATROOM') {
      if (targetId != null && targetId.isNotEmpty) {
        Get.toNamed<void>(
          AppRoutes.chatDetail,
          arguments: {'roomId': targetId},
        );
      } else {
        Get.toNamed<void>(AppRoutes.chat);
      }
      return;
    }

    // ── Post / Comments Navigation ───────────────────────────────────────
    if (targetType == 'POST' ||
        targetType == 'COMMENT' ||
        notif.type == NotificationType.comment ||
        notif.type == NotificationType.reply ||
        notif.type == NotificationType.like) {
      if (targetId != null && targetId.isNotEmpty) {
        try {
          if (!Get.isRegistered<CommunityController>()) {
            CommunityBinding().dependencies();
          }
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CommentsBottomSheet(postId: targetId),
          );
          return;
        } catch (_) {}
      }
    }

    // ── Social / Friend Requests Navigation ──────────────────────────────
    if (notif.type == NotificationType.friendRequest ||
        notif.type == NotificationType.follow ||
        targetType == 'FRIEND_REQUEST' ||
        targetType == 'FRIENDREQUEST' ||
        targetType == 'USER' ||
        targetType == 'PROFILE') {
      Get.to<void>(() => const FriendRequestsScreen());
      return;
    }

    if (notif.category == NotificationCategory.social) {
      if (targetType == 'STORY' && targetId != null && targetId.isNotEmpty) {
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

    // ── Finance Navigation ────────────────────────────────────────────────
    if (notif.category == NotificationCategory.finance ||
        targetType == 'FINANCE') {
      if (notif.type == NotificationType.savingGoal ||
          targetType == 'SAVING_GOAL' ||
          targetType == 'SAVINGGOAL') {
        if (Get.isRegistered<SavingGoalController>()) {
          Get.to<void>(() => const SavingGoalsScreen());
          return;
        }
      }
      if (notif.type == NotificationType.budgetWarning ||
          notif.type == NotificationType.budgetExceeded ||
          targetType == 'BUDGET') {
        if (Get.isRegistered<BudgetController>()) {
          Get.to<void>(() => const BudgetScreen());
          return;
        }
      }
      if (Get.isRegistered<FinanceController>()) {
        Get.to<void>(() => const FinanceScreen());
        return;
      }
      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title.isNotEmpty ? notif.title : 'Finance',
        message: notif.body,
      );
      return;
    }

    // ── Events Navigation ─────────────────────────────────────────────────
    if (notif.category == NotificationCategory.events ||
        notif.type == NotificationType.eventReminder ||
        notif.type == NotificationType.eventRsvp ||
        notif.type == NotificationType.eventUpdate ||
        targetType == 'EVENT') {
      if (Get.isRegistered<CommunityController>()) {
        Get.to<void>(() => const EventsScreen());
        return;
      }
      try {
        CommunityBinding().dependencies();
        Get.to<void>(() => const EventsScreen());
        return;
      } catch (_) {}
      AppNotificationBanner.showInfo(
        context: context,
        title: notif.title.isNotEmpty ? notif.title : 'Events',
        message: notif.body,
      );
      return;
    }

    // ── Reminders & Productivity Navigation ──────────────────────────────
    if (notif.category == NotificationCategory.reminders ||
        targetType == 'PRODUCTIVITY') {
      if (notif.type == NotificationType.habitReminder ||
          targetType == 'HABIT') {
        Get.to<void>(() => const HabitHomeScreen());
        return;
      }
      if (notif.type == NotificationType.taskReminder ||
          targetType == 'TASK') {
        Get.to<void>(() => const TasksPage());
        return;
      }
      if (notif.type == NotificationType.goalReminder ||
          targetType == 'GOAL') {
        Get.to<void>(() => const FocusPage());
        return;
      }
      Get.to<void>(() => const ProductivityPage());
      return;
    }

    // ── Updates & Gamification Navigation ────────────────────────────────
    if (notif.category == NotificationCategory.updates) {
      if (notif.type == NotificationType.security ||
          targetType == 'SECURITY') {
        Get.toNamed<void>(AppRoutes.settingsPrivacy);
        return;
      }
      if (notif.type == NotificationType.quizResult ||
          targetType == 'QUIZ') {
        Get.toNamed<void>(AppRoutes.quizDashboard);
        return;
      }
      if (notif.type == NotificationType.achievement ||
          targetType == 'ACHIEVEMENT') {
        Get.toNamed<void>(AppRoutes.profileAchievements);
        return;
      }
    }

    // ── Safe Fallback ─────────────────────────────────────────────────────
    AppNotificationBanner.showInfo(
      context: context,
      title: notif.title.isNotEmpty ? notif.title : 'GenLink KH',
      message: notif.body,
    );
  }
}
