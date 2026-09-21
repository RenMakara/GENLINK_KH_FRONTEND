import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/branding/app_logo.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/completion_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/language_select_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/completion_screen.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:genlink_frontend/features/splash/presentation/controllers/welcome_controller.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/welcome_screen.dart';
import 'package:get/get.dart';

void main() {
  const phone = Size(390, 844);

  setUp(() {
    Get
      ..put<LocalStorage>(LocalStorage())
      ..put<LocalizationService>(
        LocalizationService(localStorage: Get.find<LocalStorage>()),
      )
      ..put<ThemeController>(
        ThemeController(localStorage: Get.find<LocalStorage>()),
      );
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
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
    final context = tester.element(find.byType(GetMaterialApp));
    await tester.runAsync(() async {
      for (final asset in [
        'assets/images/welcome.png',
        'assets/images/onboard-image.png',
        AppLogoAssets.markLight,
        AppLogoAssets.markDark,
        AppLogoAssets.wordmark,
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
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

  testWidgets('welcome', (tester) async {
    Get.put<WelcomeController>(
      WelcomeController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(tester, const WelcomeScreen());
    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('goldens/welcome.png'),
    );
  });

  testWidgets('welcome dark mode', (tester) async {
    Get.put<WelcomeController>(
      WelcomeController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(
      tester,
      const WelcomeScreen(),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('goldens/welcome_dark.png'),
    );
  });

  testWidgets('language select', (tester) async {
    Get.put<LanguageSelectController>(
      LanguageSelectController(
        localization: Get.find<LocalizationService>(),
        themeController: Get.find<ThemeController>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );
    await pumpScreen(tester, const LanguageSelectScreen());
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/language_select.png'),
    );
  });

  testWidgets('language select dark mode', (tester) async {
    Get.put<LanguageSelectController>(
      LanguageSelectController(
        localization: Get.find<LocalizationService>(),
        themeController: Get.find<ThemeController>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );
    await pumpScreen(
      tester,
      const LanguageSelectScreen(),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/language_select_dark.png'),
    );
  });

  testWidgets('appearance select', (tester) async {
    Get.put<LanguageSelectController>(
      LanguageSelectController(
        localization: Get.find<LocalizationService>(),
        themeController: Get.find<ThemeController>(),
        localStorage: Get.find<LocalStorage>(),
      ),
    );
    await pumpScreen(tester, const LanguageSelectScreen());
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/appearance_select.png'),
    );
  });

  testWidgets('appearance select dark mode', (tester) async {
    final themeController = Get.find<ThemeController>();
    themeController.themeMode.value = ThemeMode.dark;
    Get.put<LanguageSelectController>(
      LanguageSelectController(
        localization: Get.find<LocalizationService>(),
        themeController: themeController,
        localStorage: Get.find<LocalStorage>(),
      ),
    );
    await pumpScreen(
      tester,
      const LanguageSelectScreen(),
      brightness: Brightness.dark,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/appearance_select_dark.png'),
    );
  });

  testWidgets('completion', (tester) async {
    Get.put<CompletionController>(
      CompletionController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(tester, const CompletionScreen(animate: false));
    await expectLater(
      find.byType(CompletionScreen),
      matchesGoldenFile('goldens/completion.png'),
    );
  });

  testWidgets('completion dark mode', (tester) async {
    Get.put<CompletionController>(
      CompletionController(localStorage: Get.find<LocalStorage>()),
    );
    await pumpScreen(
      tester,
      const CompletionScreen(animate: false),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(CompletionScreen),
      matchesGoldenFile('goldens/completion_dark.png'),
    );
  });
}
