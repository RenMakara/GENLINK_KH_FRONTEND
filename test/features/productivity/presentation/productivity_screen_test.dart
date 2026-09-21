import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart'
    hide ProductivityPage;
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/widgets/productivity_components.dart';
import 'package:genlink_frontend/features/productivity/presentation/widgets/productivity_illustrations.dart';
import 'package:get/get.dart';

class _MockProductivityController extends GetxController
    implements ProductivityController {
  @override
  final isLoading = false.obs;

  final isSubmitting = false.obs;

  @override
  final errorMessage = RxnString();

  @override
  final dashboard = Rxn<ProductivityDashboard>();

  @override
  final tasks = <ProductivityTask>[].obs;

  @override
  final habits = <ProductivityHabit>[].obs;

  @override
  final focusHistory = <ProductivityFocusSession>[].obs;

  final focusHistoryPage = 1.obs;

  final focusHistoryHasMore = false.obs;

  @override
  final activeFocusSession = Rxn<ProductivityFocusSession>();

  final isFocusSessionRunning = false.obs;

  final isFocusSessionPaused = false.obs;

  final focusRemainingSeconds = 0.obs;

  final focusPresetMinutes = 25.obs;

  bool toggleTaskCalled = false;
  String? toggledTaskId;
  bool? toggledCompleted;

  bool reloadCalled = false;

  @override
  Future<void> load() async {}

  @override
  Future<void> reload() async {
    reloadCalled = true;
  }

  @override
  Future<ProductivityTask> toggleTask(String taskId, {required bool completed}) async {
    toggleTaskCalled = true;
    toggledTaskId = taskId;
    toggledCompleted = completed;
    return ProductivityTask(taskId: taskId, title: 'Task', completed: completed);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockProductivityController controller;

  setUp(() {
    controller = _MockProductivityController();
    Get.reset();
  });

  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('ProductivityHeader Tests', () {
    testWidgets('renders title, subtitle, streak pill, and notification badge',
        (tester) async {
      bool notificationsTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityHeader(
            streakCount: 3,
            onNotifications: () => notificationsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productivity'), findsOneWidget);
      expect(find.text('Your daily growth dashboard'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(notificationsTapped, isTrue);
    });

    testWidgets('renders 1 day streak correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityHeader(
            streakCount: 1,
            onNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 day'), findsOneWidget);
    });
  });

  group('ProductivitySummaryCard Tests', () {
    testWidgets('renders Today gradient card with 3D dartboard and 3 stat badges',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ProductivitySummaryCard(
            completedTasks: 3,
            totalTasks: 3,
            focusMinutes: 25,
            habitStreak: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Keep building momentum 👋'), findsOneWidget);
      expect(find.byType(Soft3DTargetDartboardWidget), findsOneWidget);

      // Stat badges
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);

      // Progress bar
      expect(find.text('Daily progress'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('ProductivityTodayPlan Tests', () {
    testWidgets('renders task list, completed state with strikethrough, and toggles',
        (tester) async {
      bool seeAllTapped = false;
      controller.tasks.assignAll([
        ProductivityTask(
          taskId: 't1',
          title: 'test2',
          completed: true,
          dueDate: DateTime(2026, 9, 22, 4, 12),
        ),
        const ProductivityTask(
          taskId: 't2',
          title: 'Test',
          completed: true,
          category: 'STUDY',
        ),
        const ProductivityTask(
          taskId: 't3',
          title: 'Unfinished Task',
          completed: false,
        ),
      ]);

      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityTodayPlan(
            controller: controller,
            onSeeAll: () => seeAllTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('test2'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('STUDY'), findsOneWidget);
      expect(find.text('Unfinished Task'), findsOneWidget);

      // Tap task to toggle
      await tester.tap(find.text('test2'));
      await tester.pumpAndSettle();
      expect(controller.toggleTaskCalled, isTrue);
      expect(controller.toggledTaskId, 't1');
      expect(controller.toggledCompleted, isFalse);

      // Tap See All
      await tester.tap(find.text('See All'));
      await tester.pumpAndSettle();
      expect(seeAllTapped, isTrue);
    });

    testWidgets('renders empty state when no tasks exist', (tester) async {
      controller.tasks.clear();

      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityTodayPlan(
            controller: controller,
            onSeeAll: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet. Add one to get started.'), findsOneWidget);
    });
  });

  group('ProductivityQuickActions Tests', () {
    testWidgets('renders 2x2 grid with soft 3D icons, subtitles, and arrow buttons',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityQuickActions(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);

      // Action 1: Add Task
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Get things done'), findsOneWidget);

      // Action 2: Add Habit
      expect(find.text('Add Habit'), findsOneWidget);
      expect(find.text('Build better you'), findsOneWidget);

      // Action 3: Focus
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Stay in the zone'), findsOneWidget);

      // Action 4: New Goal
      expect(find.text('New Goal'), findsOneWidget);
      expect(find.text('Turn dreams into reality'), findsOneWidget);
    });
  });

  group('ProductivityGoalProgressSection Tests', () {
    testWidgets('renders empty state with Soft3D mound and Create Goal pill button',
        (tester) async {
      bool seeAllTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityGoalProgressSection(
            goals: const [],
            onSeeAll: () => seeAllTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goal Progress'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.byType(Soft3DGoalMoundWidget), findsOneWidget);
      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.text('Create your first goal and start tracking your progress.'),
          findsOneWidget);
      expect(find.text('Create Goal'), findsOneWidget);

      await tester.tap(find.text('See All'));
      await tester.pumpAndSettle();
      expect(seeAllTapped, isTrue);
    });

    testWidgets('renders active goal progress cards when goals exist',
        (tester) async {
      final goals = [
        const ProductivityGoalProgress(
          goalId: 'g1',
          title: 'Save for Laptop',
          progressPercentage: 80.0,
          status: 'ACTIVE',
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProductivityGoalProgressSection(
            goals: goals,
            onSeeAll: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save for Laptop'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('ProductivityMotivationSection Tests', () {
    testWidgets('renders motivation card with sparkle, content, and mountain peak',
        (tester) async {
      const motivation = ProductivityMotivationCard(
        motivationId: 'm1',
        title: 'Start small',
        content:
            'You do not have to be great to start, but you have to start to be great. One small step today beats a perfect plan tomorrow.',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const ProductivityMotivationSection(motivation: motivation),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Soft3DSparkleWidget), findsOneWidget);
      expect(find.text('Start small'), findsOneWidget);
      expect(
        find.textContaining('You do not have to be great to start'),
        findsOneWidget,
      );
      expect(find.byType(Soft3DMountainPeakWidget), findsOneWidget);
    });
  });

  group('Khmer Localization & Dark Mode Tests', () {
    testWidgets('renders full Productivity screen layout in Khmer locale cleanly',
        (tester) async {
      controller.tasks.assignAll([
        const ProductivityTask(
          taskId: 't1',
          title: 'កិច្ចការគំរូ',
          completed: false,
        ),
      ]);

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('km', 'KH'),
          child: Column(
            children: [
              ProductivityHeader(
                streakCount: 2,
                onNotifications: () {},
              ),
              const SizedBox(height: 18),
              const ProductivitySummaryCard(
                completedTasks: 1,
                totalTasks: 2,
                focusMinutes: 45,
                habitStreak: 2,
              ),
              const SizedBox(height: 18),
              ProductivityTodayPlan(
                controller: controller,
                onSeeAll: () {},
              ),
              const SizedBox(height: 18),
              ProductivityQuickActions(
                controller: controller,
              ),
              const SizedBox(height: 18),
              ProductivityGoalProgressSection(
                goals: const [],
                onSeeAll: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Khmer headers
      expect(find.text('ផលិតភាព'), findsOneWidget);
      expect(find.text('ផែនការថ្ងៃនេះ'), findsOneWidget);
      expect(find.text('សកម្មភាពរហ័ស'), findsOneWidget);
      expect(find.text('វឌ្ឍនភាពគោលដៅ'), findsOneWidget);
      expect(find.text('មិនទាន់មានគោលដៅនៅឡើយ'), findsOneWidget);
      expect(find.text('បង្កើតគោលដៅ'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in Dark Mode without errors', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          theme: ThemeData.dark(),
          child: ProductivityHeader(
            streakCount: 5,
            onNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productivity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
