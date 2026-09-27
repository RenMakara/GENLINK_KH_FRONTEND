import 'package:get/get.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';

class MainController extends GetxController {
  static MainController get to => Get.find<MainController>();

  static const homeIndex = 0;
  static const levelUpIndex = 1;
  static const financeIndex = 2;
  static const profileIndex = 3;
  static const tabCount = 4;
  static const defaultIndex = homeIndex;

  final currentIndex = defaultIndex.obs;
  final isNavBarVisible = true.obs;

  void changeIndex(int index) {
    if (index < 0 || index >= tabCount) return;

    final didChangeTab = currentIndex.value != index;
    if (didChangeTab) {
      currentIndex.value = index;
    }

    // A tab selection is also an explicit request to reveal navigation.
    if (!isNavBarVisible.value) {
      isNavBarVisible.value = true;
    }

    // Avoid starting a duplicate network refresh when the active Profile tab
    // is tapped again. Its double-tap handler owns explicit refreshes.
    if (didChangeTab &&
        index == profileIndex &&
        Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshFollowStats();
    }
  }

  void setNavBarVisibility(bool visible) {
    if (isNavBarVisible.value != visible) {
      isNavBarVisible.value = visible;
    }
  }

  void reset() {
    currentIndex.value = defaultIndex;
    isNavBarVisible.value = true;
  }
}
