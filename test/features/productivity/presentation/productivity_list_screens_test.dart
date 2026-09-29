import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/task_home_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/widgets/productivity_list_components.dart';
import 'package:get/get.dart';

class _MockProductivityController extends GetxController
    implements ProductivityController {
  final RxList<ProductivityTask> _tasks = <ProductivityTask>[].obs;
  final RxList<ProductivityHabit> _habits = <ProductivityHabit>[].obs;
  final RxList<ProductivityGoal> _goals = <ProductivityGoal>[].obs;
  final RxBool _isLoading = false.obs;
  final RxSet<String> _busyIds = <String>{}.obs;

  String? toggledTaskId;
  bool? toggledTaskCompleted;
  String? toggledHabitId;
  bool? toggledHabitCompleted;
  String? deletedTaskId;
  String? deletedHabitId;

  @override
  RxList<ProductivityTask> get tasks => _tasks;
  @override
  RxList<ProductivityHabit> get habits => _habits;
  @override
  RxList<ProductivityGoal> get goals => _goals;
  @override
  RxBool get isLoading => _isLoading;

  @override
  bool isBusy(String id) => _busyIds.contains(id);

  @override
  Future<void> reload() async {}

  @override
  Future<ProductivityTask> toggleTask(
    String taskId, {
    required bool completed,
  }) async {
    toggledTaskId = taskId;
    toggledTaskCompleted = completed;
    final index = _tasks.indexWhere((t) => t.taskId == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(completed: completed);
    }
    return _tasks[index];
  }

  @override
  Future<ProductivityHabit> toggleHabit(
    String habitId, {
    required bool completed,
  }) async {
    toggledHabitId = habitId;
    toggledHabitCompleted = completed;
    final index = _habits.indexWhere((h) => h.habitId == habitId);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(checkedInToday: completed);
    }
    return _habits[index];
  }

  @override
  Future<void> deleteTask(String taskId) async {
    deletedTaskId = taskId;
    _tasks.removeWhere((t) => t.taskId == taskId);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    deletedHabitId = habitId;
    _habits.removeWhere((h) => h.habitId == habitId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockProductivityController controller;

  setUp(() {
    Get.testMode = true;
    controller = _MockProductivityController();
    Get.reset();
    Get.put<ProductivityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget(Widget child, {Locale? locale, ThemeMode? mode}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale ?? const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      themeMode: mode ?? ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: child,
    );
  }

  group('TasksPage Redesign Tests (Mockup 1)', () {
    testWidgets(
      'renders Tasks hero, search, filter tabs, task cards, and all caught up card',
      (tester) async {
        controller._tasks.assignAll([
          ProductivityTask(
            taskId: 'task-1',
            title: 'test2',
            category: 'STUDY',
            priority: 'MEDIUM',
            dueDate: DateTime.now().add(const Duration(hours: 4)),
          ),
          ProductivityTask(
            taskId: 'task-2',
            title: 'Test',
            category: 'STUDY',
            priority: 'MEDIUM',
          ),
        ]);

        await tester.pumpWidget(buildTestWidget(const TasksPage()));
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Tasks'), findsOneWidget);
        expect(
          find.text('Get things done, one step at a time'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.add_rounded), findsWidgets);

        // Hero Banner
        expect(find.text('Small tasks make big progress'), findsOneWidget);
        expect(find.text('Stay consistent every day.'), findsOneWidget);

        // Search & Filter
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

        // Filter Tabs
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Overdue'), findsOneWidget);

        // Section
        expect(find.text('My Tasks'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Task Items
        expect(find.text('test2'), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('MEDIUM'), findsNWidgets(2));

        // All caught up / encouragement card at bottom
        expect(find.text('All caught up! 🎉'), findsOneWidget);
        expect(find.text('Add Task'), findsOneWidget);
      },
    );

    testWidgets('toggles task completion when check icon is tapped', (
      tester,
    ) async {
      controller._tasks.assignAll([
        ProductivityTask(taskId: 'task-1', title: 'test2', completed: false),
      ]);

      await tester.pumpWidget(buildTestWidget(const TasksPage()));
      await tester.pumpAndSettle();

      // Tap circular checkmark button
      final checkFinder = find.byKey(const ValueKey('task_toggle_task-1'));
      expect(checkFinder, findsOneWidget);
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(controller.toggledTaskId, 'task-1');
      expect(controller.toggledTaskCompleted, isTrue);
    });
  });

  group('HabitHomeScreen Redesign Tests (Mockup 2)', () {
    testWidgets(
      'renders Habits hero, streak card, habits list, and encouragement card',
      (tester) async {
        controller._habits.assignAll([
          ProductivityHabit(
            habitId: 'habit-1',
            title: 'test',
            category: 'PERSONAL',
            frequency: 'DAILY',
            streakCount: 1,
            checkedInToday: true,
          ),
        ]);

        await tester.pumpWidget(buildTestWidget(const HabitHomeScreen()));
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Habits'), findsOneWidget);
        expect(find.text('Small habits, big results'), findsOneWidget);

        // Hero Banner with Flame
        expect(
          find.text('Build better you\none habit at a time.'),
          findsOneWidget,
        );
        expect(
          find.text('Consistency today a brighter tomorrow.'),
          findsOneWidget,
        );

        // Charcoal Streak Card
        expect(find.text('1 day streak'), findsOneWidget);
        expect(find.text('1 of 1 completed'), findsOneWidget);
        expect(
          find.byIcon(Icons.local_fire_department_rounded),
          findsOneWidget,
        );

        // Section Header
        expect(find.text("Today's habits"), findsOneWidget);
        expect(find.text('1/1'), findsOneWidget);

        // Habit Item
        expect(find.text('test'), findsOneWidget);

        // Encouragement Sprout Card
        expect(find.text('Great start! 🌱'), findsOneWidget);
        expect(find.text('Add Habit'), findsOneWidget);
      },
    );

    testWidgets('labels a weekly streak in weeks', (tester) async {
      controller._habits.assignAll([
        ProductivityHabit(
          habitId: 'weekly-habit',
          title: 'Weekly planning',
          frequency: 'WEEKLY',
          streakCount: 2,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(const HabitHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('2 week streak'), findsOneWidget);
    });

    testWidgets('toggles habit check-in when tapped', (tester) async {
      controller._habits.assignAll([
        ProductivityHabit(
          habitId: 'habit-1',
          title: 'test',
          checkedInToday: false,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(const HabitHomeScreen()));
      await tester.pumpAndSettle();

      final checkFinder = find.byKey(const ValueKey('habit_toggle_habit-1'));
      expect(checkFinder, findsOneWidget);
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(controller.toggledHabitId, 'habit-1');
      expect(controller.toggledHabitCompleted, isTrue);
    });
  });

  group('PlanGoalScreen Redesign Tests (Mockup 3)', () {
    testWidgets(
      'renders Goals Plan hero, category chips, empty state mound, and tip card',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(const PlanGoalScreen()));
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Goals Plan'), findsOneWidget);
        expect(find.text('Turn your dreams into reality'), findsOneWidget);

        // Hero Banner
        expect(
          find.text('Set a goal today\na brighter tomorrow.'),
          findsOneWidget,
        );
        expect(find.text('Big dreams start with small steps.'), findsOneWidget);

        // Category Chips
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Personal'), findsOneWidget);
        expect(find.text('Career'), findsOneWidget);
        expect(find.text('Skill'), findsOneWidget);
        expect(find.text('Finance'), findsOneWidget);

        // Section Header
        expect(find.text('My goals'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);

        // Empty State Card with Mound
        expect(find.text('No goals yet'), findsOneWidget);
        expect(
          find.text('Create a goal and break it into milestones.'),
          findsOneWidget,
        );
        expect(find.text('Create goal'), findsOneWidget);

        // Bottom Motivation / Tip Card
        expect(find.text('A better you is a goal away.'), findsOneWidget);
        expect(
          find.text('Set a goal today and start building the future you want.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      },
    );

    testWidgets('renders active goal items when goals exist', (tester) async {
      controller._goals.assignAll([
        ProductivityGoal(
          goalId: 'goal-1',
          title: 'Master Flutter Redesign',
          goalType: 'SKILL',
          progressPercentage: 65,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(const PlanGoalScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Master Flutter Redesign'), findsOneWidget);
      expect(find.text('SKILL'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });
  });

  group('Khmer Locale and Dark Mode Tests for all 3 screens', () {
    testWidgets(
      'renders all 3 listing screens in Khmer locale without overflow',
      (tester) async {
        for (final screen in [
          const TasksPage(),
          const HabitHomeScreen(),
          const PlanGoalScreen(),
        ]) {
          await tester.pumpWidget(
            buildTestWidget(screen, locale: const Locale('km', 'KH')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ListScreenHeader), findsOneWidget);
          expect(find.byType(ListHeroBanner), findsOneWidget);
        }
      },
    );

    testWidgets('renders all 3 listing screens in Dark Mode without issues', (
      tester,
    ) async {
      for (final screen in [
        const TasksPage(),
        const HabitHomeScreen(),
        const PlanGoalScreen(),
      ]) {
        await tester.pumpWidget(buildTestWidget(screen, mode: ThemeMode.dark));
        await tester.pumpAndSettle();
        expect(find.byType(ListScreenHeader), findsOneWidget);
        expect(find.byType(ListHeroBanner), findsOneWidget);
      }
    });
  });
}
