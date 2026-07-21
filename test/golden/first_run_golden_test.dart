import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/language_select_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:get/get.dart';

/// Golden tests for the first-run flow.
///
/// These exist to check the rendered result against the design, not to
/// gate CI — regenerate with `flutter test --update-goldens`.
void main() {
  const phone = Size(390, 844);

  setUp(() {
    Get
      ..put<LocalStorage>(LocalStorage())
      ..put<LocalizationService>(
        LocalizationService(localStorage: Get.find<LocalStorage>()),
      );
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
    // Splash runs an indeterminate progress animation that never settles.
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = phone * tester.view.devicePixelRatio
      ..devicePixelRatio = 1.0;
    tester.view.physicalSize = phone;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: brightness == Brightness.dark
            ? AppTheme.darkFor('en')
            : AppTheme.lightFor('en'),
        home: child,
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('splash', (tester) async {
    await pumpScreen(tester, const SplashScreen(), settle: false);
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );
  });

  testWidgets('language select', (tester) async {
    Get.put<LanguageSelectController>(
      LanguageSelectController(localization: Get.find<LocalizationService>()),
    );
    await pumpScreen(tester, const LanguageSelectScreen());
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/language_select.png'),
    );
  });

  testWidgets('onboarding slide 1', (tester) async {
    Get.put<OnboardingController>(
      OnboardingController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(tester, const OnboardingScreen());
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding_1.png'),
    );
  });

  testWidgets('onboarding slide 2', (tester) async {
    final controller = Get.put<OnboardingController>(
      OnboardingController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(tester, const OnboardingScreen());
    controller.pageController.jumpToPage(1);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding_2.png'),
    );
  });
}
