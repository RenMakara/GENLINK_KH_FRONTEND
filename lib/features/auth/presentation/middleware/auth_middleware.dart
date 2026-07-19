import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// GetX middleware that guards routes requiring authentication.
///
/// If the user is not authenticated, redirects to the login route.
/// If the user is already authenticated, redirects away from auth routes
/// (login, register) to the home route.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    final isAuthRoute =
        route == '/login' || route == '/register' || route == '/verify-email';

    if (isAuthRoute) {
      // If already authenticated, redirect away from auth screens.
      if (authController.isAuthenticated.value) {
        return const RouteSettings(name: '/home');
      }
      return null; // Allow access to auth screens.
    }

    // For protected routes, check authentication.
    if (!authController.isAuthenticated.value) {
      return const RouteSettings(name: '/login');
    }

    return null; // Allow access.
  }
}
