import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  Widget createNavBar({
    int currentIndex = 0,
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
    ValueChanged<int>? onTap,
    VoidCallback? onCenterTap,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: LocalizationService.englishLocale,
      theme: theme ?? AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: onTap ?? (_) {},
          onCenterTap: onCenterTap,
        ),
      ),
    );
  }

  testWidgets('center action uses the localized semantic label in Khmer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      createNavBar(locale: LocalizationService.khmerLocale),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('បង្កើត'), findsOneWidget);
    expect(find.bySemanticsLabel('Create'), findsNothing);
    semantics.dispose();
  });

  testWidgets('center action uses the localized semantic label in English', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      createNavBar(locale: LocalizationService.englishLocale),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Create'), findsOneWidget);
    expect(find.bySemanticsLabel('បង្កើត'), findsNothing);
    semantics.dispose();
  });

  testWidgets('navigation renders labels and preserves semantic labels in English', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      createNavBar(locale: LocalizationService.englishLocale),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('LevelUp'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('LevelUp'), findsOneWidget);
    expect(find.bySemanticsLabel('Finance'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('navigation renders labels and preserves semantic labels in Khmer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      createNavBar(locale: LocalizationService.khmerLocale),
    );
    await tester.pumpAndSettle();

    expect(find.text('ទំព័រដើម'), findsOneWidget);
    expect(find.text('ឡើងកម្រិត'), findsOneWidget);
    expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
    expect(find.text('ប្រវត្តិរូប'), findsOneWidget);

    expect(find.bySemanticsLabel('ទំព័រដើម'), findsOneWidget);
    expect(find.bySemanticsLabel('ឡើងកម្រិត'), findsOneWidget);
    expect(find.bySemanticsLabel('ហិរញ្ញវត្ថុ'), findsOneWidget);
    expect(find.bySemanticsLabel('ប្រវត្តិរូប'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('LevelUp navigation tab uses Trophy icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      createNavBar(currentIndex: 0),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

    await tester.pumpWidget(
      createNavBar(currentIndex: 1),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
  });

  testWidgets('Finance navigation tab uses Dollar sign in circle icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      createNavBar(currentIndex: 0),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.paid_outlined), findsOneWidget);

    await tester.pumpWidget(
      createNavBar(currentIndex: 2),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.paid_rounded), findsOneWidget);
  });

  testWidgets('tapping each navigation tab triggers onTap with expected index', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    int? selectedIndex;

    await tester.pumpWidget(
      createNavBar(
        currentIndex: 0,
        onTap: (index) => selectedIndex = index,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('LevelUp'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);

    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 0);

    semantics.dispose();
  });

  testWidgets('tapping center button triggers onCenterTap callback', (
    tester,
  ) async {
    bool centerTapped = false;

    await tester.pumpWidget(
      createNavBar(
        currentIndex: 0,
        onCenterTap: () => centerTapped = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(centerTapped, isTrue);
  });

  testWidgets('renders properly in Light and Dark mode without errors', (
    tester,
  ) async {
    await tester.pumpWidget(createNavBar(theme: AppTheme.light));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavBar), findsOneWidget);

    await tester.pumpWidget(createNavBar(theme: AppTheme.dark));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavBar), findsOneWidget);
  });

  testWidgets('responsive layout on widths 320, 360, 390, 412, 430 without overflow', (
    tester,
  ) async {
    const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

    for (final width in widths) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createNavBar(currentIndex: 1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at width $width');
      expect(find.byType(BottomNavBar), findsOneWidget);
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('sequential tab switching preserves stability: Home -> LevelUp -> Home -> Finance -> Profile -> Home, then Create', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    int activeIndex = 0;
    bool createTapped = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return GetMaterialApp(
            translations: AppTranslations(),
            locale: LocalizationService.englishLocale,
            fallbackLocale: LocalizationService.englishLocale,
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(child: Text('Active Tab: $activeIndex')),
              bottomNavigationBar: BottomNavBar(
                currentIndex: activeIndex,
                onTap: (idx) => setState(() => activeIndex = idx),
                onCenterTap: () => createTapped = true,
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final navBarFinder = find.byType(BottomNavBar);
    final initialRect = tester.getRect(navBarFinder);

    await tester.tap(find.bySemanticsLabel('LevelUp'));
    await tester.pumpAndSettle();
    expect(activeIndex, 1);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(activeIndex, 0);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pumpAndSettle();
    expect(activeIndex, 2);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    expect(activeIndex, 3);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(activeIndex, 0);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(createTapped, isTrue);
    expect(tester.getRect(navBarFinder), equals(initialRect));

    semantics.dispose();
  });

  testWidgets('verifies all required transitions: Home->LevelUp, LevelUp->Finance, Finance->Profile, Profile->Finance, Finance->LevelUp, LevelUp->Home, Home->Finance, Profile->Home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    int activeIndex = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return GetMaterialApp(
            translations: AppTranslations(),
            locale: LocalizationService.englishLocale,
            fallbackLocale: LocalizationService.englishLocale,
            theme: AppTheme.dark,
            home: Scaffold(
              bottomNavigationBar: BottomNavBar(
                currentIndex: activeIndex,
                onTap: (idx) => setState(() => activeIndex = idx),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // 1. Home (Inbox) -> LevelUp (Timeline) (0 -> 1)
    await tester.tap(find.bySemanticsLabel('LevelUp'));
    await tester.pumpAndSettle();
    expect(activeIndex, 1);

    // 2. LevelUp (Timeline) -> Finance (AI) (1 -> 2)
    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pumpAndSettle();
    expect(activeIndex, 2);

    // 3. Finance (AI) -> Profile (Settings) (2 -> 3)
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    expect(activeIndex, 3);

    // 4. Profile (Settings) -> Finance (AI) (3 -> 2)
    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pumpAndSettle();
    expect(activeIndex, 2);

    // 5. Finance (AI) -> LevelUp (Timeline) (2 -> 1)
    await tester.tap(find.bySemanticsLabel('LevelUp'));
    await tester.pumpAndSettle();
    expect(activeIndex, 1);

    // 6. LevelUp (Timeline) -> Home (Inbox) (1 -> 0)
    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(activeIndex, 0);

    // 7. Home (Inbox) -> Finance (AI) (0 -> 2)
    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pumpAndSettle();
    expect(activeIndex, 2);

    // 8. Profile (Settings) -> Home (Inbox) (3 -> 0)
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(activeIndex, 0);

    semantics.dispose();
  });

  testWidgets('verifies continuous active glass capsule movement and dynamic icon transitions across user requested sequences', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    int activeIndex = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return GetMaterialApp(
            translations: AppTranslations(),
            locale: LocalizationService.englishLocale,
            fallbackLocale: LocalizationService.englishLocale,
            theme: AppTheme.dark,
            home: Scaffold(
              bottomNavigationBar: BottomNavBar(
                currentIndex: activeIndex,
                onTap: (idx) => setState(() => activeIndex = idx),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Sequence 1: Home → LevelUp (0 → 1)
    await tester.tap(find.bySemanticsLabel('LevelUp'));
    // Advance halfway through the 340ms ease-out spring
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

    // Sequence 2: LevelUp → Finance (1 → 2)
    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.paid_rounded), findsOneWidget);

    // Sequence 3: Finance → Profile (2 → 3)
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Sequence 4: Profile → Home (3 → 0)
    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    // Sequence 5: Home → Finance (0 → 2) - Multi-slot jump across LevelUp
    await tester.tap(find.bySemanticsLabel('Finance'));
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.paid_rounded), findsOneWidget);

    // Sequence 6: Profile → LevelUp (via setting active to 3 then tapping LevelUp)
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    expect(activeIndex, 3);

    await tester.tap(find.bySemanticsLabel('LevelUp'));
    await tester.pump(const Duration(milliseconds: 140));
    expect(activeIndex, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

    semantics.dispose();
  });
}

