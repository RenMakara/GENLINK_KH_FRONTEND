import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Dio();
    final localDataSource = ChatLocalDataSource();
    final dataSource = ChatRemoteDataSource(
      dio: dio,
      localDataSource: localDataSource,
    );
    final repository = ChatRepositoryImpl(
      remoteDataSource: dataSource,
      localDataSource: localDataSource,
    );
    Get.lazyPut<ChatController>(() => ChatController(repository: repository));
  }
}
