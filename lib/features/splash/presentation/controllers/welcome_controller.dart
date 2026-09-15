import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';

class WelcomeController extends GetxController {
  WelcomeController({required this._localStorage});

  final LocalStorage _localStorage;
  final isSaving = false.obs;

  void start() => Get.offAllNamed<void>(AppRoutes.languageSelect);

  Future<void> skip() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await _localStorage.markInitialPreferencesSeen();
      await _localStorage.markOnboardingSeen();
      Get.offAllNamed<void>(AppRoutes.authChoice);
    } finally {
      isSaving.value = false;
    }
  }
}
