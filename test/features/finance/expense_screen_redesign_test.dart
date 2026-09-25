import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_widget.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceDashboardEntity _mockDashboard({
  required FinanceCurrency currency,
  double spent = 100000000.00,
}) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: spent,
      budgetTotal: 120000000.00,
      budgetRemaining: 20000000.00,
      budgetStatus: 'SAFE',
    ),
    topCategories: [
      FinanceCategorySpend(
        category: 'BILLS',
        currency: currency,
        amount: 60000000.00,
      ),
      FinanceCategorySpend(
        category: 'FOOD',
        currency: currency,
        amount: 20000000.00,
      ),
      FinanceCategorySpend(
        category: 'TRANSPORT',
        currency: currency,
        amount: 10000000.00,
      ),
      FinanceCategorySpend(
        category: 'SHOPPING',
        currency: currency,
        amount: 5000000.00,
      ),
      FinanceCategorySpend(
        category: 'OTHER',
        currency: currency,
        amount: 5000000.00,
      ),
    ],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 1000000.0,
      totalSaved: 500000.0,
      progressPercent: 50,
      activeGoals: 2,
    ),
    recentExpenses: const [],
  );
}

FinanceExpenseEntity _mockExpense({
  required String id,
  required String title,
  required double amount,
  required String category,
  required String date,
  FinanceCurrency currency = FinanceCurrency.usd,
}) {
  return FinanceExpenseEntity(
    expenseId: id,
    title: title,
    amount: amount,
    currency: currency,
    category: category,
    expenseDate: date,
    paidFromWallet: true,
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late ExpenseController expenseController;

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
    ).thenAnswer((_) async => _mockDashboard(currency: FinanceCurrency.usd));

    when(
      () => repository.getExpenses(
        category: any(named: 'category'),
        currency: any(named: 'currency'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => FinancePage<FinanceExpenseEntity>(
        content: [
          _mockExpense(
            id: 'exp-1',
            title: 'Buy new car',
            amount: 100000000.00,
            category: 'BILLS',
            date: '2026-09-17',
          ),
          _mockExpense(
            id: 'exp-2',
            title: 'Lunch at café',
            amount: 15.50,
            category: 'FOOD',
            date: '2026-09-16',
          ),
          _mockExpense(
            id: 'exp-3',
            title: 'Taxi to office',
            amount: 8.00,
            category: 'TRANSPORT',
            date: '2026-09-16',
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 3,
        totalPages: 1,
        hasNext: false,
      ),
    );

    financeController = FinanceController(repository: repository);
    expenseController = ExpenseController(
      repository: repository,
      financeController: financeController,
    );

    Get.put<FinanceController>(financeController);
    Get.put<ExpenseController>(expenseController);
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
      home: const ExpenseScreen(),
    );
  }

  testWidgets('renders all redesigned sections without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Track and manage your spending'), findsOneWidget);
    expect(find.byType(ExpenseAddButton), findsOneWidget);

    // 2. Currency Bar
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('KHR'), findsOneWidget);

    // 3. Period Bar
    expect(find.byType(ExpensePeriodBar), findsOneWidget);
    expect(find.text('Sep 2026'), findsOneWidget);

    // 4. Spending Summary Card
    expect(find.text('Total Spent'), findsOneWidget);
    expect(find.text(r'$100,000,000.00'), findsOneWidget);
    expect(find.byType(ExpenseDonut), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text(r'$100.0M'), findsOneWidget);

    // 5. Category Breakdown
    expect(find.text('Category Breakdown'), findsOneWidget);
    expect(find.text('Bills'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);

    // 6. Recent Expenses (scroll into view)
    final recentExpensesFinder = find.text('Recent Expenses');
    await tester.scrollUntilVisible(find.text('Lunch at café'), 200);
    expect(recentExpensesFinder, findsOneWidget);
    expect(find.text('Buy new car'), findsOneWidget);
    expect(find.text('Lunch at café'), findsOneWidget);
    expect(find.text(r'-$100,000,000.00'), findsOneWidget);
    expect(find.text(r'-$15.50'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders properly in dark mode with semantic colors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Track and manage your spending'), findsOneWidget);
    expect(find.text(r'$100,000,000.00'), findsOneWidget);

    final recentFinder = find.text('Recent Expenses');
    await tester.scrollUntilVisible(recentFinder, 200);
    expect(recentFinder, findsOneWidget);
    expect(find.text('Buy new car'), findsOneWidget);

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
    expect(find.text('ចំណាយ'), findsOneWidget);
    expect(find.text('តាមដាន និងគ្រប់គ្រងការចំណាយរបស់អ្នក'), findsOneWidget);
    expect(find.text('ចំណាយសរុប'), findsOneWidget);
    expect(find.text('ការបែងចែកចំណាយ'), findsOneWidget);

    final kmRecentFinder = find.text('ចំណាយថ្មីៗ');
    await tester.scrollUntilVisible(kmRecentFinder, 200);
    expect(kmRecentFinder, findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('supports narrow small screen (320px width) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text(r'$100,000,000.00'), findsOneWidget);

    final narrowRecentFinder = find.text('Recent Expenses');
    await tester.scrollUntilVisible(find.text('Buy new car'), 200);
    expect(narrowRecentFinder, findsOneWidget);
    expect(find.text('Buy new car'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
