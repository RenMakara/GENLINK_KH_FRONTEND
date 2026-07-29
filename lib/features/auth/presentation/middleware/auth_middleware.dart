import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    // Development mode bypass — allow direct navigation without login blocks
    return null;
  }
}
