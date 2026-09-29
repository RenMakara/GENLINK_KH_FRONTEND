import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  late _MockFinanceRepository repository;

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();

    when(
      () => repository.getFinanceDashboard(currency: any(named: 'currency')),
    ).thenAnswer((invocation) async {
      final currency = invocation.namedArguments[#currency] as FinanceCurrency;
      return FinanceDashboardEntity(
        currency: currency,
        month: FinanceMonthOverview(
          month: DateTime.now().month,
          year: DateTime.now().year,
          currency: currency,
          spent: 0,
        ),
        topCategories: const [],
        saving: FinanceSavingProgress(
          currency: currency,
          totalTarget: 0,
          totalSaved: 0,
          progressPercent: 0,
          activeGoals: 0,
        ),
        recentExpenses: const [],
      );
    });
    when(
      () => repository.getExpenses(
        category: any(named: 'category'),
        currency: any(named: 'currency'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const FinancePage<FinanceExpenseEntity>(
        content: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        hasNext: false,
      ),
    );
    final now = DateTime.now();
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: now.month,
        year: now.year,
      ),
    ).thenAnswer(
      (_) async => FinanceBudgetEntity(
        budgetId: 'budget-current',
        month: now.month,
        year: now.year,
        totalBudget: 400000,
        spentAmount: 0,
        remainingAmount: 400000,
        status: 'SAFE',
        currency: FinanceCurrency.usd,
        categories: const [
          FinanceCategoryBudget(
            category: 'Drink',
            allocatedAmount: 100000,
            spentAmount: 0,
            remainingAmount: 100000,
          ),
          FinanceCategoryBudget(
            category: 'Food',
            allocatedAmount: 200000,
            spentAmount: 0,
            remainingAmount: 200000,
          ),
          FinanceCategoryBudget(
            category: 'Travel',
            allocatedAmount: 100000,
            spentAmount: 0,
            remainingAmount: 100000,
          ),
        ],
      ),
    );
  });

  tearDown(Get.reset);

  testWidgets(
    'expense categories include custom categories from the active budget',
    (tester) async {
      final financeController = FinanceController(repository: repository);
      Get.put<FinanceController>(financeController);
      Get.put<ExpenseController>(
        ExpenseController(
          repository: repository,
          financeController: financeController,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AddExpenseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drink'), findsOneWidget);
      expect(find.text('Food & Drinks'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
