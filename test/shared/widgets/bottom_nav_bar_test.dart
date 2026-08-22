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
}
