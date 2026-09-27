import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/localization/localization_service.dart';
import '../core/network/app_realtime_service.dart';
import '../core/theme/theme_controller.dart';
import '../firebase_options.dart';
import '../features/notification/data/firebase_mobile_notification_service.dart';
import 'app.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_routes.dart';
import 'startup_route_resolver.dart';

/// Bootstraps app-level setup before rendering GenLink KH.

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is required by mobile push registration, but a Firebase setup
  // problem must never prevent the app from painting or the user from using
  // non-push features.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));
    }
    debugPrint('[Firebase] initialized');
  } catch (error, stack) {
    debugPrint('Firebase initialization skipped: $error\n$stack');
  }

  // Request access immediately, but do not hold the first Flutter frame while
  // Android displays the permission dialog. The dialog is modal, so the user
  // cannot start an API action until they have answered it.
  unawaited(_ensureAndroidLocalNetworkAccess());

  // Surface framework and platform errors instead of letting them vanish.
  // Without this a build-time or async error during startup can leave a blank
  // window and an empty console — the exact failure this file guards against.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };

  InitialBinding().dependencies();

  var initialRoute = AppRoutes.splash;
  final initialRouteFuture = StartupRouteResolver(
    localStorage: Get.find(),
  ).resolve();

  // Preload persisted preferences, but never let them block the first frame.
  // A keystore read can hang or throw on some devices/emulators; the timeout
  // caps the wait and the catch swallows a failure, so a slow or broken store
  // costs at most [_preloadTimeout] and a default-styled first frame.
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
  if (Get.isRegistered<FirebaseMobileNotificationService>()) {
    unawaited(Get.find<FirebaseMobileNotificationService>().initialize());
  }
  if (Get.isRegistered<AppRealtimeService>()) {
    unawaited(Get.find<AppRealtimeService>().connect());
  }
}

/// Android 17 (API 37) blocks direct TCP connections to local addresses unless
/// the app declares and receives ACCESS_LOCAL_NETWORK. Local development uses
/// 10.0.2.2 to reach the host machine; production uses the public API instead.
Future<void> _ensureAndroidLocalNetworkAccess() async {
  if (!kDebugMode || defaultTargetPlatform != TargetPlatform.android) return;

  try {
    final granted = await const MethodChannel(
      'kh.edu.acleda.genlink/local_network',
    ).invokeMethod<bool>('ensurePermission');
    if (granted != true) {
      debugPrint(
        'Local network permission was not granted; local development API calls may fail.',
      );
    }
  } on PlatformException catch (error) {
    debugPrint('Unable to request local network permission: $error');
  }
}

/// Long enough for a healthy keystore read, short enough that a stuck one
/// does not read as a frozen launch.
const _preloadTimeout = Duration(seconds: 3);
