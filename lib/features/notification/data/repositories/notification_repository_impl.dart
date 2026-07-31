import '../../domain/models/notification_model.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  Future<List<NotificationModel>> getNotifications() {
    return remoteDataSource.fetchNotifications();
  }

  Future<bool> markAsRead(String id) {
    return remoteDataSource.markAsRead(id);
  }

  Future<bool> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }

  Future<bool> deleteNotification(String id) {
    return remoteDataSource.deleteNotification(id);
  }
}
