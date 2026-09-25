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

  static const totalSteps = 4;
  static const languageStep = 1;
  static const appearanceStep = 2;

  final preferencePageController = PageController();
  final currentStep = languageStep.obs;
  late final selected = localization.language.value.obs;
  late final selectedTheme = themeController.themeMode.value.obs;
  final isSaving = false.obs;

  bool get isAppearanceStep => currentStep.value == appearanceStep;

  @override
  void onClose() {
    preferencePageController.dispose();
    super.onClose();
  }

  Future<void> select(String language) async {
    selected.value = language;
    await localization.setLanguage(language);
  }

  Future<void> selectTheme(ThemeMode mode) async {
    selectedTheme.value = mode;
    await themeController.setThemeMode(mode);
  }

  void onStepChanged(int index) => currentStep.value = index + languageStep;

  Future<void> next() async {
    if (isAppearanceStep) {
      await continueToCompletion();
      return;
    }

    await preferencePageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> previous() async {
    if (currentStep.value == languageStep) {
      Get.offAllNamed<void>(AppRoutes.welcome);
      return;
    }

    await preferencePageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> continueToCompletion() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await localization.setLanguage(selected.value);
      await themeController.setThemeMode(selectedTheme.value);
      Get.offAllNamed<void>(AppRoutes.completion);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> continueToSplash() => continueToCompletion();
}
