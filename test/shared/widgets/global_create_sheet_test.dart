import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/investing_quiz.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => GlobalCreateSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(600, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestApp(locale: locale, themeMode: themeMode));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  group('GlobalCreateSheet Modal Navigation Tests', () {
    testWidgets('renders all section headers and all 13 action buttons in English', (tester) async {
      await openSheet(tester);

      // Verify Header
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('What would you like to create?'), findsOneWidget);

      // Verify Section Headers
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

      // Verify Community Actions (4)
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);

      // Verify Productivity Actions (3)
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);

      // Verify Financial Actions (3)
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);

      // Verify Entertainment Actions (3)
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Short Content'), findsOneWidget);
    });

    testWidgets('renders properly in Light Mode without errors', (tester) async {
      await openSheet(tester, themeMode: ThemeMode.light);

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly in Dark Mode without errors', (tester) async {
      await openSheet(tester, themeMode: ThemeMode.dark);

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all section headers and actions in Khmer without overflow', (tester) async {
      await openSheet(tester, locale: const Locale('km', 'KH'));

      // Verify Khmer header
      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('តើអ្នកចង់បង្កើតអ្វី?'), findsOneWidget);
      expect(find.text('សហគមន៍'), findsOneWidget);
      expect(find.text('ផលិតភាព'), findsOneWidget);
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(find.text('ការកម្សាន្ត'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts smoothly to small phone viewport (320x568) in Khmer without overflow', (tester) async {
      await openSheet(
        tester,
        locale: const Locale('km', 'KH'),
        size: const Size(320, 568),
      );

      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('សហគមន៍'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts smoothly to tablet / desktop viewport (800x1200)', (tester) async {
      await openSheet(
        tester,
        size: const Size(800, 1200),
      );

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Post opens CreatePostScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('tapping Event opens CreateEventScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
    });

    testWidgets('tapping Discussion opens CreateDiscussionScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Discussion'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDiscussionScreen), findsOneWidget);
    });

    testWidgets('tapping Goal opens CreateGoalScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping To-Do opens CreateTaskScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('To-Do'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTaskScreen), findsOneWidget);
    });

    testWidgets('tapping Habit opens CreateHabitScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateHabitScreen), findsOneWidget);
    });

    testWidgets('tapping Expense opens AddExpenseScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
    });

    testWidgets('tapping Saving Goal opens CreateGoalScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Saving Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping Budget opens SetBudgetScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(SetBudgetScreen), findsOneWidget);
    });

    testWidgets('tapping Quiz opens InvestingQuizScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();

      expect(find.byType(InvestingQuizScreen), findsOneWidget);
    });

    testWidgets('tapping Challenge opens Challenge dialog in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Challenge'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tapping Short Content opens Short Content dialog in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Short Content'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
