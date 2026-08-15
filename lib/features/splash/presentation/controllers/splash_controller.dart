import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Decides the app's first real screen.
///
/// Order matters: onboarding is shown only on a genuinely first run, so a
/// returning user with an expired token lands on login, not onboarding.
class SplashController extends GetxController {
  SplashController({
    required AuthController authController,
    required LocalStorage localStorage,
  })  : _auth = authController,
        _storage = localStorage;

  final AuthController _auth;
  final LocalStorage _storage;

  /// Minimum time the splash stays up, so a fast restore does not flash.
  static const _minimumDisplay = Duration(milliseconds: 600);

  @override
  void onReady() {
    super.onReady();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    debugPrint('[SPLASH] Starting initialization');
    final minimumElapsed = Future<void>.delayed(_minimumDisplay);

    var restored = false;
    var onboardingSeen = false;

    try {
      debugPrint('[SPLASH] Restoring token...');
      restored = await _auth.restoreSession().timeout(const Duration(seconds: 5));
      debugPrint('[SPLASH] Token restore completed: restored=$restored');

      debugPrint('[SPLASH] Checking onboarding status...');
      onboardingSeen = await _storage.readOnboardingSeen().timeout(const Duration(seconds: 5));
      debugPrint('[SPLASH] Onboarding check completed: seen=$onboardingSeen');
    } catch (e) {
      debugPrint('[SPLASH] Session restore/onboarding check failed: $e');
    }

    debugPrint('[SPLASH] Waiting for minimum display time...');
    await minimumElapsed;
    debugPrint('[SPLASH] Minimum display time elapsed');

    if (restored) {
      debugPrint('[SPLASH] Navigating to Home');
      Get.offAllNamed<void>(AppRoutes.home);
    } else if (!onboardingSeen) {
      debugPrint('[SPLASH] Navigating to Language Select');
      Get.offAllNamed<void>(AppRoutes.languageSelect);
    } else {
      debugPrint('[SPLASH] Navigating to Login');
      Get.offAllNamed<void>(AppRoutes.login);
    }
  }
}
