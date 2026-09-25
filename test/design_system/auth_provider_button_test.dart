import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/auth_provider_button.dart';

void main() {
  testWidgets('renders AuthProviderButton with label and optional icon', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightFor('en'),
        home: Scaffold(
          body: AuthProviderButton(
            label: 'Continue with Mail',
            icon: const Icon(Icons.mail_rounded, size: 22),
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Continue with Mail'), findsOneWidget);
    expect(find.byIcon(Icons.mail_rounded), findsOneWidget);

    await tester.tap(find.byType(AuthProviderButton));
    expect(pressed, isTrue);
  });

  testWidgets('renders disabled state when onPressed is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightFor('en'),
        home: const Scaffold(
          body: AuthProviderButton(
            label: 'Continue with Mail',
            onPressed: null,
          ),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('renders progress indicator and disables tap while loading', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightFor('en'),
        home: Scaffold(
          body: AuthProviderButton(
            label: 'Continue with Mail',
            loading: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue with Mail'), findsNothing);

    await tester.tap(find.byType(AuthProviderButton));
    expect(pressed, isFalse);

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('adapts surface color and border in light mode', (tester) async {
    final theme = AppTheme.lightFor('en');

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Theme(
          data: theme,
          child: Scaffold(
            body: AuthProviderButton(
              label: 'Continue with Mail',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AuthProviderButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.surface);

    final border = material.shape as RoundedRectangleBorder;
    expect(border.side.color, theme.colorScheme.outlineVariant);
    expect(border.side.width, 1.2);
  });

  testWidgets('adapts surface color and border in dark mode', (tester) async {
    final theme = AppTheme.darkFor('en');

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Theme(
          data: theme,
          child: Scaffold(
            body: AuthProviderButton(
              label: 'Continue with Mail',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AuthProviderButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.surface);

    final border = material.shape as RoundedRectangleBorder;
    expect(border.side.color, theme.colorScheme.outlineVariant);
    expect(border.side.width, 1.2);
  });
}
