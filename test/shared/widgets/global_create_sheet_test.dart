import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Budget Feature/screens/set_budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Expense Feature/screens/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Learn Feature/screens/investing_quiz.dart';
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

  Widget buildTestApp({Locale locale = const Locale('en', 'US'), Size screenSize = const Size(400, 800)}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: const Scaffold(
          body: GlobalCreateSheet(),
        ),
      ),
    );
  }

  group('GlobalCreateSheet Direct 1-Tap Tests', () {
    testWidgets('renders all section headers and all 13 action buttons immediately in English', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

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

    testWidgets('renders all section headers and actions in Khmer without overflow', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('km', 'KH'), screenSize: const Size(340, 800)));
      await tester.pumpAndSettle();

      // Verify Khmer text
      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('តើអ្នកចង់បង្កើតអ្វី?'), findsOneWidget);
      expect(find.text('សហគមន៍'), findsOneWidget);
      expect(find.text('ផលិតភាព'), findsOneWidget);
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(find.text('ការកម្សាន្ត'), findsOneWidget);

      expect(find.text('ប្រកាស'), findsOneWidget);
      expect(find.text('ស្តូរី'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsOneWidget);
      expect(find.text('ការពិភាក្សា'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Post opens CreatePostScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Post'));
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('tapping Event opens CreateEventScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Event'));
      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
    });

    testWidgets('tapping Discussion opens CreateDiscussionScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Discussion'));
      await tester.tap(find.text('Discussion'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDiscussionScreen), findsOneWidget);
    });

    testWidgets('tapping To-Do opens CreateTaskScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('To-Do'));
      await tester.tap(find.text('To-Do'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTaskScreen), findsOneWidget);
    });

    testWidgets('tapping Habit opens CreateHabitScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Habit'));
      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateHabitScreen), findsOneWidget);
    });

    testWidgets('tapping Expense opens AddExpenseScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Expense'));
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
    });

    testWidgets('tapping Budget opens SetBudgetScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Budget'));
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(SetBudgetScreen), findsOneWidget);
    });

    testWidgets('tapping Quiz opens InvestingQuizScreen in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Quiz'));
      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();

      expect(find.byType(InvestingQuizScreen), findsOneWidget);
    });

    testWidgets('tapping Challenge opens Challenge dialog in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Challenge'));
      await tester.tap(find.text('Challenge'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tapping Short Content opens Short Content dialog in 1 tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Short Content'));
      await tester.tap(find.text('Short Content'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow 320px device width without overflow', (tester) async {
      await tester.pumpWidget(buildTestApp(screenSize: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
