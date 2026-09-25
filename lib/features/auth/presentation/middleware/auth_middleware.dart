import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    if (auth != null && !auth.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
