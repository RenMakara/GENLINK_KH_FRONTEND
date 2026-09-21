import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceBudgetEntity _mockBudget({
  FinanceCurrency currency = FinanceCurrency.usd,
  double total = 100.00,
  double spent = 100000.00,
}) {
  return FinanceBudgetEntity(
    budgetId: 'budget-101',
    month: 9,
    year: 2026,
    totalBudget: total,
    spentAmount: spent,
    remainingAmount: total - spent,
    status: 'LIMIT_REACHED',
    currency: currency,
    categories: [
      FinanceCategoryBudget(
        category: 'Food',
        allocatedAmount: 10.00,
        spentAmount: 0.00,
        remainingAmount: 10.00,
      ),
      FinanceCategoryBudget(
        category: 'Travel',
        allocatedAmount: 20.00,
        spentAmount: 0.00,
        remainingAmount: 20.00,
      ),
      FinanceCategoryBudget(
        category: 'Transport',
        allocatedAmount: 20.00,
        spentAmount: 0.00,
        remainingAmount: 20.00,
      ),
      FinanceCategoryBudget(
        category: 'Bills',
        allocatedAmount: 50.00,
        spentAmount: 100000.00,
        remainingAmount: -99950.00,
      ),
    ],
  );
}

FinanceDashboardEntity _mockDashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: 100000.00,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 1000.0,
      totalSaved: 100.0,
      progressPercent: 10,
      activeGoals: 1,
    ),
    recentExpenses: const [],
    financialTip:
        'Try adjusting your budget or review your spending to stay on track next month.',
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late BudgetController budgetController;

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
      () => repository.getCurrentBudget(
        currency: any(named: 'currency'),
        month: any(named: 'month'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => _mockBudget(currency: FinanceCurrency.usd));

    financeController = FinanceController(repository: repository);
    budgetController = BudgetController(
      repository: repository,
      financeController: financeController,
    )
      ..selectedMonth.value = 9
      ..selectedYear.value = 2026;

    Get.put<FinanceController>(financeController);
    Get.put<BudgetController>(budgetController);
  });

  tearDown(Get.reset);

  Widget buildTestApp({Brightness brightness = Brightness.light}) {
    return GetMaterialApp(
      theme: ThemeData(
        brightness: brightness,
        fontFamily: 'Sora',
        scaffoldBackgroundColor: brightness == Brightness.dark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
      ),
      home: const BudgetScreen(),
    );
  }

  testWidgets('renders all redesigned sections, limit-reached warning, and extreme percentages without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Plan today for a better tomorrow'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // 2. Currency Bar
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('KHR'), findsOneWidget);

    // 3. Period Bar
    expect(find.text('September 2026'), findsOneWidget);

    // 4. Main Budget Card
    expect(find.text('Total Budget'), findsWidgets);
    expect(find.text(r'$100.00'), findsWidgets);
    expect(find.text('Limit Reached'), findsOneWidget);
    expect(find.text('100000% used'), findsOneWidget);
    expect(find.text(r'-$99,900.00 remaining'), findsOneWidget);

    // Exceeded warning banner
    expect(find.text("You've exceeded your budget"), findsOneWidget);
    expect(find.text('Your spending is \$99,900.00 over the limit.'), findsOneWidget);

    // 5. Budget Overview (scroll down)
    expect(find.text('Budget Overview'), findsOneWidget);
    expect(find.text(r'$100,000.00'), findsWidgets);

    // 6. Category Budgets (scroll into view)
    final categoryBudgetsFinder = find.text('Category Budgets');
    await tester.scrollUntilVisible(categoryBudgetsFinder, 200);
    expect(categoryBudgetsFinder, findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    // Scroll to Bills with extreme percentage 200000%
    await tester.scrollUntilVisible(find.text('Bills'), 200);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('200000%'), findsOneWidget);

    // 7. Smart Tip
    final smartTipFinder = find.text('Smart Tip');
    await tester.scrollUntilVisible(smartTipFinder, 200);
    expect(smartTipFinder, findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders properly in dark mode with semantic colors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Plan today for a better tomorrow'), findsOneWidget);
    expect(find.text(r'$100.00'), findsWidgets);
    expect(find.text("You've exceeded your budget"), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders properly in Khmer locale with zero overflow', (tester) async {
    Get.locale = const Locale('km', 'KH');

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Khmer title and subtitle
    expect(find.text('ការកំណត់ថវិកា'), findsOneWidget);
    expect(find.text('រៀបចំផែនការថ្ងៃនេះ ដើម្បីអនាគតល្អប្រសើរ'), findsOneWidget);
    expect(find.text('ដល់កម្រិតកំណត់'), findsOneWidget);
    expect(find.text('អ្នកបានចំណាយលើសថវិកាហើយ'), findsOneWidget);
    expect(find.text('ទិដ្ឋភាពទូទៅនៃថវិកា'), findsOneWidget);

    final kmCatFinder = find.text('ថវិកាតាមប្រភេទ');
    await tester.scrollUntilVisible(kmCatFinder, 200);
    expect(kmCatFinder, findsOneWidget);

    final kmTipFinder = find.text('គន្លឹះឆ្លាតវៃ');
    await tester.scrollUntilVisible(kmTipFinder, 200);
    expect(kmTipFinder, findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('supports narrow small screen (320px width) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text(r'$100.00'), findsWidgets);
    expect(find.text("You've exceeded your budget"), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('supports large amounts (\$100,000,000.00) without overflow', (tester) async {
    when(
      () => repository.getCurrentBudget(
        currency: any(named: 'currency'),
        month: any(named: 'month'),
        year: any(named: 'year'),
      ),
    ).thenAnswer(
      (_) async => _mockBudget(
        currency: FinanceCurrency.usd,
        total: 100000000.00,
        spent: 150000000.00,
      ),
    );

    budgetController.load();

    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text(r'$100,000,000.00'), findsWidgets);
    expect(find.text(r'$150,000,000.00'), findsWidgets);

    expect(tester.takeException(), isNull);
  });
}
