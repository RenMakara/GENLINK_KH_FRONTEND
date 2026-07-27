import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/localization/localization_service.dart';
import '../core/theme/theme_controller.dart';
import 'app.dart';
import 'bindings/initial_binding.dart';

/// Bootstraps app-level setup before rendering GenLink KH.
///
/// Dependency registration happens here rather than through
/// `GetMaterialApp.initialBinding` so that [GenLinkKhApp] can resolve the
/// theme and localization controllers during its first `build`.
///
/// The stored theme and language are loaded before the first frame, so the
/// app opens directly in the user's preference instead of flashing the
/// default and correcting itself.
///
/// The single hard rule here: **the app must always paint**. Every preload is
/// a convenience — the worst case of skipping one is the wrong theme or
/// language for a moment, which self-corrects. A preload that throws or hangs
/// must never prevent `runApp`, because the result is an unrecoverable black
/// screen with no error on screen and nothing in the logs.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface framework and platform errors instead of letting them vanish.
  // Without this a build-time or async error during startup can leave a blank
  // window and an empty console — the exact failure this file guards against.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError during startup: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error during startup: $error\n$stack');
    return true;
  };

  InitialBinding().dependencies();

  // Preload persisted preferences, but never let them block the first frame.
  // A keystore read can hang or throw on some devices/emulators; the timeout
  // caps the wait and the catch swallows a failure, so a slow or broken store
  // costs at most [_preloadTimeout] and a default-styled first frame.
  try {
    await Future.wait([
      Get.find<ThemeController>().load(),
      Get.find<LocalizationService>().load(),
    ]).timeout(_preloadTimeout);
  } catch (error, stack) {
    debugPrint('Preload skipped (${error.runtimeType}): $error\n$stack');
  }

  runApp(const GenLinkKhApp());
}

/// Long enough for a healthy keystore read, short enough that a stuck one
/// does not read as a frozen launch.
const _preloadTimeout = Duration(seconds: 3);
