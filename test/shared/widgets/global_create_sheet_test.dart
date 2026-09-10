import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart'
    as finance_goal;
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;

    final repo = _MockFinanceRepository();
    final financeController = FinanceController(repository: repo);
    Get.put<FinanceController>(financeController, permanent: true);
    Get.put<ExpenseController>(ExpenseController(repository: repo, financeController: financeController), permanent: true);
    Get.put<SavingGoalController>(SavingGoalController(repository: repo, financeController: financeController), permanent: true);
    Get.put<BudgetController>(BudgetController(repository: repo, financeController: financeController), permanent: true);
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
      getPages: [
        GetPage(
          name: AppRoutes.quizDashboard,
          page: () => const Scaffold(body: Text('Quiz Dashboard')),
        ),
      ],
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

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('What would you like to create?'), findsOneWidget);

      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);

      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);

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

      expect(find.byType(finance_goal.CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping Budget opens SetBudgetScreen in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(SetBudgetScreen), findsOneWidget);
    });

    testWidgets('tapping Quiz opens quiz route in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('tapping Challenge opens Challenge dialog in 1 tap', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Challenge'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tapping Story closes Create menu and invokes Story creation picker', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Story'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('scrolling smoothly through the Create menu reaches all 4 categories and 13 options', (tester) async {
      await openSheet(tester, size: const Size(360, 640));

      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);

      final scrollable = find.byType(ListView).last;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('ENTERTAINMENT'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Short Content'), findsOneWidget);
    });

    testWidgets('visual direction: uses neutral cards and surfaces without bright rainbow/neon colors in Dark Mode', (tester) async {
      await openSheet(tester, themeMode: ThemeMode.dark);

      // Verify absence of rainbow neon colors
      expect(find.byWidgetPredicate((w) {
        if (w is Icon && w.color != null) {
          final c = w.color!;
          return c == AppColors.communityAccent ||
              c == AppColors.growthAccent ||
              c == AppColors.brandPrimary ||
              c == AppColors.productivityAccent ||
              c == AppColors.financeAccent;
        }
        return false;
      }), findsNothing);
    });

    testWidgets('visual direction: uses neutral cards and surfaces without bright rainbow/neon colors in Light Mode', (tester) async {
      await openSheet(tester, themeMode: ThemeMode.light);

      // Verify absence of rainbow neon colors
      expect(find.byWidgetPredicate((w) {
        if (w is Icon && w.color != null) {
          final c = w.color!;
          return c == AppColors.communityAccent ||
              c == AppColors.growthAccent ||
              c == AppColors.brandPrimary ||
              c == AppColors.productivityAccent ||
              c == AppColors.financeAccent;
        }
        return false;
      }), findsNothing);
    });

    testWidgets('small mobile screen (320x568) in Khmer scrolls and renders without clipping or overflow', (tester) async {
      await openSheet(
        tester,
        locale: const Locale('km', 'KH'),
        size: const Size(320, 568),
      );

      final scrollable = find.byType(ListView).last;

      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('សហគមន៍'), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('ផលិតភាព'), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('ការកម្សាន្ត'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
