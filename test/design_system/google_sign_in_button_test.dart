import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/google_sign_in_button.dart';

void main() {
  testWidgets('renders natively and invokes the Google action', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleSignInButton(
            semanticLabel: 'Continue with Google',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('G'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.byType(GoogleSignInButton));
    expect(pressed, isTrue);
  });

  testWidgets('does not invoke the action while disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleSignInButton(semanticLabel: 'Continue with Google'),
        ),
      ),
    );

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
