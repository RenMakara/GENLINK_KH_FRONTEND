import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/notification_model.dart';

class NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSource({required this.dio});

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.notifications),
    );
    if (response.statusCode == 200 && response.data != null) {
      final body = response.data;
      var rawData = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : body;
      if (rawData is Map<String, dynamic> && rawData.containsKey('content')) {
        rawData = rawData['content'];
      }
      if (rawData is List) {
        return rawData
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }
    return <NotificationModel>[];
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>(
          '${ApiEndpoints.notifications}/$notificationId/read',
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.notifications}/read-all'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await guardDio(
        () => dio.delete<dynamic>(
          '${ApiEndpoints.notifications}/$notificationId',
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    // Real API does not support client-side notification injection.
  }
}
