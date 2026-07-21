import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/home_repository.dart';
import '../controllers/home_controller.dart';

/// Binding for the Home tab.
///
/// Registered by `MainScreen` (the tab is rendered inline, not pushed as a
/// route). `lazyPut` keeps the fetch from firing before the tab exists.
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
