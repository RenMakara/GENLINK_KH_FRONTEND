import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/home_repository.dart';
import '../controllers/home_controller.dart';

/// Binding for the LevelUp tab.
///
/// Composed by `MainBinding` because the tab is rendered inline rather than
/// pushed as its own route. The legacy Home data/controller now powers the
/// LevelUp experience, so the feature folder remains a compatibility module
/// while the user-facing navigation uses the new name.
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
