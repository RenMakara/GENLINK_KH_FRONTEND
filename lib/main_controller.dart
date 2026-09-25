import 'package:get/get.dart';

class MainController extends GetxController {
  static MainController get to => Get.find<MainController>();

  static const defaultIndex = 0;

  final currentIndex = defaultIndex.obs;
  final isNavBarVisible = true.obs;

  void changeIndex(int index) {
    if (index < 0 || index > 3) return;
    currentIndex.value = index;
    isNavBarVisible.value = true;
  }

  void setNavBarVisibility(bool visible) {
    if (isNavBarVisible.value != visible) {
      isNavBarVisible.value = visible;
    }
  }

  void reset() => currentIndex.value = defaultIndex;
}
