import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../onboarding/presentation/controllers/completion_controller.dart';
import '../../../onboarding/presentation/controllers/language_select_controller.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/welcome_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        authController: Get.find<AuthController>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );
  }
}

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(
      () => WelcomeController(localStorage: Get.find<LocalStorage>()),
    );
  }
}

class CompletionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompletionController>(
      () => CompletionController(localStorage: Get.find<LocalStorage>()),
    );
  }
}

class LanguageSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LanguageSelectController>(
      () => LanguageSelectController(
        localization: Get.find<LocalizationService>(),
        themeController: Get.find<ThemeController>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );
  }
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(localStorage: Get.find<LocalStorage>()),
    );
  }
}
