import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';

/// Renders the bottom nav in both themes with the Community tab active,
/// matching the reference design frame.
void main() {
  const size = Size(390, 200);

  Future<void> pumpBar(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (_) {},
            onCenterTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nav bar light', (tester) async {
    await pumpBar(tester, AppTheme.lightFor('en'));
    await expectLater(
      find.byType(BottomNavBar),
      matchesGoldenFile('goldens/nav_bar.png'),
    );
  });

  testWidgets('nav bar dark', (tester) async {
    await pumpBar(tester, AppTheme.darkFor('en'));
    await expectLater(
      find.byType(BottomNavBar),
      matchesGoldenFile('goldens/nav_bar_dark.png'),
    );
  });
}
