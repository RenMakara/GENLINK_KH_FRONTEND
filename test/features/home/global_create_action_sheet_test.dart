import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/global_create_action_sheet.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('GlobalCreateActionSheet renders exclusively Daily Life Quick Create actions (To-Do, Goal, Expense)', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: GlobalCreateActionSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Quick Create'), findsOneWidget);

    // Verify Daily Life Quick Actions
    expect(find.text('To-Do'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);

    // Verify Community creation is NOT present in Home Create
    expect(find.text('Post'), findsNothing);
    expect(find.text('Event'), findsNothing);
    expect(find.text('Habit'), findsNothing);
  });
}
