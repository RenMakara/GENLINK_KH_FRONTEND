import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart'
    as finance_saving_goal;
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart'
    as productivity_goal;
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

class _FakeExpenseController extends GetxController
    implements ExpenseController {
  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final selectedCategory = RxnString();

  @override
  final expenses = <FinanceExpenseEntity>[].obs;

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBudgetController extends GetxController implements BudgetController {
  @override
  final selectedMonth = 9.obs;

  @override
  final selectedYear = 2026.obs;

  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final budget = Rxn<FinanceBudgetEntity>();

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSavingGoalController extends GetxController
    implements SavingGoalController {
  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final goals = <FinanceSavingGoalEntity>[].obs;

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put<ExpenseController>(_FakeExpenseController(), permanent: true);
    Get.put<BudgetController>(_FakeBudgetController(), permanent: true);
    Get.put<SavingGoalController>(_FakeSavingGoalController(), permanent: true);
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
          page: () => const Scaffold(body: Text('Quiz Dashboard Page')),
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

  group('GlobalCreateSheet UI Redesign and Navigation Tests', () {
    testWidgets('renders all 4 categories and all 12 approved features with chevrons in English', (tester) async {
      await openSheet(tester);

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('What would you like to create?'), findsOneWidget);

      // Verify all 4 category headers are present
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

      // Verify COMMUNITY features
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);

      // Verify PRODUCTIVITY features
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);

      // Verify FINANCIAL features
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);

      // Verify ENTERTAINMENT features
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);

      // Verify unapproved features are NOT present
      expect(find.text('Short Content'), findsNothing);

      // Verify right-side chevrons exist for each item (at least 12)
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(12));
    });

    testWidgets('renders properly in Light Mode without errors', (tester) async {
      await openSheet(tester, themeMode: ThemeMode.light);

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

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
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

      expect(find.text('Story'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders categories and actions in Khmer without overflow', (tester) async {
      await openSheet(tester, locale: const Locale('km', 'KH'));

      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('តើអ្នកចង់បង្កើតអ្វី?'), findsOneWidget);

      // Category headers in Khmer
      expect(find.text('សហគមន៍'), findsOneWidget);
      expect(find.text('ផលិតភាព'), findsOneWidget);
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(find.text('ការកម្សាន្ត'), findsOneWidget);

      // Action items in Khmer
      expect(find.text('ប្រកាស'), findsOneWidget);
      expect(find.text('ស្តូរី'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsOneWidget);
      expect(find.text('ការពិភាក្សា'), findsOneWidget);
      expect(find.text('គោលដៅ'), findsOneWidget);
      expect(find.text('កិច្ចការត្រូវធ្វើ'), findsOneWidget);
      expect(find.text('ទម្លាប់'), findsOneWidget);
      expect(find.text('ការចំណាយ'), findsOneWidget);
      expect(find.text('គោលដៅសន្សំ'), findsOneWidget);
      expect(find.text('ថវិកា'), findsOneWidget);
      expect(find.text('កម្រងសំណួរ'), findsOneWidget);
      expect(find.text('បញ្ហាប្រឈម'), findsOneWidget);

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
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Post opens CreatePostScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('tapping Event opens CreateEventScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
    });

    testWidgets('tapping Discussion opens CreateDiscussionScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Discussion'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDiscussionScreen), findsOneWidget);
    });

    testWidgets('tapping Story closes Create menu and invokes Story creation picker', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Story'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('tapping Goal opens CreateGoalScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(productivity_goal.CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping To-Do opens CreateTaskScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('To-Do'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTaskScreen), findsOneWidget);
    });

    testWidgets('tapping Habit opens CreateHabitScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateHabitScreen), findsOneWidget);
    });

    testWidgets('tapping Expense opens AddExpenseScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
    });

    testWidgets('tapping Saving Goal opens saving goal CreateGoalScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Saving Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(finance_saving_goal.CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping Budget opens SetBudgetScreen', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(SetBudgetScreen), findsOneWidget);
    });

    testWidgets('tapping Quiz routes to quizDashboard', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz Dashboard Page'), findsOneWidget);
    });

    testWidgets('tapping Challenge opens challenge dialog', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Challenge'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
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

    testWidgets('fromPostComposer: true renders contextual attachment menu', (tester) async {
      tester.view.physicalSize = const Size(600, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool mediaSelected = false;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GlobalCreateSheet.show(
                  context,
                  fromPostComposer: true,
                  onSelectMedia: () => mediaSelected = true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Media'), findsOneWidget);
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();

      expect(mediaSelected, isTrue);
    });
  });
}
