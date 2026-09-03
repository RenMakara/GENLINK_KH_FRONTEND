import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Dio();
    final dataSource = ChatRemoteDataSource(dio: dio);
    final repository = ChatRepositoryImpl(remoteDataSource: dataSource);
    Get.lazyPut<ChatController>(() => ChatController(repository: repository));
  }
}
