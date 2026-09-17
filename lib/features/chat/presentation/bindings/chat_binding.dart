import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/chat_websocket_client.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Dio();
    final secureStorage = Get.isRegistered<SecureStorage>()
        ? Get.find<SecureStorage>()
        : SecureStorage();

    final localDataSource = ChatLocalDataSource(secureStorage: secureStorage);
    final remoteDataSource = ChatRemoteDataSource(dio: dio);
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final wsClient = ChatWebSocketClient(secureStorage: secureStorage);

    Get.lazyPut<ChatLocalDataSource>(() => localDataSource, fenix: true);
    Get.lazyPut<ChatWebSocketClient>(() => wsClient, fenix: true);
    Get.lazyPut<ChatRepositoryImpl>(() => repository, fenix: true);
    Get.lazyPut<ChatController>(
      () => ChatController(
        repository: repository,
        webSocketClient: wsClient,
      ),
      fenix: true,
    );
  }
}
