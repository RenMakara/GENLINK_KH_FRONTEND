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
    // Started first so the restore call runs inside the minimum display
    // window rather than after it.
    final minimumElapsed = Future<void>.delayed(_minimumDisplay);

    var restored = false;
    var onboardingSeen = false;

    try {
      // Add a 5-second timeout so a dead backend or hanging keystore 
      // never leaves the user stuck on the splash screen forever.
      restored = await _auth.restoreSession().timeout(const Duration(seconds: 5));
      onboardingSeen = await _storage.readOnboardingSeen().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Secure storage can fail outright (keystore reset, restored backup,
      // rooted device), or the network call can timeout. Falling through with 
      // both flags false sends the user to the first-run flow — never leaves 
      // them stuck on splash.
    }

    await minimumElapsed;

    if (restored) {
      Get.offAllNamed<void>(AppRoutes.home);
    } else if (!onboardingSeen) {
      // First run starts at language select (step 1), which then hands off
      // to the onboarding slides.
      Get.offAllNamed<void>(AppRoutes.languageSelect);
    } else {
      Get.offAllNamed<void>(AppRoutes.login);
    }
  }
}
