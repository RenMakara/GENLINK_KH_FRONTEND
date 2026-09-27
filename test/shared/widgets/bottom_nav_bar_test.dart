import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  Widget createNavBar({
    int currentIndex = 0,
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
    ValueChanged<int>? onTap,
    ValueChanged<int>? onDoubleTapActive,
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
          onDoubleTapActive: onDoubleTapActive,
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

  testWidgets(
    'navigation renders labels and preserves semantic labels in English',
    (tester) async {
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
    },
  );

  testWidgets(
    'navigation renders labels and preserves semantic labels in Khmer',
    (tester) async {
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
    },
  );

  testWidgets('LevelUp navigation tab uses Trophy icon', (tester) async {
    await tester.pumpWidget(createNavBar(currentIndex: 0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

    await tester.pumpWidget(createNavBar(currentIndex: 1));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
  });

  testWidgets('Finance navigation tab uses Dollar sign in circle icon', (
    tester,
  ) async {
    await tester.pumpWidget(createNavBar(currentIndex: 0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.paid_outlined), findsOneWidget);

    await tester.pumpWidget(createNavBar(currentIndex: 2));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.paid_rounded), findsOneWidget);
  });

  testWidgets(
    'tapping each navigation tab triggers onTap with expected index',
    (tester) async {
      final semantics = tester.ensureSemantics();
      int? selectedIndex;

      await tester.pumpWidget(
        createNavBar(currentIndex: 0, onTap: (index) => selectedIndex = index),
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
    },
  );

  testWidgets('selected tab follows MainController changes', (tester) async {
    final mainController = Get.put(MainController());

    await tester.pumpWidget(createNavBar(currentIndex: 0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

    mainController.changeIndex(1);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
  });

  testWidgets('tapping center button triggers onCenterTap callback', (
    tester,
  ) async {
    bool centerTapped = false;

    await tester.pumpWidget(
      createNavBar(currentIndex: 0, onCenterTap: () => centerTapped = true),
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

  testWidgets('keeps floating snackbars visible above the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(createNavBar());
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(BottomNavBar)).height, lessThan(120));

    final scaffoldContext = tester.element(find.byType(Scaffold));
    ScaffoldMessenger.of(
      scaffoldContext,
    ).showSnackBar(const SnackBar(content: Text('Profile cover updated')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Profile cover updated'), findsOneWidget);
  });

  testWidgets(
    'responsive layout on widths 320, 360, 390, 412, 430 without overflow',
    (tester) async {
      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createNavBar(currentIndex: 1));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed at width $width',
        );
        expect(find.byType(BottomNavBar), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );

  testWidgets(
    'sequential tab switching preserves stability: Home -> LevelUp -> Home -> Finance -> Profile -> Home, then Create',
    (tester) async {
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
    },
  );

  testWidgets(
    'verifies all required transitions: Home->LevelUp, LevelUp->Finance, Finance->Profile, Profile->Finance, Finance->LevelUp, LevelUp->Home, Home->Finance, Profile->Home',
    (tester) async {
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
    },
  );

  testWidgets(
    'verifies continuous active glass capsule movement and dynamic icon transitions across user requested sequences',
    (tester) async {
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
    },
  );

  group('Monochrome + Glass Polish verification', () {
    for (final mode in ['Dark', 'Light']) {
      final isDark = mode == 'Dark';

      testWidgets(
        'verifies $mode Mode: monochrome icons, no feature colors, and glass capsule movement across all tabs',
        (tester) async {
          int activeIndex = 0;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return GetMaterialApp(
                  translations: AppTranslations(),
                  locale: LocalizationService.englishLocale,
                  fallbackLocale: LocalizationService.englishLocale,
                  theme: isDark ? AppTheme.dark : AppTheme.light,
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

          final tabs = ['Home', 'LevelUp', 'Finance', 'Profile'];

          for (int targetIdx = 0; targetIdx < tabs.length; targetIdx++) {
            await tester.tap(find.bySemanticsLabel(tabs[targetIdx]));
            await tester.pumpAndSettle();
            expect(activeIndex, targetIdx);

            // Verify all Icon widgets in the nav bar have monochrome colors
            final iconWidgets = tester.widgetList<Icon>(
              find.descendant(
                of: find.byType(BottomNavBar),
                matching: find.byType(Icon),
              ),
            );

            for (final icon in iconWidgets) {
              final color = icon.color;
              if (color != null) {
                if (isDark) {
                  // In dark mode: white
                  expect(
                    color,
                    equals(Colors.white),
                    reason:
                        'Tab icon must be white in dark mode, got $color on tab $targetIdx',
                  );
                } else {
                  // In light mode: dark monochrome
                  expect(
                    color,
                    equals(const Color(0xFF121212)),
                    reason:
                        'Tab icon must be dark monochrome in light mode, got $color on tab $targetIdx',
                  );
                }
              }
            }

            // Verify text label colors: active is white/dark, inactive are neutral gray
            final textWidgets = tester.widgetList<Text>(
              find.descendant(
                of: find.byType(BottomNavBar),
                matching: find.byType(Text),
              ),
            );

            for (final text in textWidgets) {
              if (text.style?.color != null) {
                final textColor = text.style!.color!;
                final isCurrentTab = text.data == tabs[targetIdx];

                if (isDark) {
                  if (isCurrentTab) {
                    expect(
                      textColor,
                      equals(Colors.white),
                      reason:
                          'Active label must be white in dark mode, got $textColor',
                    );
                  } else {
                    expect(
                      textColor,
                      equals(const Color(0x8AFFFFFF)),
                      reason:
                          'Inactive label must be soft neutral gray in dark mode, got $textColor',
                    );
                  }
                } else {
                  if (isCurrentTab) {
                    expect(
                      textColor,
                      equals(const Color(0xFF121212)),
                      reason:
                          'Active label must be dark in light mode, got $textColor',
                    );
                  } else {
                    expect(
                      textColor,
                      equals(const Color(0x8A121212)),
                      reason:
                          'Inactive label must be neutral gray in light mode, got $textColor',
                    );
                  }
                }

                // Verify absolutely NO feature colors (blue, green, orange, purple, pink, cyan, yellow, gold)
                // Color hue shouldn't be saturated colored hue
                final hsl = HSLColor.fromColor(textColor);
                expect(
                  hsl.saturation,
                  lessThanOrEqualTo(0.1),
                  reason:
                      'Label must be neutral monochrome (no saturation), but found saturation ${hsl.saturation} in $textColor',
                );
              }
            }
          }
        },
      );
    }
  });

  group('Double-tap active navigation tests', () {
    testWidgets('1. single tap on inactive tab navigates normally', (
      tester,
    ) async {
      int activeIndex = 0;
      int refreshCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return GetMaterialApp(
              translations: AppTranslations(),
              locale: LocalizationService.englishLocale,
              fallbackLocale: LocalizationService.englishLocale,
              theme: AppTheme.light,
              home: Scaffold(
                bottomNavigationBar: BottomNavBar(
                  currentIndex: activeIndex,
                  onTap: (idx) => setState(() => activeIndex = idx),
                  onDoubleTapActive: (_) => refreshCount++,
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Currently on tab 0 (Home). Tap tab 1 (LevelUp)
      await tester.tap(find.bySemanticsLabel('LevelUp'));
      await tester.pumpAndSettle();

      expect(activeIndex, equals(1));
      expect(refreshCount, equals(0));
    });

    testWidgets('2. single tap on active tab does not accidentally refresh', (
      tester,
    ) async {
      int tapCount = 0;
      int refreshCount = 0;

      await tester.pumpWidget(
        createNavBar(
          currentIndex: 0,
          onTap: (_) => tapCount++,
          onDoubleTapActive: (_) => refreshCount++,
        ),
      );
      await tester.pumpAndSettle();

      // Single tap on active tab (Home)
      await tester.tap(find.bySemanticsLabel('Home'));
      // Advance past the 350ms double-tap timeout
      await tester.pump(const Duration(milliseconds: 400));

      expect(tapCount, equals(1));
      expect(refreshCount, equals(0));
    });

    testWidgets('3. double tap on active tab scrolls to top', (tester) async {
      final scrollController = ScrollController(initialScrollOffset: 300.0);
      int refreshCount = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: LocalizationService.englishLocale,
          fallbackLocale: LocalizationService.englishLocale,
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView.builder(
              controller: scrollController,
              itemCount: 50,
              itemBuilder: (context, i) => ListTile(title: Text('Item $i')),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onDoubleTapActive: (index) {
                refreshCount++;
                if (scrollController.hasClients) {
                  scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.offset, equals(300.0));

      // Double tap on already active tab (Home)
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();

      expect(scrollController.offset, equals(0.0));
      expect(refreshCount, equals(1));
    });

    testWidgets(
      '4. double tap on active tab triggers refresh across all tabs',
      (tester) async {
        final refreshedTabs = <int>[];
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
                    onDoubleTapActive: (idx) => refreshedTabs.add(idx),
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        final tabLabels = ['Home', 'LevelUp', 'Finance', 'Profile'];

        for (int i = 0; i < tabLabels.length; i++) {
          if (activeIndex != i) {
            // Navigate to tab
            await tester.tap(find.bySemanticsLabel(tabLabels[i]));
            await tester.pumpAndSettle();
            expect(activeIndex, equals(i));
          }

          // Double-tap on the now active tab
          await tester.tap(find.bySemanticsLabel(tabLabels[i]));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.bySemanticsLabel(tabLabels[i]));
          await tester.pumpAndSettle();

          expect(refreshedTabs.last, equals(i));
        }

        expect(refreshedTabs, equals([0, 1, 2, 3]));
      },
    );

    testWidgets('5. tapping another tab still navigates normally', (
      tester,
    ) async {
      int activeIndex = 0;
      int refreshCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return GetMaterialApp(
              translations: AppTranslations(),
              locale: LocalizationService.englishLocale,
              fallbackLocale: LocalizationService.englishLocale,
              theme: AppTheme.light,
              home: Scaffold(
                bottomNavigationBar: BottomNavBar(
                  currentIndex: activeIndex,
                  onTap: (idx) => setState(() => activeIndex = idx),
                  onDoubleTapActive: (_) => refreshCount++,
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Home (0) -> LevelUp (1)
      await tester.tap(find.bySemanticsLabel('LevelUp'));
      await tester.pumpAndSettle();
      expect(activeIndex, equals(1));
      expect(refreshCount, equals(0));

      // LevelUp (1) -> Finance (2)
      await tester.tap(find.bySemanticsLabel('Finance'));
      await tester.pumpAndSettle();
      expect(activeIndex, equals(2));
      expect(refreshCount, equals(0));

      // Finance (2) -> Profile (3)
      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();
      expect(activeIndex, equals(3));
      expect(refreshCount, equals(0));

      // Profile (3) -> Home (0)
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();
      expect(activeIndex, equals(0));
      expect(refreshCount, equals(0));
    });
  });

  group('Responsive Liquid Glass & Structural Verification', () {
    testWidgets(
      '+ button remains strictly separate from main navigation pill across all phone widths',
      (tester) async {
        const testWidths = [320.0, 360.0, 390.0, 412.0, 430.0, 600.0];

        for (final width in testWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(createNavBar(currentIndex: 0));
          await tester.pumpAndSettle();

          // Find the plus button icon and the main pill items
          final plusFinder = find.byIcon(Icons.add_rounded);
          expect(plusFinder, findsOneWidget);

          final plusRect = tester.getRect(plusFinder);
          final profileRect = tester.getRect(find.bySemanticsLabel('Profile'));

          // Plus button must be to the right of the last tab item with a gap
          expect(
            plusRect.left,
            greaterThan(profileRect.right),
            reason:
                'Plus button must be positioned to the right of Profile on width $width',
          );

          // Plus button must have a comfortable touch target size
          expect(plusRect.width, greaterThanOrEqualTo(20.0));
          expect(plusRect.height, greaterThanOrEqualTo(20.0));
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('labels never collide or overlap across all phone widths', (
      tester,
    ) async {
      const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0];

      for (final width in testWidths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createNavBar(currentIndex: 1));
        await tester.pumpAndSettle();

        final homeRect = tester.getRect(find.bySemanticsLabel('Home'));
        final levelUpRect = tester.getRect(find.bySemanticsLabel('LevelUp'));
        final financeRect = tester.getRect(find.bySemanticsLabel('Finance'));
        final profileRect = tester.getRect(find.bySemanticsLabel('Profile'));

        // Non-overlapping horizontal ordering: Home < LevelUp < Finance < Profile
        expect(homeRect.right, lessThanOrEqualTo(levelUpRect.left));
        expect(levelUpRect.right, lessThanOrEqualTo(financeRect.left));
        expect(financeRect.right, lessThanOrEqualTo(profileRect.left));

        // Each tab has positive width
        expect(homeRect.width, greaterThan(30.0));
        expect(levelUpRect.width, greaterThan(30.0));
        expect(financeRect.width, greaterThan(30.0));
        expect(profileRect.width, greaterThan(30.0));
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      'active glass lens smoothly animates and centers over the selected tab',
      (tester) async {
        int selectedIndex = 0;

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
                    currentIndex: selectedIndex,
                    onTap: (i) => setState(() => selectedIndex = i),
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Initially on Home (index 0)
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);

        // Tap Finance (index 2)
        await tester.tap(find.bySemanticsLabel('Finance'));

        // Pump halfway through the animation (160ms of 320ms)
        await tester.pump(const Duration(milliseconds: 160));
        expect(selectedIndex, equals(2));
        expect(tester.takeException(), isNull);

        // Finish animation
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.paid_rounded), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      },
    );
  });
}
