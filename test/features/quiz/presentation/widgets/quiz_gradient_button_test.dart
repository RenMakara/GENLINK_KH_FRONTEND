import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_gradient_button.dart';

void main() {
  testWidgets('outlined loading state shows progress feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(
          body: QuizGradientButton(
            label: 'Submit',
            isOutlined: true,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });
}
