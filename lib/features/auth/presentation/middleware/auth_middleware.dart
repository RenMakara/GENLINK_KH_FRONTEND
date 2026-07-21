import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

/// GetX middleware that guards routes requiring authentication.
///
/// Attach to protected pages only. Splash and onboarding decide their own
/// destination and must not be guarded, or the app would bounce to login
/// before the stored session has been restored.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // If the controller is not registered yet there is nothing to check;
    // splash will resolve the session and route from there.
    if (!Get.isRegistered<AuthController>()) return null;

    final auth = Get.find<AuthController>();
    final authenticated = auth.isAuthenticated.value;

    if (AppRoutes.authRoutes.contains(route)) {
      // Already signed in — skip past the auth screens.
      return authenticated
          ? const RouteSettings(name: AppRoutes.home)
          : null;
    }

    return authenticated
        ? null
        : const RouteSettings(name: AppRoutes.login);
  }
}
