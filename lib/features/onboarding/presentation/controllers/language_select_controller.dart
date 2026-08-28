import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/theme_controller.dart';

/// Step 1 of the first-run flow: pick the app language.
///
/// Pre-selected from the device language (Khmer device → Khmer, otherwise
/// English). The choice is applied live as the user taps, so the rest of
/// the flow is already in their language before they press Continue.
/// Tapping is an explicit choice and sticks; merely continuing without
/// tapping leaves the app following the device language.
class LanguageSelectController extends GetxController {
  LanguageSelectController({
    required this.localization,
    required this.themeController,
    required this.localStorage,
  });

  final LocalizationService localization;
  final ThemeController themeController;
  final LocalStorage localStorage;

  /// Position in the first-run flow, shown as "STEP 1 OF 6".
  static const step = 1;
  static const totalSteps = 6;

  late final selected = localization.language.value.obs;
  late final selectedTheme = themeController.themeMode.value.obs;
  final isSaving = false.obs;

  Future<void> select(String language) async {
    selected.value = language;
    // Applied immediately so the screen itself switches language.
    await localization.setLanguage(language);
  }

  Future<void> selectTheme(ThemeMode mode) async {
    selectedTheme.value = mode;
    // Applied immediately so each option is a real theme preview.
    await themeController.setThemeMode(mode);
  }

  Future<void> continueToSplash() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      // Persist the displayed defaults too, even when the user accepts the
      // device language and System theme without tapping either card.
      await localization.setLanguage(selected.value);
      await themeController.setThemeMode(selectedTheme.value);
      await localStorage.markInitialPreferencesSeen();
      Get.offAllNamed<void>(AppRoutes.splash);
    } finally {
      isSaving.value = false;
    }
  }
}
