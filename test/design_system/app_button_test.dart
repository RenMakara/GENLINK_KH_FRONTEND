import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';

/// Regression tests for the button label colour.
///
/// The label used to be styled with `textTheme.labelLarge`, which carries an
/// explicit colour from `TextTheme.apply(bodyColor:)`. An explicit `Text`
/// colour beats the button's `foregroundColor`, so the label rendered
/// black-on-black in light mode and white-on-white in dark mode. The style
/// now goes through `ButtonStyle.textStyle` instead, letting the button
/// overlay its own foreground colour.
void main() {
  /// The colour the label is actually painted in.
  Color resolvedLabelColor(WidgetTester tester, String label) {
    final style = tester.widget<RichText>(
      find.descendant(
        of: find.text(label),
        matching: find.byType(RichText),
      ),
    );
    return style.text.style!.color!;
  }

  /// [enabled] matters: a button with no `onPressed` resolves the *disabled*
  /// foreground colour, which is a different code path.
  Future<void> pumpButton(
    WidgetTester tester,
    ThemeData theme, {
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Create Account',
              onPressed: enabled ? () {} : null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('primary label contrasts with the button in light mode',
      (tester) async {
    final theme = AppTheme.lightFor('en');
    await pumpButton(tester, theme);

    final labelColor = resolvedLabelColor(tester, 'Create Account');

    expect(labelColor, theme.colorScheme.onPrimary);
    expect(
      labelColor,
      isNot(theme.colorScheme.primary),
      reason: 'label would be invisible against its own background',
    );
  });

  testWidgets('primary label contrasts with the button in dark mode',
      (tester) async {
    final theme = AppTheme.darkFor('en');
    await pumpButton(tester, theme);

    final labelColor = resolvedLabelColor(tester, 'Create Account');

    expect(labelColor, theme.colorScheme.onPrimary);
    expect(
      labelColor,
      isNot(theme.colorScheme.primary),
      reason: 'label would be invisible against its own background',
    );
  });

  testWidgets('disabled label is dimmed but still not the background colour',
      (tester) async {
    final theme = AppTheme.lightFor('en');
    await pumpButton(tester, theme, enabled: false);

    final labelColor = resolvedLabelColor(tester, 'Create Account');

    expect(labelColor.a, lessThan(1.0), reason: 'disabled should be dimmed');
    expect(labelColor, isNot(theme.colorScheme.primary));
  });

  testWidgets('label keeps the design system type scale', (tester) async {
    final theme = AppTheme.lightFor('en');
    await pumpButton(tester, theme);

    final style = tester
        .widget<RichText>(
          find.descendant(
            of: find.text('Create Account'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;

    expect(style.fontSize, theme.textTheme.labelLarge!.fontSize);
    expect(style.fontWeight, theme.textTheme.labelLarge!.fontWeight);
  });
}
