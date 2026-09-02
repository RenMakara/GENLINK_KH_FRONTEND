import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('center action uses the localized semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.khmerLocale,
        fallbackLocale: LocalizationService.englishLocale,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onCenterTap: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('បង្កើត'), findsOneWidget);
    expect(find.bySemanticsLabel('Create'), findsNothing);
    semantics.dispose();
  });

  testWidgets('renders LevelUp tab with flame icon and English label', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onCenterTap: () {},
          ),
        ),
      ),
    );

    // Label should be LevelUp
    expect(find.text('LevelUp'), findsOneWidget);
    expect(find.text('Growth'), findsNothing);

    // Inactive LevelUp icon should be CupertinoIcons.flame
    expect(find.byIcon(CupertinoIcons.flame), findsOneWidget);

    // Other tabs intact
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('renders LevelUp tab with filled flame icon when active', (
    tester,
  ) async {
    int selectedIndex = -1;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (index) => selectedIndex = index,
            onCenterTap: () {},
          ),
        ),
      ),
    );

    // Active LevelUp icon should be CupertinoIcons.flame_fill
    expect(find.byIcon(CupertinoIcons.flame_fill), findsOneWidget);

    // Tap fires with index 1
    await tester.tap(find.text('LevelUp'));
    expect(selectedIndex, 1);
  });

  testWidgets('renders LevelUp tab with localized Khmer label in Khmer locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.khmerLocale,
        fallbackLocale: LocalizationService.englishLocale,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onCenterTap: () {},
          ),
        ),
      ),
    );

    // Localized Khmer label
    expect(find.text('ឡើងកម្រិត'), findsOneWidget);
    expect(find.text('ការរីកចម្រើន'), findsNothing);
  });
}
