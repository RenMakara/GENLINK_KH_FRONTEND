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
      type: NotificationType.like,
      title: 'Post Reaction',
      body:
          'Ren Makara liked your post "Building cross-platform mobile apps with Flutter & Cloud Infrastructure".',
      senderName: 'Ren Makara',
      senderAvatar: 'assets/images/ren_makara_profile.png',
      timeAgo: '10m ago',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
      targetId: 'post_me',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'notif_2',
      type: NotificationType.comment,
      title: 'New Comment',
      body: 'Sokny Enat commented: "Great work on the architecture design!"',
      senderName: 'Sokny Enat',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '45m ago',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: false,
      targetId: 'post_me',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'notif_3',
      type: NotificationType.event,
      title: 'Upcoming Campus Event',
      body:
          'Flutter Mobile Dev Workshop 2026 starts in 2 hours at ACLEDA Institute.',
      senderName: 'AUB Tech Club',
      senderAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      targetId: 'ev_1',
      targetType: 'event',
    ),
    NotificationModel(
      id: 'notif_4',
      type: NotificationType.mention,
      title: 'Mentioned You',
      body:
          'Heng Chansela mentioned you in a discussion: "@soknyenat check out this UI mockup!"',
      senderName: 'Heng Chansela',
      senderAvatar: 'assets/images/heng_chansela_profile.png',
      timeAgo: '5h ago',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      targetId: 'post_chansela',
      targetType: 'post',
    ),
    NotificationModel(
      id: 'notif_5',
      type: NotificationType.system,
      title: 'Welcome to GenLink KH',
      body:
          'Your profile setup is complete! Explore your campus community feed, groups, and events.',
      senderName: 'GenLink KH Team',
      senderAvatar: 'assets/logos/genlink_logo.png',
      timeAgo: '1d ago',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      targetId: 'welcome',
      targetType: 'system',
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
    // Check duplicate notification by ID or identical target/actor combo within 1 minute
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
