import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/theme_controller.dart';

class LanguageSelectController extends GetxController {
  LanguageSelectController({
    required this.localization,
    required this.themeController,
    required this.localStorage,
  });

  final LocalizationService localization;
  final ThemeController themeController;
  final LocalStorage localStorage;

  static const step = 1;
  static const totalSteps = 6;

  late final selected = localization.language.value.obs;
  late final selectedTheme = themeController.themeMode.value.obs;
  final isSaving = false.obs;

  Future<void> select(String language) async {
    selected.value = language;
    await localization.setLanguage(language);
  }

  Future<void> selectTheme(ThemeMode mode) async {
    selectedTheme.value = mode;
    await themeController.setThemeMode(mode);
  }

  Future<void> continueToSplash() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await localization.setLanguage(selected.value);
      await themeController.setThemeMode(selectedTheme.value);
      await localStorage.markInitialPreferencesSeen();
      Get.offAllNamed<void>(AppRoutes.splash);
    } finally {
      isSaving.value = false;
    }
  }
}
