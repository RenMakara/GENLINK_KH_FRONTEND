import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/localization/localization_service.dart';
import '../core/theme/theme_controller.dart';
import 'app.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_routes.dart';
import 'startup_route_resolver.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError during startup: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error during startup: $error\n$stack');
    return true;
  };

  InitialBinding().dependencies();

  var initialRoute = AppRoutes.splash;
  final initialRouteFuture = StartupRouteResolver(
    localStorage: Get.find(),
  ).resolve();

  try {
    await Future.wait([
      Get.find<ThemeController>().load(),
      Get.find<LocalizationService>().load(),
      initialRouteFuture.then<void>((_) {}),
    ]).timeout(_preloadTimeout);
    initialRoute = await initialRouteFuture;
  } catch (error, stack) {
    debugPrint('Preload skipped (${error.runtimeType}): $error\n$stack');
  }

  runApp(GenLinkKhApp(initialRoute: initialRoute));
}

const _preloadTimeout = Duration(seconds: 3);
