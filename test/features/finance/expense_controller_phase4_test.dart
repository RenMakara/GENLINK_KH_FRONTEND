import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceExpenseEntity _expense({
  String id = 'expense-1',
  FinanceCurrency currency = FinanceCurrency.usd,
  String category = 'FOOD',
  double amount = 5,
}) {
  return FinanceExpenseEntity(
    expenseId: id,
    title: 'Lunch',
    amount: amount,
    currency: currency,
    category: category,
    description: 'Cafe',
    expenseDate: '2026-08-20',
    paymentMethod: 'CASH',
    paidFromWallet: false,
    createdAt: '2026-08-20T10:00:00Z',
  );
}

FinancePage<FinanceExpenseEntity> _page(
  List<FinanceExpenseEntity> content, {
  int page = 0,
  bool hasNext = false,
  int? totalElements,
}) {
  return FinancePage(
    content: content,
    page: page,
    size: 20,
    totalElements: totalElements ?? content.length,
    totalPages: hasNext ? page + 2 : page + 1,
    hasNext: hasNext,
  );
}

FinanceDashboardEntity _dashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 8,
      year: 2026,
      currency: currency,
      spent: 5,
    ),
    topCategories: [
      FinanceCategorySpend(category: 'FOOD', currency: currency, amount: 5),
    ],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 0,
      totalSaved: 0,
      progressPercent: 0,
      activeGoals: 0,
    ),
    recentExpenses: [_recentExpense(currency)],
  );
}

FinanceRecentExpense _recentExpense(FinanceCurrency currency) {
  return FinanceRecentExpense(
    expenseId: 'expense-1',
    title: 'Lunch',
    category: 'FOOD',
    currency: currency,
    amount: 5,
    expenseDate: '2026-08-20',
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late ExpenseController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller = ExpenseController(
      repository: repository,
      financeController: financeController,
    );
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.khr));
  });

  tearDown(Get.reset);

  test('loads page zero with the selected currency', () async {
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_expense()]));

    await controller.loadInitial();

    expect(controller.expenses.single.expenseId, 'expense-1');
    expect(controller.currentPage.value, 0);
    expect(controller.totalElements.value, 1);
    expect(controller.hasNextPage.value, isFalse);
    verify(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).called(1);
  });

  test(
    'loads the selected period budget categories for expense entry',
    () async {
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 9,
          year: 2026,
        ),
      ).thenAnswer(
        (_) async => const FinanceBudgetEntity(
          budgetId: 'budget-1',
          month: 9,
          year: 2026,
          totalBudget: 400000,
          spentAmount: 5000,
          remainingAmount: 395000,
          status: 'SAFE',
          currency: FinanceCurrency.usd,
          categories: [
            FinanceCategoryBudget(
              category: 'Drink',
              allocatedAmount: 100000,
              spentAmount: 0,
              remainingAmount: 100000,
            ),
            FinanceCategoryBudget(
              category: 'Food',
              allocatedAmount: 200000,
              spentAmount: 5000,
              remainingAmount: 195000,
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

      await controller.loadBudgetCategories(
        currency: FinanceCurrency.usd,
        month: 9,
        year: 2026,
      );

      expect(controller.budgetCategories, ['Drink', 'Food', 'Travel']);
    },
  );

  test('exposes initial list errors without fake rows', () async {
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenThrow(
      const AppError(
        message: 'Expense service unavailable',
        errorCode: 'API_ERROR',
      ),
    );

    await controller.loadInitial();

    expect(controller.expenses, isEmpty);
    expect(controller.listErrorMessage.value, 'Expense service unavailable');
  });

  test(
    'currency changes reset the list and send KHR before pagination',
    () async {
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.khr,
          page: 0,
          size: 20,
        ),
      ).thenAnswer(
        (_) async =>
            _page([_expense(id: 'khr-1', currency: FinanceCurrency.khr)]),
      );

      await controller.selectCurrency(FinanceCurrency.khr);

      expect(controller.selectedCurrency.value, FinanceCurrency.khr);
      expect(controller.expenses.single.currency, FinanceCurrency.khr);
      verify(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.khr,
          page: 0,
          size: 20,
        ),
      ).called(1);
    },
  );

  test(
    'category filter uses the exact backend value and resets pagination',
    () async {
      when(
        () => repository.getExpenses(
          category: 'TRANSPORT',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer(
        (_) async => _page([_expense(id: 'transport', category: 'TRANSPORT')]),
      );

      await controller.selectCategory(' transport ');

      expect(controller.selectedCategory.value, 'TRANSPORT');
      expect(controller.currentPage.value, 0);
      verify(
        () => repository.getExpenses(
          category: 'TRANSPORT',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).called(1);
    },
  );

  test('next pages append and deduplicate by stable expense id', () async {
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_expense(id: 'one')], hasNext: true));
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenAnswer(
      (_) async => _page(
        [_expense(id: 'one'), _expense(id: 'two')],
        page: 1,
        totalElements: 3,
      ),
    );

    await controller.loadInitial();
    await controller.loadNextPage();

    expect(controller.expenses.map((item) => item.expenseId), ['one', 'two']);
    expect(controller.currentPage.value, 1);
    expect(controller.totalElements.value, 3);
  });

  test('pagination errors preserve already loaded expenses', () async {
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_expense()], hasNext: true));
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenThrow(const AppError(message: 'Page failed', errorCode: 'API_ERROR'));

    await controller.loadInitial();
    await controller.loadNextPage();

    expect(controller.expenses, hasLength(1));
    expect(controller.paginationErrorMessage.value, 'Page failed');
    expect(controller.currentPage.value, 0);
  });

  test(
    'refresh replaces rows with page zero and keeps active filters',
    () async {
      var calls = 0;
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) async {
        calls++;
        return _page([_expense(id: 'fresh-$calls')]);
      });

      await controller.loadInitial();
      await controller.refresh();

      expect(controller.expenses.single.expenseId, 'fresh-2');
      verify(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).called(2);
    },
  );

  test(
    'stale currency response cannot overwrite the current selection',
    () async {
      final usd = Completer<FinancePage<FinanceExpenseEntity>>();
      final khr = Completer<FinancePage<FinanceExpenseEntity>>();
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) => usd.future);
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.khr,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) => khr.future);

      final first = controller.loadInitial();
      final second = controller.selectCurrency(FinanceCurrency.khr);
      usd.complete(_page([_expense(id: 'usd')], totalElements: 1));
      await first;
      expect(controller.expenses, isEmpty);
      khr.complete(_page([_expense(id: 'khr', currency: FinanceCurrency.khr)]));
      await second;

      expect(controller.expenses.single.expenseId, 'khr');
      expect(controller.selectedCurrency.value, FinanceCurrency.khr);
    },
  );

  test('refresh failure keeps the last successful rows visible', () async {
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_expense()]));
    await controller.loadInitial();
    reset(repository);
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenThrow(
      const AppError(message: 'Refresh failed', errorCode: 'API_ERROR'),
    );

    await controller.refresh();

    expect(controller.expenses.single.expenseId, 'expense-1');
    expect(controller.listErrorMessage.value, 'Refresh failed');
    expect(controller.isRefreshing.value, isFalse);
  });

  test('refresh during page loading does not leave pagination stuck', () async {
    final nextPage = Completer<FinancePage<FinanceExpenseEntity>>();
    final refreshedPage = Completer<FinancePage<FinanceExpenseEntity>>();
    var pageZeroCalls = 0;
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) {
      pageZeroCalls++;
      return pageZeroCalls == 1
          ? Future.value(_page([_expense()], hasNext: true))
          : refreshedPage.future;
    });
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenAnswer((_) => nextPage.future);

    await controller.loadInitial();
    final loadingNextPage = controller.loadNextPage();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isLoadingMore.value, isTrue);

    final refreshing = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isLoadingMore.value, isFalse);

    nextPage.complete(_page([_expense(id: 'next')], page: 1));
    await loadingNextPage;
    refreshedPage.complete(_page([_expense(id: 'refreshed')]));
    await refreshing;

    expect(controller.isLoadingMore.value, isFalse);
    expect(controller.expenses.single.expenseId, 'refreshed');
  });

  test(
    'refresh during initial load clears the stale initial indicator',
    () async {
      final initialPage = Completer<FinancePage<FinanceExpenseEntity>>();
      final refreshedPage = Completer<FinancePage<FinanceExpenseEntity>>();
      var pageZeroCalls = 0;
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) {
        pageZeroCalls++;
        return pageZeroCalls == 1 ? initialPage.future : refreshedPage.future;
      });

      final loading = controller.loadInitial();
      expect(controller.isInitialLoading.value, isTrue);
      final refreshing = controller.refresh();
      expect(controller.isInitialLoading.value, isFalse);
      expect(controller.isRefreshing.value, isTrue);

      refreshedPage.complete(_page([_expense(id: 'refreshed')]));
      await refreshing;
      initialPage.complete(_page([_expense(id: 'stale')]));
      await loading;

      expect(controller.isInitialLoading.value, isFalse);
      expect(controller.isRefreshing.value, isFalse);
      expect(controller.expenses.single.expenseId, 'refreshed');
    },
  );

  test(
    'create sends the selected currency and refreshes list/dashboard',
    () async {
      when(
        () => repository.createExpense(
          title: 'Lunch',
          amount: 5,
          expenseDate: '2026-08-20',
          category: 'FOOD',
          description: 'Cafe',
          paymentMethod: 'CASH',
          paidFromWallet: true,
          currency: FinanceCurrency.usd,
        ),
      ).thenAnswer((_) async => _expense());
      when(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) async => _page([_expense()]));

      expect(
        await controller.createExpense(
          title: 'Lunch',
          amount: 5,
          expenseDate: '2026-08-20',
          category: 'FOOD',
          description: 'Cafe',
          paymentMethod: 'CASH',
          paidFromWallet: true,
        ),
        isTrue,
      );
      verify(
        () => repository.getExpenses(
          category: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).called(1);
      verify(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).called(1);
    },
  );

  test('invalid create amount is blocked before the API', () async {
    expect(
      await controller.createExpense(
        title: 'Invalid',
        amount: 0,
        expenseDate: '2026-08-20',
      ),
      isFalse,
    );
    verifyNever(
      () => repository.createExpense(
        title: 'Invalid',
        amount: 0,
        expenseDate: '2026-08-20',
        category: null,
        description: null,
        paymentMethod: null,
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    );
  });

  test('create double-submit protection allows one request', () async {
    final gate = Completer<FinanceExpenseEntity>();
    when(
      () => repository.createExpense(
        title: 'Lunch',
        amount: 5,
        expenseDate: '2026-08-20',
        category: null,
        description: null,
        paymentMethod: null,
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => gate.future);
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    final first = controller.createExpense(
      title: 'Lunch',
      amount: 5,
      expenseDate: '2026-08-20',
    );
    final second = controller.createExpense(
      title: 'Lunch',
      amount: 5,
      expenseDate: '2026-08-20',
    );
    expect(await second, isFalse);
    gate.complete(_expense());
    expect(await first, isTrue);
    verify(
      () => repository.createExpense(
        title: 'Lunch',
        amount: 5,
        expenseDate: '2026-08-20',
        category: null,
        description: null,
        paymentMethod: null,
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('create failure preserves the form operation state and error', () async {
    when(
      () => repository.createExpense(
        title: 'Lunch',
        amount: 5,
        expenseDate: '2026-08-20',
        category: null,
        description: null,
        paymentMethod: null,
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(message: 'Wallet too low', errorCode: 'VALIDATION_ERROR'),
    );

    expect(
      await controller.createExpense(
        title: 'Lunch',
        amount: 5,
        expenseDate: '2026-08-20',
      ),
      isFalse,
    );
    expect(controller.mutationErrorMessage.value, 'Wallet too low');
    expect(controller.isCreateSubmitting.value, isFalse);
  });

  test('update sends PUT fields and refreshes state', () async {
    final existing = _expense(amount: 10);
    when(
      () => repository.updateExpense(
        expenseId: 'expense-1',
        title: 'Dinner',
        amount: 8,
        expenseDate: '2026-08-21',
        category: 'BILLS',
        description: 'Updated',
        paymentMethod: 'CARD',
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async => existing);
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([existing]));

    expect(
      await controller.updateExpense(
        existing: existing,
        title: 'Dinner',
        amount: 8,
        expenseDate: '2026-08-21',
        category: 'BILLS',
        description: 'Updated',
        paymentMethod: 'CARD',
        paidFromWallet: false,
      ),
      isTrue,
    );
    verify(
      () => repository.updateExpense(
        expenseId: 'expense-1',
        title: 'Dinner',
        amount: 8,
        expenseDate: '2026-08-21',
        category: 'BILLS',
        description: 'Updated',
        paymentMethod: 'CARD',
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('update failure does not report success', () async {
    final existing = _expense();
    when(
      () => repository.updateExpense(
        expenseId: 'expense-1',
        title: 'Lunch',
        amount: 6,
        expenseDate: '2026-08-20',
        category: 'FOOD',
        description: 'Cafe',
        paymentMethod: 'CASH',
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(message: 'Update failed', errorCode: 'API_ERROR'),
    );

    expect(
      await controller.updateExpense(
        existing: existing,
        title: 'Lunch',
        amount: 6,
        expenseDate: '2026-08-20',
        category: 'FOOD',
        description: 'Cafe',
        paymentMethod: 'CASH',
        paidFromWallet: false,
      ),
      isFalse,
    );
    expect(controller.mutationErrorMessage.value, 'Update failed');
  });

  test('update double-submit protection allows one request', () async {
    final existing = _expense();
    final gate = Completer<FinanceExpenseEntity>();
    when(
      () => repository.updateExpense(
        expenseId: 'expense-1',
        title: 'Lunch',
        amount: 6,
        expenseDate: '2026-08-20',
        category: 'FOOD',
        description: 'Cafe',
        paymentMethod: 'CASH',
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => gate.future);

    final first = controller.updateExpense(
      existing: existing,
      title: 'Lunch',
      amount: 6,
      expenseDate: '2026-08-20',
      category: 'FOOD',
      description: 'Cafe',
      paymentMethod: 'CASH',
      paidFromWallet: false,
    );
    final second = controller.updateExpense(
      existing: existing,
      title: 'Lunch',
      amount: 6,
      expenseDate: '2026-08-20',
      category: 'FOOD',
      description: 'Cafe',
      paymentMethod: 'CASH',
      paidFromWallet: false,
    );
    expect(await second, isFalse);
    gate.complete(existing);
    expect(await first, isTrue);
    verify(
      () => repository.updateExpense(
        expenseId: 'expense-1',
        title: 'Lunch',
        amount: 6,
        expenseDate: '2026-08-20',
        category: 'FOOD',
        description: 'Cafe',
        paymentMethod: 'CASH',
        paidFromWallet: false,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('delete only refreshes/removes after backend success', () async {
    when(() => repository.deleteExpense('expense-1')).thenAnswer((_) async {});
    when(
      () => repository.getExpenses(
        category: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    expect(await controller.deleteExpense('expense-1'), isTrue);
    expect(controller.expenses, isEmpty);
    verify(() => repository.deleteExpense('expense-1')).called(1);
  });

  test('detail factory preserves backend values and currency context', () {
    final screen = ExpenseDetailScreen.fromEntity(_expense(amount: 12.5));
    expect(screen.expenseId, 'expense-1');
    expect(screen.currency, FinanceCurrency.usd);
    expect(screen.date, '2026-08-20');
    expect(screen.amount, r'-$12.50');
  });

  test(
    'delete failure keeps the existing list and prevents duplicate calls',
    () async {
      final gate = Completer<void>();
      when(
        () => repository.deleteExpense('expense-1'),
      ).thenAnswer((_) => gate.future);
      controller.expenses.add(_expense());

      final first = controller.deleteExpense('expense-1');
      final second = controller.deleteExpense('expense-1');
      expect(await second, isFalse);
      gate.completeError(
        const AppError(message: 'Delete failed', errorCode: 'API_ERROR'),
      );
      expect(await first, isFalse);
      expect(controller.expenses.single.expenseId, 'expense-1');
      expect(controller.mutationErrorMessage.value, 'Delete failed');
      verify(() => repository.deleteExpense('expense-1')).called(1);
    },
  );
}
