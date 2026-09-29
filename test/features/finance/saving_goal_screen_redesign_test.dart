import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_detail.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceSavingGoalEntity _mockGoal({
  String id = 'goal-1',
  String title = 'Macbook Pro M3',
  double target = 1000.0,
  double current = 100.0,
  int progress = 10,
  String status = 'IN_PROGRESS',
  String? targetDate = '2026-10-09',
  FinanceCurrency currency = FinanceCurrency.usd,
}) {
  return FinanceSavingGoalEntity(
    savingGoalId: id,
    title: title,
    targetAmount: target,
    currentAmount: current,
    remainingAmount: target - current,
    progressPercent: progress,
    targetDate: targetDate,
    status: status,
    currency: currency,
  );
}

FinanceSavingDepositEntity _mockDeposit({
  String id = 'dep-1',
  double amount = 100.0,
  String note = 'Initial deposit',
  String date = '2026-09-01',
}) {
  return FinanceSavingDepositEntity(
    depositId: id,
    amount: amount,
    note: note,
    depositDate: date,
  );
}

FinanceDashboardEntity _mockDashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: 50.0,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 5000.0,
      totalSaved: 1250.0,
      progressPercent: 25,
      activeGoals: 4,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late SavingGoalController savingGoalController;

  final sampleGoals = [
    _mockGoal(
      id: 'g-1',
      title: 'Macbook Pro M3',
      target: 2000.0,
      current: 500.0,
      progress: 25,
      targetDate: '2026-10-09',
    ),
    _mockGoal(
      id: 'g-2',
      title: 'New Car',
      target: 15000.0,
      current: 4500.0,
      progress: 30,
      targetDate: '2027-01-01',
    ),
    _mockGoal(
      id: 'g-3',
      title: 'Japan Trip Vacation',
      target: 3000.0,
      current: 1500.0,
      progress: 50,
      targetDate: '2026-12-25',
    ),
    _mockGoal(
      id: 'g-4',
      title: 'Emergency Fund',
      target: 5000.0,
      current: 5000.0,
      progress: 100,
      status: 'COMPLETED',
      targetDate: null,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    repository = _MockFinanceRepository();
    when(
      () => repository.getFinanceDashboard(currency: any(named: 'currency')),
    ).thenAnswer((_) async => _mockDashboard(FinanceCurrency.usd));

    when(
      () => repository.getSavingGoals(
        status: any<String?>(named: 'status'),
        currency: any<FinanceCurrency?>(named: 'currency'),
      ),
    ).thenAnswer((_) async => sampleGoals);

    when(
      () => repository.getSavingGoal(any()),
    ).thenAnswer((_) async => sampleGoals.first);

    when(
      () => repository.getSavingDeposits(any()),
    ).thenAnswer(
      (_) async => [
        _mockDeposit(id: 'd-1', amount: 100.0, note: 'Initial deposit', date: '2026-09-01'),
        _mockDeposit(id: 'd-2', amount: 400.0, note: 'Bonus contribution', date: '2026-09-15'),
      ],
    );

    financeController = FinanceController(repository: repository);
    savingGoalController = SavingGoalController(
      repository: repository,
      financeController: financeController,
    );

    Get.put<FinanceController>(financeController);
    Get.put<SavingGoalController>(savingGoalController);
  });

  tearDown(Get.reset);

  Widget buildTestApp({
    Widget? home,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en', 'US'),
  }) {
    final isDark = brightness == Brightness.dark;
    Get.locale = locale;
    return GetMaterialApp(
      locale: locale,
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: isDark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
      ),
      home: home ?? const SavingGoalsScreen(),
    );
  }

  testWidgets(
    'renders redesigned SavingGoalsScreen with Hero total card, categories, and zero overflow',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Top Bar
      expect(find.text('Saving Goals'), findsOneWidget);
      expect(find.text('Turn your dreams into reality'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Currency Pill
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('KHR'), findsOneWidget);

      // Hero Total Saved Card
      expect(find.text('Total Saved'), findsOneWidget);
      expect(find.text(r'$11,500.00'), findsOneWidget);
      expect(find.text('+12% from last month'), findsNothing);
      expect(find.text('Across 4 goals'), findsOneWidget);

      // Section Header
      expect(find.text('Your Goals'), findsOneWidget);
      expect(find.text('Newest first'), findsOneWidget);

      // Goal Cards
      expect(find.text('Macbook Pro M3'), findsOneWidget);
      expect(find.text('Due Oct 9, 2026'), findsOneWidget);
      expect(find.text('New Car'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Japan Trip Vacation'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    r'handles massive amounts ($999,900,000.00) without RenderFlex overflow',
    (tester) async {
      final hugeGoal = _mockGoal(
        id: 'huge-1',
        title: 'Penthouse Investment Fund',
        target: 999900000.0,
        current: 500000000.0,
        progress: 50,
      );

      when(
        () => repository.getSavingGoals(
          status: any<String?>(named: 'status'),
          currency: any<FinanceCurrency?>(named: 'currency'),
        ),
      ).thenAnswer((_) async => [hugeGoal]);

      await savingGoalController.loadGoals();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(r'$500,000,000.00'), findsOneWidget);
      expect(find.text('Penthouse Investment Fund'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly on narrow 320px screen width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 3.0, 700 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Saving Goals'), findsOneWidget);
      expect(find.text('Total Saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders in Dark mode with proper theme contrast',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saving Goals'), findsOneWidget);
      expect(find.text('Macbook Pro M3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders with Khmer locale (km_KH) cleanly',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(locale: const Locale('km', 'KH')),
      );
      await tester.pumpAndSettle();

      // Khmer titles and labels
      expect(find.text('គោលដៅសន្សំ'), findsOneWidget);
      expect(find.text('ប្រែក្លាយក្តីស្រមៃរបស់អ្នកឱ្យក្លាយជាការពិត'), findsOneWidget);
      expect(find.text('សន្សំបានសរុប'), findsOneWidget);
      expect(find.text('គោលដៅរបស់អ្នក'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders redesigned GoalDetailScreen with summary, progress, 3 stat tiles, and sticky CTA',
    (tester) async {
      final goal = sampleGoals.first;
      await tester.pumpWidget(
        buildTestApp(
          home: GoalDetailScreen(goal: goal),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Macbook Pro M3'), findsWidgets);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Summary Card
      expect(
        find.text('Keep saving to reach your dream target on schedule.'),
        findsOneWidget,
      );

      // Progress Card
      expect(find.text('Current amount'), findsOneWidget);
      expect(find.text(r'$500.00'), findsOneWidget);
      expect(find.text('Target amount'), findsOneWidget);
      expect(find.text(r'$2,000.00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);

      // 3 Stat Tiles
      expect(find.text('Deadline'), findsOneWidget);
      expect(find.text('Oct 9, 2026'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text(r'$1,500.00'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      // Deposit History
      final historyFinder = find.text('Contribution history');
      await tester.scrollUntilVisible(historyFinder, 200);
      expect(historyFinder, findsOneWidget);
      expect(find.text('Initial deposit'), findsOneWidget);
      expect(find.text(r'+$100.00'), findsOneWidget);
      expect(find.text('Bonus contribution'), findsOneWidget);
      expect(find.text(r'+$400.00'), findsOneWidget);

      // Bottom Sticky Button
      expect(find.text('Add contribution'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
