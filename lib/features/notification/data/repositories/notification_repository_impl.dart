import '../../domain/models/notification_model.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  Future<NotificationPage> getNotifications({
    int page = 0,
    int size = 20,
    bool unreadOnly = false,
  }) {
    return remoteDataSource.fetchNotifications(
      page: page,
      size: size,
      unreadOnly: unreadOnly,
    );
  }

  Future<int> getUnreadCount() {
    return remoteDataSource.fetchUnreadCount();
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
