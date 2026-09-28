import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../chat/chat_navigation.dart';

import '../../../community/presentation/bindings/community_binding.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/presentation/controllers/story_controller.dart';
import '../../../community/presentation/screens/events_screen.dart';
import '../../../community/presentation/screens/friend_requests_screen.dart';
import '../../../community/presentation/screens/story_viewer_screen.dart';
import '../../../community/presentation/screens/post_detail_screen.dart';
import '../../../community/presentation/navigation/community_reference_router.dart';
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
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_model.dart';

class NotificationController extends GetxController
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    scrollController.addListener(_onScroll);
    fetchNotifications();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncLatestNotifications();
    }
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
      final newItems = pageResult.items
          .where((n) => !existingIds.contains(n.id))
          .toList();

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
    await onRealtimeNotificationReceived(notif);
  }

  /// Handles incoming realtime notifications (from STOMP or FCM foreground).
  ///
  /// Immediately inserts at the correct chronological index, increments unread count,
  /// triggers reactive UI observers, and kicks off a background sync with the backend.
  Future<void> onRealtimeNotificationReceived(NotificationModel model) async {
    final modelDeliveryId = model.metadata?['deliveryId']?.toString();
    final modelDedupeKey = model.metadata?['dedupeKey']?.toString();

    final isDuplicate = notifications.any((n) {
      if (n.id.isNotEmpty && n.id == model.id) return true;
      final nDeliveryId = n.metadata?['deliveryId']?.toString();
      if (modelDeliveryId != null &&
          nDeliveryId != null &&
          modelDeliveryId == nDeliveryId) {
        return true;
      }
      final nDedupeKey = n.metadata?['dedupeKey']?.toString();
      if (modelDedupeKey != null &&
          nDedupeKey != null &&
          modelDedupeKey == nDedupeKey) {
        return true;
      }
      if (n.targetId != null &&
          n.targetId == model.targetId &&
          n.type == model.type &&
          (n.title == model.title || n.senderName == model.senderName) &&
          n.timestamp.difference(model.timestamp).abs().inSeconds < 60) {
        return true;
      }
      return false;
    });

    if (!isDuplicate) {
      int insertIndex = 0;
      while (insertIndex < notifications.length &&
          notifications[insertIndex].timestamp.isAfter(model.timestamp)) {
        insertIndex++;
      }
      notifications.insert(insertIndex, model);
      if (!model.isRead) {
        totalUnreadCount.value++;
      }
      notifications.refresh();
    }
  }

  /// Parses raw JSON payload from STOMP `/user/queue/notifications` and dispatches it.
  Future<void> onRealtimeNotificationReceivedFromJson(
    Map<String, dynamic> json,
  ) async {
    try {
      final model = NotificationModel.fromJson(json);
      await onRealtimeNotificationReceived(model);
    } catch (e) {
      debugPrint('[NotificationController] Failed to parse realtime json: $e');
      await syncLatestNotifications();
    }
  }

  /// Adapts FCM foreground push payload and dispatches it.
  Future<void> onRealtimeNotificationReceivedFromPayload(
    dynamic payload,
  ) async {
    try {
      if (payload is Map<String, dynamic>) {
        await onRealtimeNotificationReceivedFromJson(payload);
        return;
      }
      final title = payload.title?.toString() ?? '';
      final body = payload.body?.toString() ?? '';
      final type = payload.type?.toString() ?? 'SYSTEM';
      final deliveryId = payload.deliveryId?.toString();
      final referenceType = payload.referenceType?.toString();
      final referenceId = payload.referenceId?.toString();
      final dedupeKey = payload.dedupeKey?.toString();

      final json = <String, dynamic>{
        'id': deliveryId ?? dedupeKey ?? '$type:$referenceId',
        'type': type,
        'title': title,
        'body': body,
        'message': body,
        'referenceType': referenceType,
        'referenceId': referenceId,
        'targetType': referenceType,
        'targetId': referenceId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'readStatus': false,
        'metadata': {'deliveryId': ?deliveryId, 'dedupeKey': ?dedupeKey},
      };
      final model = NotificationModel.fromJson(json);
      await onRealtimeNotificationReceived(model);
    } catch (e) {
      debugPrint('[NotificationController] Failed to process payload: $e');
      await syncLatestNotifications();
    }
  }

  /// Harmonizes local state with database records (IDs, timestamps, counts).
  Future<void> syncLatestNotifications() async {
    try {
      final results = await Future.wait([
        repository.getNotifications(page: 0, size: pageSize),
        repository.getUnreadCount(),
      ]);
      final pageResult = results[0] as NotificationPage;
      final count = results[1] as int;

      final unreadLocal = notifications.where((n) => !n.isRead).length;
      totalUnreadCount.value = (count > 0 || unreadLocal == 0)
          ? count
          : unreadLocal;

      final existingIds = notifications.map((n) => n.id).toSet();
      final newItems = pageResult.items
          .where((n) => !existingIds.contains(n.id))
          .toList();

      if (newItems.isNotEmpty) {
        for (final item in newItems.reversed) {
          final optimisticIdx = notifications.indexWhere(
            (n) =>
                n.targetId != null &&
                n.targetId == item.targetId &&
                n.type == item.type &&
                n.timestamp.difference(item.timestamp).abs().inSeconds < 120,
          );

          if (optimisticIdx != -1) {
            notifications[optimisticIdx] = item;
          } else {
            int insertIndex = 0;
            while (insertIndex < notifications.length &&
                notifications[insertIndex].timestamp.isAfter(item.timestamp)) {
              insertIndex++;
            }
            notifications.insert(insertIndex, item);
          }
        }
        notifications.refresh();
      } else {
        for (final remote in pageResult.items) {
          final idx = notifications.indexWhere((n) => n.id == remote.id);
          if (idx != -1 && notifications[idx].isRead != remote.isRead) {
            notifications[idx].isRead = remote.isRead;
          }
        }
        notifications.refresh();
      }
    } catch (_) {
      if (totalUnreadCount.value == 0) {
        totalUnreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    }
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

    var referenceType = notif.targetType ?? '';
    if (referenceType.isEmpty) {
      if (notif.type == NotificationType.chat) {
        referenceType = 'CHAT_ROOM';
      } else if (notif.type == NotificationType.event ||
          notif.type == NotificationType.eventRsvp ||
          notif.type == NotificationType.eventReminder ||
          notif.type == NotificationType.eventUpdate) {
        referenceType = 'EVENT';
      } else if (notif.type == NotificationType.comment ||
          notif.type == NotificationType.reply ||
          notif.type == NotificationType.like) {
        referenceType = 'POST';
      } else if (notif.title.toLowerCase().contains('story') ||
          notif.body.toLowerCase().contains('story')) {
        referenceType = 'STORY';
      }
    }
    final isCommentReference =
        notif.type == NotificationType.comment ||
        notif.type == NotificationType.reply ||
        (notif.metadata?['dedupeKey']?.toString().contains('comment') ?? false);
    if (await CommunityReferenceRouter.open(
      referenceType: referenceType,
      referenceId: notif.targetId,
      commentId: notif.commentId,
      openComments: isCommentReference,
    )) {
      return;
    }
    if (!context.mounted) return;

    final targetType = notif.targetType?.toUpperCase() ?? '';
    final targetId = notif.targetId;

    // ── Chat Navigation ───────────────────────────────────────────────────
    if (notif.type == NotificationType.chat ||
        targetType == 'CHAT' ||
        targetType == 'CHAT_ROOM' ||
        targetType == 'CHATROOM') {
      if (targetId != null && targetId.isNotEmpty) {
        debugPrint(
          '[CHAT-NAV] source = Notification, targetId = $targetId, currentRoute = ${Get.currentRoute}',
        );
        ChatNavigation.openChatDetail(targetId);
      } else {
        debugPrint(
          '[CHAT-NAV] source = Notification (empty targetId), currentRoute = ${Get.currentRoute}',
        );
        Get.toNamed<void>(AppRoutes.chat);
      }
      return;
    }

    // ── Story Navigation ────────────────────────────────────────────────
    final isStoryTarget =
        targetType == 'STORY' ||
        targetType == 'STORY_LIKE' ||
        targetType == 'STORY_REACTION' ||
        targetType == 'STORY_REPLY' ||
        (notif.category == NotificationCategory.social &&
            (notif.title.toLowerCase().contains('story') ||
                notif.body.toLowerCase().contains('story')));

    if (isStoryTarget && targetId != null && targetId.isNotEmpty) {
      final storyCtrl = Get.isRegistered<StoryController>()
          ? Get.find<StoryController>()
          : Get.put(StoryController());

      if (storyCtrl.storyGroups.isEmpty) {
        await storyCtrl.fetchStories();
      }

      int foundGroupIdx = -1;
      int foundStoryIdx = -1;

      for (int g = 0; g < storyCtrl.storyGroups.length; g++) {
        final sIdx = storyCtrl.storyGroups[g].stories.indexWhere(
          (s) => s.id == targetId,
        );
        if (sIdx != -1) {
          foundGroupIdx = g;
          foundStoryIdx = sIdx;
          break;
        }
      }

      // If not found in current groups, attempt to refresh from backend
      if (foundGroupIdx == -1) {
        await storyCtrl.fetchStories();
        for (int g = 0; g < storyCtrl.storyGroups.length; g++) {
          final sIdx = storyCtrl.storyGroups[g].stories.indexWhere(
            (s) => s.id == targetId,
          );
          if (sIdx != -1) {
            foundGroupIdx = g;
            foundStoryIdx = sIdx;
            break;
          }
        }
      }

      if (foundGroupIdx != -1 && context.mounted) {
        Get.to<void>(
          () => StoryViewerScreen(
            initialGroupIndex: foundGroupIdx,
            groups: storyCtrl.storyGroups,
            initialStoryIndex: foundStoryIdx,
          ),
        );
        return;
      }

      if (context.mounted) {
        AppNotificationBanner.showInfo(
          context: context,
          title: 'Story unavailable',
          message: 'This story has expired or was deleted.',
        );
      }
      return;
    }

    // ── Post / Comments Navigation ───────────────────────────────────────
    if (!isStoryTarget &&
        (targetType == 'POST' ||
            targetType == 'COMMENT' ||
            notif.type == NotificationType.comment ||
            notif.type == NotificationType.reply ||
            notif.type == NotificationType.like)) {
      if (targetId != null && targetId.isNotEmpty) {
        try {
          if (!Get.isRegistered<CommunityController>()) {
            CommunityBinding().dependencies();
          }
          final isCommentOrReply =
              notif.type == NotificationType.comment ||
              notif.type == NotificationType.reply ||
              targetType == 'COMMENT' ||
              (notif.metadata?['dedupeKey']?.toString().contains('comment') ??
                  false);

          Get.to<void>(
            () => PostDetailScreen(
              postId: targetId,
              autoOpenComments: isCommentOrReply,
              highlightCommentId: notif.commentId,
            ),
          );
          return;
        } catch (_) {}
      } else {
        if (context.mounted) {
          AppNotificationBanner.showInfo(
            context: context,
            title:
                'chat.contentUnavailable'.tr.isNotEmpty &&
                    'chat.contentUnavailable'.tr != 'chat.contentUnavailable'
                ? 'chat.contentUnavailable'.tr
                : 'Content unavailable',
            message:
                'chat.contentNoLongerAvailable'.tr.isNotEmpty &&
                    'chat.contentNoLongerAvailable'.tr !=
                        'chat.contentNoLongerAvailable'
                ? 'chat.contentNoLongerAvailable'.tr
                : 'This content is no longer available.',
          );
        }
        return;
      }
    }

    // ── Social / Friend Requests Navigation ──────────────────────────────
    if (notif.type == NotificationType.friendRequest ||
        notif.type == NotificationType.follow ||
        targetType == 'FRIEND_REQUEST' ||
        targetType == 'FRIENDREQUEST' ||
        targetType == 'USER' ||
        targetType == 'PROFILE') {
      Get.to<void>(
        () => FriendRequestsScreen(
          highlightUserId:
              notif.metadata?['senderId']?.toString() ??
              notif.metadata?['followerId']?.toString() ??
              notif.metadata?['userId']?.toString() ??
              notif.targetId,
        ),
      );
      return;
    }

    if (notif.category == NotificationCategory.social) {
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
      if (notif.type == NotificationType.taskReminder || targetType == 'TASK') {
        Get.to<void>(() => const TasksPage());
        return;
      }
      if (notif.type == NotificationType.goalReminder || targetType == 'GOAL') {
        Get.to<void>(() => const FocusPage());
        return;
      }
      Get.to<void>(() => const ProductivityPage());
      return;
    }

    // ── Updates & Gamification Navigation ────────────────────────────────
    if (notif.type == NotificationType.challengeReward ||
        targetType == 'CHALLENGE') {
      if (targetId != null && targetId.isNotEmpty) {
        Get.toNamed<void>(AppRoutes.challengeDetail, arguments: targetId);
      } else {
        Get.toNamed<void>(AppRoutes.challengeList);
      }
      return;
    }

    if (notif.type == NotificationType.badgeAwarded ||
        notif.type == NotificationType.levelUp ||
        targetType == 'BADGE' ||
        targetType == 'ACHIEVEMENT') {
      if (Get.isRegistered<ProfileController>()) {
        unawaited(Get.find<ProfileController>().load());
      }
      Get.toNamed<void>(AppRoutes.profileAchievements);
      return;
    }

    if (notif.category == NotificationCategory.updates) {
      if (notif.type == NotificationType.security || targetType == 'SECURITY') {
        Get.toNamed<void>(AppRoutes.settingsPrivacy);
        return;
      }
      if (notif.type == NotificationType.quizResult || targetType == 'QUIZ') {
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
