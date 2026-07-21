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
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  InitialBinding().dependencies();

  await Future.wait([
    Get.find<ThemeController>().load(),
    Get.find<LocalizationService>().load(),
  ]);

  runApp(const GenLinkKhApp());
}
