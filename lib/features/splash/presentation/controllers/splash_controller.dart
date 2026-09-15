import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SplashController extends GetxController {
  SplashController({
    required AuthController authController,
    required LocalStorage localStorage,
  }) : _auth = authController,
       _storage = localStorage;

  final AuthController _auth;
  final LocalStorage _storage;

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
    var initialPreferencesSeen = false;

    try {
      debugPrint('[SPLASH] Restoring token...');
      restored = await _auth.restoreSession().timeout(
        const Duration(seconds: 5),
      );
      debugPrint('[SPLASH] Token restore completed: restored=$restored');

      debugPrint('[SPLASH] Checking initial preferences status...');
      initialPreferencesSeen = await _storage
          .readInitialPreferencesSeen()
          .timeout(const Duration(seconds: 5));
      debugPrint(
        '[SPLASH] Initial preferences check completed: '
        'seen=$initialPreferencesSeen',
      );
    } catch (e) {
      debugPrint('[SPLASH] Session restore/onboarding check failed: $e');
    }

    debugPrint('[SPLASH] Waiting for minimum display time...');
    await minimumElapsed;
    debugPrint('[SPLASH] Minimum display time elapsed');

    if (restored) {
      debugPrint('[SPLASH] Navigating to Home');
      Get.offAllNamed<void>(AppRoutes.home);
    } else if (!initialPreferencesSeen) {
      debugPrint('[SPLASH] Navigating to Welcome');
      Get.offAllNamed<void>(AppRoutes.welcome);
    } else {
      debugPrint('[SPLASH] Navigating to Auth Choice');
      Get.offAllNamed<void>(AppRoutes.authChoice);
    }
  }
}
