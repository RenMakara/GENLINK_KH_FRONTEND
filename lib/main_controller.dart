import 'package:get/get.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';

class MainController extends GetxController {
  static MainController get to => Get.find<MainController>();

  static const defaultIndex = 0;

  final currentIndex = defaultIndex.obs;
  final isNavBarVisible = true.obs;

  void changeIndex(int index) {
    if (index < 0 || index > 3) return;
    currentIndex.value = index;
    isNavBarVisible.value = true;
    if (index == 3 && Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshFollowStats();
    }
  }

  void setNavBarVisibility(bool visible) {
    if (isNavBarVisible.value != visible) {
      isNavBarVisible.value = visible;
    }
  }

  void reset() => currentIndex.value = defaultIndex;
}
