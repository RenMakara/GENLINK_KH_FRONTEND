import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/onboarding/presentation/controllers/completion_controller.dart';
import 'package:genlink_frontend/features/onboarding/presentation/screens/completion_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLocalStorage localStorage;
  late CompletionController controller;

  setUp(() {
    Get.reset();
    Get.locale = const Locale('en', 'US');

    localStorage = _MockLocalStorage();
    when(() => localStorage.markInitialPreferencesSeen())
        .thenAnswer((_) async {});
    when(() => localStorage.markOnboardingSeen())
        .thenAnswer((_) async {});

    controller = CompletionController(localStorage: localStorage);

    Get
      ..testMode = true
      ..put<CompletionController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.light,
    bool animate = true,
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
            name: AppRoutes.completion,
            page: () => CompletionScreen(animate: animate),
          ),
          GetPage(
            name: AppRoutes.languageSelect,
            page: () => const Scaffold(body: Text('language select route')),
          ),
          GetPage(
            name: AppRoutes.authChoice,
            page: () => const Scaffold(body: Text('auth choice route')),
          ),
        ],
        home: CompletionScreen(animate: animate),
      ),
    );
  }

  testWidgets(
    'renders all header, celebration visual, bottom info card, and CTA button',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      // Top bar & Progress
      expect(find.byType(CompletionScreen), findsOneWidget);
      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.text('Step 3 of 3'), findsOneWidget);

      // Title & Subtitle
      expect(find.text("You're"), findsOneWidget);
      expect(find.text('all set!'), findsOneWidget);
      expect(
        find.text("Let's build a brighter future together on GenLink."),
        findsOneWidget,
      );

      // Celebration Feature Badges
      expect(find.text('Learn'), findsNWidgets(2)); // Badge & bottom card pillar
      expect(find.text('Grow'), findsNWidgets(2)); // Badge & bottom card pillar
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Together'), findsOneWidget);

      // Bottom Info Card
      expect(find.text('More opportunities ahead'), findsOneWidget);
      expect(find.text('Learn. Connect. Grow. Together.'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Real opportunities'), findsOneWidget);
      expect(find.text('Practical knowledge'), findsOneWidget);
      expect(find.text('Meaningful connections'), findsOneWidget);

      // CTA Button
      expect(find.text('Go to GenLink'), findsOneWidget);

      // VERIFY: Go to GenLink has NO arrow icon
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    },
  );

  testWidgets('back button navigates back to Step 2 (languageSelect)', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    final backButton = find.byType(AppBackButton);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('language select route'), findsOneWidget);
  });

  testWidgets('Go to GenLink button completes onboarding and navigates to auth', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    final ctaButton = find.widgetWithText(FilledButton, 'Go to GenLink');
    expect(ctaButton, findsOneWidget);

    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    verify(() => localStorage.markInitialPreferencesSeen()).called(1);
    verify(() => localStorage.markOnboardingSeen()).called(1);
    expect(find.text('auth choice route'), findsOneWidget);
  });

  testWidgets('renders cleanly in dark mode with white button and dark text', (
    tester,
  ) async {
    await pumpScreen(tester, brightness: Brightness.dark);
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text("You're"), findsOneWidget);
    expect(find.text('all set!'), findsOneWidget);

    final ctaButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cta_button')),
    );
    // Dark mode button MUST be Clean White (#FFFFFF)
    expect(
      ctaButton.style?.backgroundColor?.resolve({}),
      Colors.white,
    );
    expect(
      ctaButton.style?.foregroundColor?.resolve({}),
      const Color(0xFF0F172A),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in light mode with Dark Navy (#0F172A) button and white text', (
    tester,
  ) async {
    await pumpScreen(tester, brightness: Brightness.light);
    await tester.pumpAndSettle();

    final ctaButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cta_button')),
    );
    // Light mode button MUST be Dark Navy (#0F172A)
    expect(
      ctaButton.style?.backgroundColor?.resolve({}),
      const Color(0xFF0F172A),
    );
    expect(
      ctaButton.style?.foregroundColor?.resolve({}),
      Colors.white,
    );
  });

  testWidgets('renders cleanly on small device (360x600) without overflow', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(360, 600));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text('Go to GenLink'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly on standard iPhone (390x844)', (tester) async {
    await pumpScreen(tester, size: const Size(390, 844));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text('Go to GenLink'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly in Khmer locale', (tester) async {
    await pumpScreen(
      tester,
      locale: LocalizationService.khmerLocale,
    );
    await tester.pumpAndSettle();

    // Khmer title
    expect(find.text('រួចរាល់'), findsOneWidget);
    expect(find.text('ហើយ!'), findsOneWidget);

    // Khmer step
    expect(find.text('ជំហានទី ៣ ក្នុងចំណោម ៣'), findsOneWidget);

    // Khmer body
    expect(
      find.text('តោះបង្កើតអនាគតដ៏ភ្លឺស្វាងជាមួយគ្នា នៅលើ GenLink'),
      findsOneWidget,
    );

    // Khmer badges
    expect(find.text('រៀន'), findsNWidgets(2));
    expect(find.text('រីកចម្រើន'), findsNWidgets(2));
    expect(find.text('ភ្ជាប់ទំនាក់ទំនង'), findsOneWidget);
    expect(find.text('រួមគ្នា'), findsOneWidget);

    // Khmer bottom info card
    expect(find.text('ឱកាសកាន់តែច្រើននៅខាងមុខ'), findsOneWidget);
    expect(
      find.text('រៀន · ភ្ជាប់ទំនាក់ទំនង · រីកចម្រើន · រួមគ្នា'),
      findsOneWidget,
    );
    expect(find.text('ស្វែងរក'), findsOneWidget);

    // Khmer CTA
    expect(find.text('ចូលទៅ GenLink'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion when animate is false', (tester) async {
    await pumpScreen(tester, animate: false);
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text('Go to GenLink'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion when disableAnimations is enabled', (
    tester,
  ) async {
    await pumpScreen(tester, disableAnimations: true);
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text('Go to GenLink'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'layout verification: NO badge overlaps central logo or other badges, with clear margins',
    (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pumpAndSettle();

      final logoRect =
          tester.getRect(find.byKey(const ValueKey('central_logo_plate')));
      final learnRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_learn')));
      final growRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_grow')));
      final connectRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_connect')));
      final togetherRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_together')));
      final infoCardRect =
          tester.getRect(find.byKey(const ValueKey('bottom_info_card')));
      final ctaRect =
          tester.getRect(find.byKey(const ValueKey('cta_button')));

      // 1. None of the 4 badges overlap the central GenLink logo card
      expect(learnRect.overlaps(logoRect), isFalse,
          reason: 'Learn card must not overlap central logo');
      expect(growRect.overlaps(logoRect), isFalse,
          reason: 'Grow card must not overlap central logo');
      expect(connectRect.overlaps(logoRect), isFalse,
          reason: 'Connect card must not overlap central logo');
      expect(togetherRect.overlaps(logoRect), isFalse,
          reason: 'Together card must not overlap central logo');

      // 2. Clear horizontal gap around central logo is >= 16px (requirement: 16-24px)
      expect(logoRect.left - learnRect.right, greaterThanOrEqualTo(16.0),
          reason: 'Clear gap between Learn and Logo must be >= 16px');
      expect(logoRect.left - connectRect.right, greaterThanOrEqualTo(16.0),
          reason: 'Clear gap between Connect and Logo must be >= 16px');
      expect(growRect.left - logoRect.right, greaterThanOrEqualTo(16.0),
          reason: 'Clear gap between Logo and Grow must be >= 16px');
      expect(togetherRect.left - logoRect.right, greaterThanOrEqualTo(16.0),
          reason: 'Clear gap between Logo and Together must be >= 16px');

      // 3. None of the badges overlap each other
      expect(learnRect.overlaps(growRect), isFalse);
      expect(learnRect.overlaps(connectRect), isFalse);
      expect(learnRect.overlaps(togetherRect), isFalse);
      expect(growRect.overlaps(connectRect), isFalse);
      expect(growRect.overlaps(togetherRect), isFalse);
      expect(connectRect.overlaps(togetherRect), isFalse);

      // 4. Hero visual finishes before bottom information card begins
      expect(infoCardRect.top - connectRect.bottom, greaterThanOrEqualTo(14.0),
          reason: 'Info card must not overlap bottom-left Connect badge');
      expect(infoCardRect.top - togetherRect.bottom, greaterThanOrEqualTo(14.0),
          reason: 'Info card must not overlap bottom-right Together badge');
      expect(infoCardRect.top - logoRect.bottom, greaterThanOrEqualTo(14.0),
          reason: 'Info card must not overlap central logo');

      // 5. Breathing room between bottom information card and CTA (requirement: 16-20px)
      expect(ctaRect.top - infoCardRect.bottom, greaterThanOrEqualTo(14.0),
          reason: 'CTA button must not collide with information card');
    },
  );

  testWidgets('layout adapts across small (360x640) and large (428x926) screens without collision', (
    tester,
  ) async {
    for (final size in [const Size(360, 640), const Size(428, 926)]) {
      await pumpScreen(tester, size: size);
      await tester.pumpAndSettle();

      final logoRect =
          tester.getRect(find.byKey(const ValueKey('central_logo_plate')));
      final learnRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_learn')));
      final growRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_grow')));
      final connectRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_connect')));
      final togetherRect =
          tester.getRect(find.byKey(const ValueKey('feature_badge_together')));
      final infoCardRect =
          tester.getRect(find.byKey(const ValueKey('bottom_info_card')));
      final ctaRect =
          tester.getRect(find.byKey(const ValueKey('cta_button')));

      expect(learnRect.overlaps(logoRect), isFalse);
      expect(growRect.overlaps(logoRect), isFalse);
      expect(connectRect.overlaps(logoRect), isFalse);
      expect(togetherRect.overlaps(logoRect), isFalse);

      expect(logoRect.left - learnRect.right, greaterThanOrEqualTo(16.0));
      expect(growRect.left - logoRect.right, greaterThanOrEqualTo(16.0));
      expect(infoCardRect.top - connectRect.bottom, greaterThanOrEqualTo(12.0));
      expect(infoCardRect.top - togetherRect.bottom, greaterThanOrEqualTo(12.0));
      expect(ctaRect.top - infoCardRect.bottom, greaterThanOrEqualTo(12.0));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('animations do not create collision states at intermediate progress', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(390, 844));

    // Test intermediate frames during entrance animation
    for (int ms = 200; ms <= 1200; ms += 200) {
      await tester.pump(const Duration(milliseconds: 200));

      final logoFinder = find.byKey(const ValueKey('central_logo_plate'));
      final learnFinder = find.byKey(const ValueKey('feature_badge_learn'));
      final growFinder = find.byKey(const ValueKey('feature_badge_grow'));
      final connectFinder = find.byKey(const ValueKey('feature_badge_connect'));
      final togetherFinder = find.byKey(const ValueKey('feature_badge_together'));

      if (logoFinder.evaluate().isNotEmpty && learnFinder.evaluate().isNotEmpty) {
        final logoRect = tester.getRect(logoFinder);
        final learnRect = tester.getRect(learnFinder);
        final growRect = tester.getRect(growFinder);
        final connectRect = tester.getRect(connectFinder);
        final togetherRect = tester.getRect(togetherFinder);

        expect(learnRect.overlaps(logoRect), isFalse);
        expect(growRect.overlaps(logoRect), isFalse);
        expect(connectRect.overlaps(logoRect), isFalse);
        expect(togetherRect.overlaps(logoRect), isFalse);
      }
    }
    await tester.pumpAndSettle();
  });
}
