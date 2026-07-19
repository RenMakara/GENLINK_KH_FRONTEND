import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import '../design_system/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

/// Root application shell for GenLink KH.
///
/// This file will later host the GetX app configuration, routes,
/// localization, theme mode, and dependency bindings.
class GenLinkKhApp extends StatelessWidget {
  const GenLinkKhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GenLink KH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.initial,
      getPages: AppPages.pages,
      unknownRoute: AppPages.unknownRoute,
    );
  }
}
