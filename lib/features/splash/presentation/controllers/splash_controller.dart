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

  static const _minimumDisplay = Duration(milliseconds: 1700);

  /// Callback registered by [SplashScreen] to coordinate the exit animation sequence.
  void Function(String route)? onReadyToExit;

  /// Holds the resolved destination route once initialization is complete.
  String? resolvedDestination;

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
        // Session restoration also synchronizes account-owned theme/language
        // before Home is shown. Allow that short sync window without making a
        // healthy session look like a logged-out session.
        const Duration(seconds: 8),
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

    final targetRoute = restored
        ? AppRoutes.home
        : (!initialPreferencesSeen ? AppRoutes.welcome : AppRoutes.authChoice);

    resolvedDestination = targetRoute;
    debugPrint('[SPLASH] Destination resolved: $targetRoute');

    if (onReadyToExit != null) {
      onReadyToExit!(targetRoute);
    } else {
      Get.offAllNamed<void>(targetRoute, arguments: const {'fromSplash': true});
    }
  }
}

