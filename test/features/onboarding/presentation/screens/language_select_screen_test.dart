import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/language_select_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLocalStorage localStorage;
  late LocalizationService localizationService;
  late ThemeController themeController;
  late LanguageSelectController controller;

  setUp(() {
    Get.reset();
    Get.locale = const Locale('en', 'US');

    localStorage = _MockLocalStorage();
    when(() => localStorage.readLanguage())
        .thenAnswer((_) async => LocalizationService.english);
    when(() => localStorage.saveLanguage(any())).thenAnswer((_) async {});
    when(() => localStorage.readThemeMode()).thenAnswer((_) async => 'system');
    when(() => localStorage.saveThemeMode(any())).thenAnswer((_) async {});

    localizationService = LocalizationService(localStorage: localStorage);
    localizationService.language.value = LocalizationService.english;

    themeController = ThemeController(localStorage: localStorage);
    themeController.themeMode.value = ThemeMode.system;

    controller = LanguageSelectController(
      localization: localizationService,
      themeController: themeController,
      localStorage: localStorage,
    );

    Get
      ..testMode = true
      ..put<LocalizationService>(localizationService)
      ..put<ThemeController>(themeController)
      ..put<LanguageSelectController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
    Locale locale = const Locale('en', 'US'),
  }) async {
    Get.locale = locale;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            platformBrightness: brightness,
          ),
          child: child!,
        ),
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: brightness == Brightness.dark
            ? AppTheme.darkFor(locale.languageCode)
            : AppTheme.lightFor(locale.languageCode),
        getPages: [
          GetPage(
            name: AppRoutes.languageSelect,
            page: () => const LanguageSelectScreen(),
          ),
          GetPage(
            name: AppRoutes.welcome,
            page: () => const Scaffold(body: Text('welcome route')),
          ),
          GetPage(
            name: AppRoutes.completion,
            page: () => const Scaffold(body: Text('completion route')),
          ),
        ],
        home: const LanguageSelectScreen(),
      ),
    );
  }

  testWidgets(
    'renders all header, language, and appearance elements on combined screen',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      // Top bar & Progress
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.byType(LanguageSelectScreen), findsOneWidget);

      // Title & Description
      expect(find.text('Personalize'), findsOneWidget);
      expect(find.text('your '), findsOneWidget);
      expect(find.text('experience'), findsOneWidget);
      expect(
        find.text(
          'Choose your language and appearance.\nYou can change these anytime in Settings.',
        ),
        findsOneWidget,
      );

      // Language Section
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Choose your preferred language.'), findsOneWidget);
      expect(find.text('ភាសាខ្មែរ'), findsOneWidget);
      expect(find.text('Khmer'), findsOneWidget);
      expect(find.text('English'), findsNWidgets(2)); // Title & subtitle
      expect(
        find.text('Both languages are supported throughout the app.'),
        findsOneWidget,
      );

      // Appearance Section
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Pick a theme that feels right for you.'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(
        find.text('Automatically matches your device settings.'),
        findsOneWidget,
      );

      // Continue Button
      expect(find.text('Continue'), findsOneWidget);

      // VERIFY: Continue button has NO arrow icon
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    },
  );

  testWidgets(
    'CRITICAL: System default label stays strictly on ONE line without wrapping',
    (tester) async {
      await pumpScreen(tester, size: const Size(360, 640)); // small device width
      await tester.pumpAndSettle();

      final systemDefaultTextFinder = find.text('System default');
      expect(systemDefaultTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(systemDefaultTextFinder);
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.softWrap, isFalse);

      // Ensure that there is NO split text like "System\ndefault"
      expect(find.text('System\ndefault'), findsNothing);

      final renderBox =
          tester.renderObject(systemDefaultTextFinder) as RenderBox;
      // Single line text height is typically <= 24px
      expect(renderBox.size.height, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets('language selection updates state smoothly', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    // Default is English
    expect(controller.selected.value, equals(LocalizationService.english));

    // Tap Khmer option
    final khmerOption = find.text('ភាសាខ្មែរ');
    await tester.ensureVisible(khmerOption);
    await tester.runAsync(() async {
      await tester.tap(khmerOption);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(controller.selected.value, equals(LocalizationService.khmer));
    verify(() => localStorage.saveLanguage(LocalizationService.khmer)).called(1);

    // Tap English option
    final englishOption = find.text('English').first;
    await tester.ensureVisible(englishOption);
    await tester.runAsync(() async {
      await tester.tap(englishOption);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(controller.selected.value, equals(LocalizationService.english));
    verify(() => localStorage.saveLanguage(LocalizationService.english)).called(1);
  });

  testWidgets('appearance theme selection updates ThemeController', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    // Tap Dark option
    final darkOption = find.text('Dark');
    await tester.ensureVisible(darkOption);
    await tester.runAsync(() async {
      await tester.tap(darkOption);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(controller.selectedTheme.value, equals(ThemeMode.dark));
    expect(themeController.themeMode.value, equals(ThemeMode.dark));

    // Tap Light option
    final lightOption = find.text('Light');
    await tester.ensureVisible(lightOption);
    await tester.runAsync(() async {
      await tester.tap(lightOption);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(controller.selectedTheme.value, equals(ThemeMode.light));
    expect(themeController.themeMode.value, equals(ThemeMode.light));

    // Tap System default option
    final systemOption = find.text('System default');
    await tester.ensureVisible(systemOption);
    await tester.runAsync(() async {
      await tester.tap(systemOption);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(controller.selectedTheme.value, equals(ThemeMode.system));
    expect(themeController.themeMode.value, equals(ThemeMode.system));
  });

  testWidgets('back button navigates to welcome screen', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    final backButton = find.byType(AppBackButton);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('welcome route'), findsOneWidget);
  });

  testWidgets('continue button navigates to completion screen', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(continueButton, findsOneWidget);
    await tester.ensureVisible(continueButton);

    await tester.runAsync(() async {
      await tester.tap(continueButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('completion route'), findsOneWidget);
  });

  testWidgets('renders cleanly in dark mode without overflow', (tester) async {
    await pumpScreen(tester, brightness: Brightness.dark);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectScreen), findsOneWidget);
    expect(find.text('Personalize'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly on small device (360x600) without overflow', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(360, 600));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectScreen), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly in Khmer locale', (tester) async {
    await pumpScreen(
      tester,
      locale: LocalizationService.khmerLocale,
    );
    await tester.pumpAndSettle();

    // Khmer title
    expect(find.text('កំណត់ផ្ទាល់ខ្លួន'), findsOneWidget);
    expect(find.text('បទពិសោធន៍របស់អ្នក'), findsOneWidget);

    // Khmer step
    expect(find.text('ជំហានទី ២ ក្នុងចំណោម ៣'), findsOneWidget);

    // Khmer language section
    expect(find.text('ភាសា'), findsOneWidget);
    expect(find.text('ជ្រើសរើសភាសាដែលអ្នកពេញចិត្ត។'), findsOneWidget);

    // Khmer appearance section
    expect(find.text('រូបរាង'), findsOneWidget);
    expect(find.text('ជ្រើសរើសផ្ទាំងពណ៌ដែលស័ក្តិសមនឹងអ្នក។'), findsOneWidget);
    expect(find.text('ពន្លឺ'), findsOneWidget);
    expect(find.text('ងងឹត'), findsOneWidget);
    expect(find.text('តាមប្រព័ន្ធ'), findsOneWidget);

    // Khmer continue
    expect(find.text('បន្ត'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion when disableAnimations is enabled', (
    tester,
  ) async {
    await pumpScreen(tester, disableAnimations: true);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectScreen), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
