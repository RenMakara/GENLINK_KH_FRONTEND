import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../controllers/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Dio();
    final dataSource = NotificationRemoteDataSource(dio: dio);
    final repository = NotificationRepositoryImpl(remoteDataSource: dataSource);
    Get.lazyPut<NotificationController>(
      () => NotificationController(repository: repository),
      fenix: true,
    );
  }
}
