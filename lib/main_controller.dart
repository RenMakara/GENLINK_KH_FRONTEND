import 'package:get/get.dart';

/// Single reactive source of truth for [MainScreen] bottom navigation.
class MainController extends GetxController {
  static MainController get to => Get.find<MainController>();

  static const defaultIndex = 0;

  final currentIndex = defaultIndex.obs;

  void changeIndex(int index) {
    if (index < 0 || index > 3) return;
    currentIndex.value = index;
  }

  /// Return the signed-in shell to Home when a session ends, so a different
  /// user never inherits the previous user's selected tab.
  void reset() => currentIndex.value = defaultIndex;
}
