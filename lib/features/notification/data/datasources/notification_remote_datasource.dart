import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/notification_model.dart';

class NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSource({required this.dio});

  Future<NotificationPage> fetchNotifications({
    int page = 0,
    int size = 20,
    bool unreadOnly = false,
  }) async {
    final response = await guardDio(
      () => dio.get<dynamic>(
        ApiEndpoints.notifications,
        queryParameters: {
          'page': page,
          'size': size,
          'unreadOnly': unreadOnly,
          'sort': 'createdAt,desc',
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;

      if (rawData is Map<String, dynamic>) {
        final content = rawData['content'] ?? rawData['items'];
        final List<NotificationModel> items = content is List
            ? content
                .whereType<Map<String, dynamic>>()
                .map(NotificationModel.fromJson)
                .toList()
            : [];
        return NotificationPage.fromPageResponse(rawData, items);
      } else if (rawData is List) {
        final items = rawData
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();
        return NotificationPage(
          items: items,
          page: page,
          size: size,
          totalElements: items.length,
          totalPages: (items.length / (size > 0 ? size : 20)).ceil(),
          hasNext: false,
        );
      }
    }
    return NotificationPage.empty();
  }

  Future<int> fetchUnreadCount() async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.notificationUnreadCount),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      final rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic>) {
        final count = rawData['unreadCount'];
        if (count is num) return count.toInt();
      }
    }
    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    await guardDio(
      () => dio.post<dynamic>(
        ApiEndpoints.notificationRead(notificationId),
      ),
    );
    return true;
  }

  Future<bool> markAllAsRead() async {
    await guardDio(
      () => dio.post<dynamic>(ApiEndpoints.notificationReadAll),
    );
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    await guardDio(
      () => dio.delete<dynamic>(
        '${ApiEndpoints.notifications}/$notificationId',
      ),
    );
    return true;
  }
}
