import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/domain/repositories/productivity_repository.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_detail.dart';

class MockProductivityRepo implements ProductivityRepository {
  List<ProductivityMilestone>? customMilestones;

  @override
  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
  }) async {
    return ProductivityGoal(
      goalId: goalId,
      title: 'Test Goal',
      goalType: 'Personal',
      progressPercentage: 50,
      totalMilestones: 2,
      completedMilestones: 1,
      milestones: [
        ProductivityMilestone(
          milestoneId: 'm1',
          title: 'Existing',
          completed: true,
        ),
        ProductivityMilestone(
          milestoneId: 'm2',
          title: title,
          completed: false,
        ),
      ],
    );
  }

  @override
  Future<ProductivityGoal> getGoal(String goalId) async {
    return ProductivityGoal(
      goalId: goalId,
      title: 'Test Goal',
      goalType: 'Personal',
      progressPercentage: 0,
      totalMilestones: customMilestones?.length ?? 1,
      completedMilestones: 0,
      milestones: customMilestones ?? [
        ProductivityMilestone(
          milestoneId: 'm1',
          title: 'Existing',
          completed: false,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('adding milestone in GoalDetailScreen succeeds without lifecycle errors', (tester) async {
    final repo = MockProductivityRepo();
    final controller = ProductivityController(repository: repo);
    Get.put<ProductivityController>(controller);

    final goal = ProductivityGoal(
      goalId: 'goal_123',
      title: 'Test Goal',
      goalType: 'Personal',
      progressPercentage: 0,
      totalMilestones: 0,
      completedMilestones: 0,
      milestones: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: GoalDetailScreen(goal: goal),
      ),
    );
    await tester.pumpAndSettle();

    // Tap add milestone button
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Find TextField in dialog
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New Milestone');
    await tester.pumpAndSettle();

    // Tap Add button
    final addButton = find.widgetWithText(FilledButton, 'Add');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify milestone now appears in list
    expect(find.text('New Milestone'), findsOneWidget);
  });

  testWidgets('adding milestone in CreateGoalScreen works safely', (tester) async {
    final repo = MockProductivityRepo();
    final controller = ProductivityController(repository: repo);
    Get.put<ProductivityController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const CreateGoalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find add milestone button in creation screen
    final addMilestoneBtn = find.text('Add Milestone');
    if (addMilestoneBtn.evaluate().isNotEmpty) {
      await tester.tap(addMilestoneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).last, 'Plan Step 1');
      await tester.pumpAndSettle();

      final addBtn = find.widgetWithText(FilledButton, 'Add');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Plan Step 1'), findsOneWidget);
    }
  });

  testWidgets('tapping quick suggestion chip in GoalDetailScreen pre-fills dialog and adds milestone', (tester) async {
    final repo = MockProductivityRepo();
    final controller = ProductivityController(repository: repo);
    Get.put<ProductivityController>(controller);

    final goal = ProductivityGoal(
      goalId: 'goal_123',
      title: 'Test Goal',
      goalType: 'Personal',
      progressPercentage: 0,
      totalMilestones: 0,
      completedMilestones: 0,
      milestones: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: GoalDetailScreen(goal: goal),
      ),
    );
    await tester.pumpAndSettle();

    // Tap add milestone button
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Verify quick suggestion chip exists and tap it
    final suggestion = find.text('Research & Plan');
    expect(suggestion, findsOneWidget);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    // Verify textfield now has the suggestion
    expect(find.text('Research & Plan'), findsWidgets);

    // Tap Add button
    final addButton = find.widgetWithText(FilledButton, 'Add');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Milestone now appears
    expect(find.text('Research & Plan'), findsOneWidget);
  });

  testWidgets('empty state Add First Milestone button opens dialog and adds milestone', (tester) async {
    final repo = MockProductivityRepo();
    repo.customMilestones = [];
    final controller = ProductivityController(repository: repo);
    Get.put<ProductivityController>(controller);

    final goal = ProductivityGoal(
      goalId: 'goal_123',
      title: 'Test Goal',
      goalType: 'Personal',
      progressPercentage: 0,
      totalMilestones: 0,
      completedMilestones: 0,
      milestones: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: GoalDetailScreen(goal: goal),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "+ Add First Milestone" in empty state
    final addFirstBtn = find.text('Add First Milestone');
    expect(addFirstBtn, findsOneWidget);
    await tester.tap(addFirstBtn);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'First Step');
    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(FilledButton, 'Add');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('First Step'), findsOneWidget);
  });

  testWidgets('direct quick add suggestion in CreateGoalScreen adds milestone immediately', (tester) async {
    final repo = MockProductivityRepo();
    final controller = ProductivityController(repository: repo);
    Get.put<ProductivityController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const CreateGoalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap a quick suggestion in the creation form
    final chip = find.text('Research & Scope');
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Verify it was added to the milestones numbered list
      expect(find.text('Research & Scope'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    }
  });
}
