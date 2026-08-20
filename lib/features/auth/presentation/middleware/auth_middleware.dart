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
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth != null && !auth.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
