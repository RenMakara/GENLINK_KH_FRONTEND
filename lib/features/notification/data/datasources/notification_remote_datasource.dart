import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/notification_model.dart';

class NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSource({required this.dio});

  final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'notif_1',
      type: NotificationType.reply,
      category: NotificationCategory.social,
      title: 'Dara replied to your comment',
      body: '“Great idea! Let’s collaborate on this.”',
      contextText: '“Great idea!”',
      senderName: 'Dara',
      senderAvatar: 'assets/images/ren_makara_profile.png',
      timeAgo: '2m ago',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
      targetId: 'post_arch',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'notif_2',
      type: NotificationType.budgetWarning,
      category: NotificationCategory.finance,
      title: "You've used 80% of your budget",
      body: 'You have spent \$80 of your \$100 food budget.',
      contextText: 'Food · \$80 of \$100',
      senderName: 'GenLink Finance',
      timeAgo: '15m ago',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      targetId: 'budget_food',
      targetType: 'budget',
    ),
    NotificationModel(
      id: 'notif_3',
      type: NotificationType.eventReminder,
      category: NotificationCategory.events,
      title: 'Flutter Workshop is tomorrow',
      body: 'Starts at 9:00 AM at ACLEDA University Auditorium.',
      contextText: '9:00 AM · ACLEDA University',
      senderName: 'Tech Club',
      timeAgo: '1h ago',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      targetId: 'ev_flutter',
      targetType: 'event',
    ),
    NotificationModel(
      id: 'notif_4',
      type: NotificationType.habitReminder,
      category: NotificationCategory.reminders,
      title: 'Time to complete Morning Reading',
      body: 'Spend 15 minutes on reading today.',
      contextText: 'Keep your streak going!',
      senderName: 'GenLink Productivity',
      timeAgo: '2h ago',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      targetId: 'habit_reading',
      targetType: 'habit',
    ),
    NotificationModel(
      id: 'notif_5',
      type: NotificationType.friendRequest,
      category: NotificationCategory.social,
      title: 'Lina sent you a friend request',
      body: 'Lina wants to connect with you.',
      contextText: '2 mutual friends',
      senderName: 'Lina',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
      isRead: false,
      targetId: 'user_lina',
      targetType: 'friend_request',
    ),

    NotificationModel(
      id: 'notif_6',
      type: NotificationType.like,
      category: NotificationCategory.social,
      title: 'Sokchea liked your post',
      body: 'Sokchea liked your post "Building cross-platform mobile apps".',
      contextText: '“Building cross-platform mobile apps”',
      senderName: 'Sokchea',
      senderAvatar: 'assets/images/heng_chansela_profile.png',
      timeAgo: 'Yesterday',
      timestamp: DateTime.now().subtract(const Duration(hours: 26)),
      isRead: true,
      targetId: 'post_me',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'notif_7',
      type: NotificationType.quizResult,
      category: NotificationCategory.updates,
      title: 'Quiz result is ready!',
      body: 'Your quiz submission has been graded.',
      contextText: 'You scored 85%',
      senderName: 'Quiz Center',
      timeAgo: 'Yesterday',
      timestamp: DateTime.now().subtract(const Duration(hours: 28)),
      isRead: true,
      targetId: 'quiz_finance',
      targetType: 'quiz',
    ),
    NotificationModel(
      id: 'notif_8',
      type: NotificationType.savingGoal,
      category: NotificationCategory.finance,
      title: "You're 70% closer to your saving goal",
      body: 'Keep going! Only \$150 left to reach your goal.',
      contextText: 'Laptop Saving Goal',
      senderName: 'GenLink Finance',
      timeAgo: 'Yesterday',
      timestamp: DateTime.now().subtract(const Duration(hours: 30)),
      isRead: true,
      targetId: 'goal_laptop',
      targetType: 'saving_goal',
    ),

    NotificationModel(
      id: 'notif_9',
      type: NotificationType.eventRsvp,
      category: NotificationCategory.events,
      title: 'Tech Summit Cambodia registration confirmed',
      body: 'You are registered for Tech Summit Cambodia 2026.',
      contextText: 'Phnom Penh Center · Ticket #GLK-4029',
      senderName: 'Event Desk',
      timeAgo: '3d ago',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      targetId: 'ev_summit',
      targetType: 'event',
    ),
    NotificationModel(
      id: 'notif_10',
      type: NotificationType.taskReminder,
      category: NotificationCategory.reminders,
      title: 'Task reminder: Project Proposal',
      body: 'Due before Friday 5:00 PM.',
      contextText: 'Due before Friday 5:00 PM',
      senderName: 'GenLink Productivity',
      timeAgo: '4d ago',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
      targetId: 'task_proposal',
      targetType: 'task',
    ),
    NotificationModel(
      id: 'notif_11',
      type: NotificationType.achievement,
      category: NotificationCategory.updates,
      title: 'Achievement Unlocked: 7-Day Habit Streak',
      body: 'You completed all habits for 7 consecutive days!',
      contextText: 'You completed all habits for 7 days',
      senderName: 'GenLink Rewards',
      timeAgo: '5d ago',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
      targetId: 'ach_streak',
      targetType: 'achievement',
    ),
  ];

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(ApiEndpoints.notifications),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final rawData = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
        if (rawData is List && rawData.isNotEmpty) {
          return rawData
              .map(
                (json) =>
                    NotificationModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (_) {}
    return _mockNotifications;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await guardDio(
        () => dio.put<dynamic>(
          '${ApiEndpoints.notifications}/$notificationId/read',
        ),
      );
    } catch (_) {}
    final idx = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _mockNotifications[idx].isRead = true;
    }
    return true;
  }

  Future<bool> markAllAsRead() async {
    try {
      await guardDio(
        () => dio.put<dynamic>('${ApiEndpoints.notifications}/read-all'),
      );
    } catch (_) {}
    for (var n in _mockNotifications) {
      n.isRead = true;
    }
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>(
          '${ApiEndpoints.notifications}/$notificationId',
        ),
      );
    } catch (_) {}
    _mockNotifications.removeWhere((n) => n.id == notificationId);
    return true;
  }

  Future<void> addNotification(NotificationModel notification) async {
    final exists = _mockNotifications.any(
      (n) =>
          n.id == notification.id ||
          (n.targetId == notification.targetId &&
              n.senderName == notification.senderName &&
              n.type == notification.type &&
              DateTime.now().difference(n.timestamp).inSeconds < 60),
    );
    if (!exists) {
      _mockNotifications.insert(0, notification);
    }
  }
}
