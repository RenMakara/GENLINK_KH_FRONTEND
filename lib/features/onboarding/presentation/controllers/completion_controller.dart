import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';

class CompletionController extends GetxController {
  CompletionController({required this._localStorage});

  final LocalStorage _localStorage;
  final isSaving = false.obs;

  Future<void> goToGenLink() async {
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
