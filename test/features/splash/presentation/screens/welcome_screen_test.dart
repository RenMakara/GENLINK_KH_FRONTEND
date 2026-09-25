import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/splash/presentation/controllers/welcome_controller.dart';
import 'package:genlink_frontend/features/splash/presentation/screens/welcome_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLocalStorage localStorage;
  late WelcomeController controller;

  setUp(() {
    localStorage = _MockLocalStorage();
    when(() => localStorage.markInitialPreferencesSeen())
        .thenAnswer((_) async {});
    when(() => localStorage.markOnboardingSeen()).thenAnswer((_) async {});

    controller = WelcomeController(localStorage: localStorage);
    Get
      ..testMode = true
      ..put<WelcomeController>(controller);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        getPages: [
          GetPage(name: AppRoutes.welcome, page: () => const WelcomeScreen()),
          GetPage(
            name: AppRoutes.languageSelect,
            page: () => const Scaffold(body: Text('language select route')),
          ),
          GetPage(
            name: AppRoutes.authChoice,
            page: () => const Scaffold(body: Text('auth choice route')),
          ),
        ],
        home: const WelcomeScreen(),
      ),
    );
  }

  testWidgets('renders all onboarding elements and completes entrance animation', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Initial frame
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Progress through entrance animation (800ms)
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    // Logo & branding
    expect(find.text('Same opportunities.\nBrighter tomorrows.'), findsOneWidget);

    // Illustration asset
    expect(
      find.bySemanticsLabel('GenLink students and Angkor Wat illustration'),
      findsOneWidget,
    );

    // Buttons & indicators
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);

    // Feature badges
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Grow'), findsOneWidget);
    expect(find.text('Together'), findsOneWidget);

    // Decorative paper plane calligraphy
    expect(find.text('Connect.\nLearn.\nGrow.\nTogether.'), findsOneWidget);

    // Bottom card content
    expect(find.text('A brighter future\nstarts with you'), findsOneWidget);
    expect(
      find.text(
        'Join a community, explore opportunities,\nand build the best version of yourself.',
      ),
      findsOneWidget,
    );

    // Verify Get started button has NO arrow icon
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
  });

  testWidgets('Get started button triggers navigation to language select', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 900));

    final getStartedButton = find.widgetWithText(FilledButton, 'Get started');
    expect(getStartedButton, findsOneWidget);

    await tester.tap(getStartedButton);
    await tester.pumpAndSettle();

    expect(find.text('language select route'), findsOneWidget);
  });

  testWidgets('Skip button marks onboarding seen and navigates to auth choice', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 900));

    final skipButton = find.widgetWithText(TextButton, 'Skip for now');
    expect(skipButton, findsOneWidget);

    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    verify(() => localStorage.markInitialPreferencesSeen()).called(1);
    verify(() => localStorage.markOnboardingSeen()).called(1);
    expect(find.text('auth choice route'), findsOneWidget);
  });

  testWidgets('renders properly in compact layout without overflowing', (
    tester,
  ) async {
    // Compact device height: 600px
    await pumpScreen(tester, size: const Size(360, 600));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion when disableAnimations is enabled', (
    tester,
  ) async {
    await pumpScreen(tester, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly in Khmer locale', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.khmerLocale,
        fallbackLocale: LocalizationService.khmerLocale,
        theme: AppTheme.lightFor('km'),
        getPages: [
          GetPage(name: AppRoutes.welcome, page: () => const WelcomeScreen()),
        ],
        home: const WelcomeScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));

    // Khmer headline
    expect(find.text('ឱកាសដូចគ្នា\nថ្ងៃស្អែកកាន់តែភ្លឺស្វាង'), findsOneWidget);

    // Khmer feature badges
    expect(find.text('រៀន'), findsOneWidget);
    expect(find.text('ភ្ជាប់ទំនាក់ទំនង'), findsOneWidget);
    expect(find.text('រីកចម្រើន'), findsOneWidget);
    expect(find.text('រួមគ្នា'), findsOneWidget);

    // Khmer bottom card
    expect(find.text('អនាគតកាន់តែភ្លឺស្វាង\nចាប់ផ្តើមពីអ្នក'), findsOneWidget);
    expect(find.text('ចាប់ផ្តើម'), findsOneWidget);
    expect(find.text('រំលងសិន'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all 4 feature cards have identical square dimensions and bottom card has margins',
    (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump(const Duration(milliseconds: 900));

      final learnFinder = find.ancestor(
        of: find.text('Learn'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.hasBoundedWidth == true &&
              w.constraints?.maxWidth == w.constraints?.maxHeight,
        ),
      );
      final connectFinder = find.ancestor(
        of: find.text('Connect'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.hasBoundedWidth == true &&
              w.constraints?.maxWidth == w.constraints?.maxHeight,
        ),
      );
      final growFinder = find.ancestor(
        of: find.text('Grow'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.hasBoundedWidth == true &&
              w.constraints?.maxWidth == w.constraints?.maxHeight,
        ),
      );
      final togetherFinder = find.ancestor(
        of: find.text('Together'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.hasBoundedWidth == true &&
              w.constraints?.maxWidth == w.constraints?.maxHeight,
        ),
      );

      expect(learnFinder, findsOneWidget);
      expect(connectFinder, findsOneWidget);
      expect(growFinder, findsOneWidget);
      expect(togetherFinder, findsOneWidget);

      final learnSize = tester.getSize(learnFinder);
      final connectSize = tester.getSize(connectFinder);
      final growSize = tester.getSize(growFinder);
      final togetherSize = tester.getSize(togetherFinder);

      // Verify all 4 cards are square and identical in size
      expect(learnSize.width, equals(learnSize.height));
      expect(learnSize, equals(connectSize));
      expect(learnSize, equals(growSize));
      expect(learnSize, equals(togetherSize));
      expect(learnSize.width, inInclusiveRange(84.0, 96.0));

      // Verify bottom card container has margins and is compact
      final bottomCardFinder = find.ancestor(
        of: find.text('Get started'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(28),
        ),
      );
      expect(bottomCardFinder, findsOneWidget);

      final cardRect = tester.getRect(bottomCardFinder);
      expect(cardRect.left, equals(24.0));
      expect(390.0 - cardRect.right, equals(24.0));
      expect(cardRect.height, lessThan(320.0));

      // Verify button is inside bottom card
      final buttonFinder = find.widgetWithText(FilledButton, 'Get started');
      final buttonRect = tester.getRect(buttonFinder);
      expect(cardRect.contains(buttonRect.center), isTrue);
    },
  );

  testWidgets(
    'feature cards remain uniform and equal on small and large screens',
    (tester) async {
      for (final size in const [Size(360, 640), Size(412, 915)]) {
        await pumpScreen(tester, size: size);
        await tester.pump(const Duration(milliseconds: 900));

        final learnFinder = find.ancestor(
          of: find.text('Learn'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.hasBoundedWidth == true &&
                w.constraints?.maxWidth == w.constraints?.maxHeight,
          ),
        );
        final togetherFinder = find.ancestor(
          of: find.text('Together'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.hasBoundedWidth == true &&
                w.constraints?.maxWidth == w.constraints?.maxHeight,
          ),
        );

        final learnSize = tester.getSize(learnFinder);
        final togetherSize = tester.getSize(togetherFinder);

        expect(learnSize.width, equals(learnSize.height));
        expect(togetherSize.width, equals(togetherSize.height));
        expect(learnSize, equals(togetherSize));
        expect(learnSize.width, inInclusiveRange(84.0, 96.0));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
