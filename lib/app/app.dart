import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/config/app_config.dart';
import '../core/localization/app_translations.dart';
import '../core/localization/localization_service.dart';
import '../core/theme/theme_controller.dart';
import '../design_system/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

/// Root application shell for GenLink KH.
///
/// Hosts the GetX configuration: routes, translations, and theme mode.
/// Theme and locale are read reactively so a change in Settings takes
/// effect immediately, without a restart.
///
/// Dependencies are registered by `bootstrap()` *before* this widget is
/// built — not via `initialBinding` — because the two `Get.find` calls
/// below run during `build`, which happens before `GetMaterialApp` would
/// have had a chance to run its own binding.
class GenLinkKhApp extends StatelessWidget {
  const GenLinkKhApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localization = Get.find<LocalizationService>();

    return Obx(
      () => GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,

        // Theme — Khmer and English each get their own text theme.
        theme: AppTheme.lightFor(localization.languageCode),
        darkTheme: AppTheme.darkFor(localization.languageCode),
        themeMode: themeController.themeMode.value,

        // Localization.
        //
        // `supportedLocales` is deliberately left at its default: Material's
        // own strings (date picker, text-selection menu) need
        // `flutter_localizations` to render in Khmer, which is not a
        // dependency yet. GetX `.tr` is independent of those delegates, so
        // every app-authored label still follows the selected language.
        translations: AppTranslations(),
        locale: localization.locale,
        fallbackLocale: LocalizationService.fallbackLocale,

        // Routing
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknownRoute,
      ),
    );
  }
}
