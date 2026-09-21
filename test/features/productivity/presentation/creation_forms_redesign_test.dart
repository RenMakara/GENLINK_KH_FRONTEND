import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/widgets/creation_form_components.dart';
import 'package:get/get.dart';

class _MockProductivityController extends GetxController
    implements ProductivityController {
  String? createdGoalTitle;
  String? createdGoalType;
  String? createdTaskTitle;
  String? createdTaskPriority;
  String? createdHabitTitle;
  String? createdHabitFrequency;

  @override
  Future<ProductivityGoal> createGoal({
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) async {
    createdGoalTitle = title;
    createdGoalType = goalType;
    return ProductivityGoal(
      goalId: 'goal-1',
      title: title,
      description: description,
      goalType: goalType,
      deadline: deadline,
    );
  }

  @override
  Future<ProductivityTask> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) async {
    createdTaskTitle = title;
    createdTaskPriority = priority;
    return ProductivityTask(
      taskId: 'task-1',
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      reminderTime: reminderTime,
    );
  }

  @override
  Future<ProductivityHabit> createHabit({
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) async {
    createdHabitTitle = title;
    createdHabitFrequency = frequency;
    return ProductivityHabit(
      habitId: 'habit-1',
      title: title,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
    );
  }

  @override
  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
    DateTime? deadline,
  }) async {
    return ProductivityGoal(
      goalId: goalId,
      title: 'Goal',
      milestones: [ProductivityMilestone(milestoneId: 'm-1', title: title)],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockProductivityController controller;

  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);

    controller = _MockProductivityController();
    Get.replace<ProductivityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpForm(
    WidgetTester tester,
    Widget child, {
    ThemeMode mode = ThemeMode.light,
    Locale locale = const Locale('en', 'US'),
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(GetMaterialApp(
      themeMode: mode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      translations: AppTranslations(),
      locale: locale,
      home: child,
    ));
    await tester.pumpAndSettle();
  }

  group('CreateGoalScreen Redesign Tests', () {
    testWidgets('renders all redesigned Goal form components properly', (
      tester,
    ) async {
      await pumpForm(tester, const CreateGoalScreen());

      // Header
      expect(find.text('New Goal'), findsOneWidget);
      expect(find.text('Turn your dreams into reality'), findsOneWidget);
      expect(find.byType(CreationFormHeader), findsOneWidget);

      // Hero Card with quote
      expect(
        find.text('A clear goal today, a brighter tomorrow.'),
        findsOneWidget,
      );

      // Fields
      expect(find.text('Goal title'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.text('Goal type'), findsOneWidget);

      // 4 Goal types
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);
      expect(find.text('Skill'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);

      // Target & Deadline cards
      expect(find.text('Target & Deadline'), findsOneWidget);
      expect(find.text('Target (optional)'), findsOneWidget);
      expect(find.text('Deadline (optional)'), findsOneWidget);

      // Milestones and Motivation
      expect(find.text('Add Milestones (optional)'), findsOneWidget);
      expect(find.text('Small steps make big changes.'), findsOneWidget);

      // Save Goal Button
      expect(find.text('Save Goal'), findsOneWidget);
    });

    testWidgets('allows selecting goal type cards', (tester) async {
      await pumpForm(tester, const CreateGoalScreen());

      // Tap 'Career'
      await tester.tap(find.text('Career'));
      await tester.pumpAndSettle();

      // Enter title and save
      await tester.enterText(
        find.widgetWithText(TextField, 'What do you want to achieve?'),
        'Become Senior Lead',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Goal'));
      await tester.pumpAndSettle();

      expect(controller.createdGoalTitle, 'Become Senior Lead');
      expect(controller.createdGoalType, 'CAREER');
    });

    testWidgets('validates empty goal title', (tester) async {
      await pumpForm(tester, const CreateGoalScreen());

      await tester.tap(find.text('Save Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a goal title.'), findsOneWidget);
      expect(controller.createdGoalTitle, isNull);
    });
  });

  group('CreateTaskScreen Redesign Tests', () {
    testWidgets('renders all redesigned Task form components properly', (
      tester,
    ) async {
      await pumpForm(tester, const CreateTaskScreen());

      // Header
      expect(find.text('Create Task'), findsOneWidget);
      expect(find.text('Get things done, one step at a time'), findsOneWidget);

      // Hero Card
      expect(find.text('Turn your to-dos into progress'), findsOneWidget);

      // Fields
      expect(find.text('Task title'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);

      // Priority options
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      // Due date & Reminder cards
      expect(find.text('Due date (optional)'), findsOneWidget);
      expect(find.text('Reminder (optional)'), findsOneWidget);

      // Bottom Save CTA
      expect(find.text('Save Task'), findsOneWidget);
    });

    testWidgets('allows selecting priority and entering task', (tester) async {
      await pumpForm(tester, const CreateTaskScreen());

      // Tap 'High' priority
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter task title...'),
        'Ship GenLink Redesign',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      expect(controller.createdTaskTitle, 'Ship GenLink Redesign');
      expect(controller.createdTaskPriority, 'HIGH');
    });

    testWidgets('validates empty task title', (tester) async {
      await pumpForm(tester, const CreateTaskScreen());

      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a task title'), findsOneWidget);
      expect(controller.createdTaskTitle, isNull);
    });
  });

  group('CreateHabitScreen Redesign Tests', () {
    testWidgets('renders all redesigned Habit form components properly', (
      tester,
    ) async {
      await pumpForm(tester, const CreateHabitScreen());

      // Header
      expect(find.text('New Habit'), findsOneWidget);
      expect(find.text('Small habits, big results'), findsOneWidget);

      // Hero Card
      expect(find.text('Build better you, one habit at a time'), findsOneWidget);

      // Fields
      expect(find.text('Habit name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);

      // Frequency options
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Reminder & Motivation
      expect(find.text('Reminder (optional)'), findsOneWidget);
      expect(find.text('Consistency creates progress.'), findsOneWidget);

      // Save CTA
      expect(find.text('Save Habit'), findsOneWidget);
    });

    testWidgets('allows selecting frequency and saving habit', (tester) async {
      await pumpForm(tester, const CreateHabitScreen());

      // Tap 'Weekly' frequency
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Enter habit title
      await tester.enterText(
        find.widgetWithText(TextField, 'What habit do you want to build?'),
        'Read 10 pages',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();

      expect(controller.createdHabitTitle, 'Read 10 pages');
      expect(controller.createdHabitFrequency, 'WEEKLY');
    });

    testWidgets('allows selecting category via modal bottom sheet', (
      tester,
    ) async {
      await pumpForm(tester, const CreateHabitScreen());

      // Initial category displays "Personal"
      expect(find.text('Personal'), findsOneWidget);

      // Tap category dropdown card to open bottom sheet
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Bottom sheet header and category choices should be visible
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);

      // Tap 'Health'
      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      // Sheet is closed and 'Health' is selected
      expect(find.text('Health'), findsOneWidget);

      // Enter habit title and save
      await tester.enterText(
        find.widgetWithText(TextField, 'What habit do you want to build?'),
        'Drink 2L water',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();

      expect(controller.createdHabitTitle, 'Drink 2L water');
      expect(controller.createdHabitFrequency, 'DAILY');
    });

    testWidgets('validates empty habit title', (tester) async {
      await pumpForm(tester, const CreateHabitScreen());

      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a habit title.'), findsOneWidget);
      expect(controller.createdHabitTitle, isNull);
    });
  });

  group('Khmer Locale & Dark Mode Tests', () {
    testWidgets('renders Goal screen in Khmer without overflow', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const CreateGoalScreen(),
        locale: const Locale('km', 'KH'),
      );

      expect(find.text('គោលដៅថ្មី'), findsOneWidget);
      expect(find.text('ប្រែក្លាយក្តីស្រមៃរបស់អ្នកទៅជាការពិត'), findsOneWidget);
      expect(find.text('រក្សាទុកគោលដៅ'), findsOneWidget);
    });

    testWidgets('renders Task screen in Khmer without overflow', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const CreateTaskScreen(),
        locale: const Locale('km', 'KH'),
      );

      expect(find.text('បង្កើតកិច្ចការ'), findsOneWidget);
      expect(find.text('បំពេញកិច្ចការមួយជំហានម្តងៗ'), findsOneWidget);
      expect(find.text('រក្សាទុកកិច្ចការ'), findsOneWidget);
    });

    testWidgets('renders Habit screen in Khmer without overflow', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const CreateHabitScreen(),
        locale: const Locale('km', 'KH'),
      );

      expect(find.text('ទម្លាប់ថ្មី'), findsOneWidget);
      expect(find.text('ទម្លាប់តូចៗ លទ្ធផលធំធេង'), findsOneWidget);
      expect(find.text('រក្សាទុកទម្លាប់'), findsOneWidget);
    });

    testWidgets('renders all 3 screens in Dark Mode', (tester) async {
      for (final screen in [
        const CreateGoalScreen(),
        const CreateTaskScreen(),
        const CreateHabitScreen(),
      ]) {
        await pumpForm(tester, screen, mode: ThemeMode.dark);
        expect(find.byType(CreationFormHeader), findsOneWidget);
      }
    });
  });
}
