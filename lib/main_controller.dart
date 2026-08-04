import 'package:get/get.dart';

/// Single reactive source of truth for [MainScreen] bottom navigation.
class MainController extends GetxController {
  static MainController get to => Get.find<MainController>();

  final currentIndex = 0.obs;

  void changeIndex(int index) {
    if (index < 0 || index > 3) return;
    currentIndex.value = index;
  }
}
