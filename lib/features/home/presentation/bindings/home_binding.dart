import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/home_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeRepository>()) {
      Get.put<HomeRepository>(
        HomeRepositoryImpl(Get.find<ApiClient>()),
        permanent: true,
      );
    }
    Get.lazyPut<HomeController>(
      () => HomeController(repository: Get.find<HomeRepository>()),
    );
  }
}
