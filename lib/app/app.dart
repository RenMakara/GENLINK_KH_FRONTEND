import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/config/app_config.dart';
import '../core/localization/app_translations.dart';
import '../core/localization/localization_service.dart';
import '../core/theme/theme_controller.dart';
import '../design_system/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class GenLinkKhApp extends StatelessWidget {
  const GenLinkKhApp({super.key, this.initialRoute = AppRoutes.splash});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localization = Get.find<LocalizationService>();

    return Obx(
      () => GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightFor(localization.languageCode),
        darkTheme: AppTheme.darkFor(localization.languageCode),
        themeMode: themeController.themeMode.value,

        translations: AppTranslations(),
        locale: localization.locale,
        fallbackLocale: LocalizationService.fallbackLocale,

        initialRoute: initialRoute,
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknownRoute,
      ),
    );
  }
}
