import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/data/models/finance_models.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceBudgetEntity _budget({
  FinanceCurrency currency = FinanceCurrency.usd,
  int month = 8,
  int year = 2026,
  String id = 'budget-1',
  double total = 900,
  double spent = 250,
  List<FinanceCategoryBudget> categories = const [],
}) {
  return FinanceBudgetEntity(
    budgetId: id,
    month: month,
    year: year,
    totalBudget: total,
    spentAmount: spent,
    remainingAmount: total - spent,
    status: spent >= total
        ? 'LIMIT_REACHED'
        : spent >= total * .8
        ? 'WARNING'
        : 'SAFE',
    currency: currency,
    categories: categories,
  );
}

FinanceDashboardEntity _dashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 8,
      year: 2026,
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
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late BudgetController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller =
        BudgetController(
            repository: repository,
            financeController: financeController,
          )
          ..selectedMonth.value = 8
          ..selectedYear.value = 2026;
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.khr));
  });

  tearDown(Get.reset);

  test(
    'loads the current USD budget with an explicit month/year/currency',
    () async {
      final value = _budget();
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) async => value);

      await controller.load();

      expect(controller.budget.value, same(value));
      expect(controller.isEmpty, isFalse);
      verify(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).called(1);
    },
  );

  test(
    'maps backend calculated fields and free-text categories without guessing',
    () {
      final value = FinanceMapper.budget({
        'budgetId': 'budget-1',
        'month': 8,
        'year': 2026,
        'totalBudget': 900,
        'spentAmount': 250,
        'remainingAmount': 650,
        'status': 'WARNING',
        'currency': 'USD',
        'categories': [
          {
            'category': 'Entertainment & Events',
            'allocatedAmount': 300,
            'spentAmount': 250,
            'remainingAmount': 50,
          },
        ],
      });

      expect(value.status, 'WARNING');
      expect(value.remainingAmount, 650);
      expect(value.categories.single.category, 'Entertainment & Events');
      expect(value.categories.single.remainingAmount, 50);
    },
  );

  test('serializes the documented budget request fields and currency', () {
    final json = FinanceBudgetRequestModel(
      month: 8,
      year: 2026,
      totalBudget: 900,
      currency: FinanceCurrency.khr,
      categories: const [
        FinanceBudgetCategoryRequestModel(
          category: 'Food & Drink',
          allocatedAmount: 300,
        ),
      ],
    ).toJson();

    expect(json, {
      'month': 8,
      'year': 2026,
      'totalBudget': 900,
      'currency': 'KHR',
      'categories': [
        {'category': 'Food & Drink', 'allocatedAmount': 300},
      ],
    });
  });

  test('loads KHR as a separate budget scope', () async {
    final value = _budget(currency: FinanceCurrency.khr, total: 300000);
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => value);

    controller.selectedCurrency.value = FinanceCurrency.khr;
    await controller.load();

    expect(controller.budget.value?.currency, FinanceCurrency.khr);
    verify(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).called(1);
  });

  test('treats a missing current budget as an empty state', () async {
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenThrow(
      const AppError(
        message: 'Not found',
        errorCode: 'NOT_FOUND',
        statusCode: 404,
      ),
    );

    await controller.load();

    expect(controller.budget.value, isNull);
    expect(controller.listErrorMessage.value, isNull);
    expect(controller.isEmpty, isTrue);
  });

  test('rejects a response for a different currency or period', () async {
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => _budget(month: 7));

    await controller.load();

    expect(controller.budget.value, isNull);
    expect(controller.listErrorMessage.value, contains('scope mismatch'));
  });

  test('a stale old-period response cannot overwrite a newer period', () async {
    final oldRequest = Completer<FinanceBudgetEntity>();
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) => oldRequest.future);
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 9,
        year: 2026,
      ),
    ).thenAnswer((_) async => _budget(month: 9));

    final first = controller.load();
    await controller.selectPeriod(month: 9, year: 2026);
    oldRequest.complete(_budget(month: 8));
    await first;

    expect(controller.budget.value?.month, 9);
  });

  test(
    'refresh preserves the existing budget on a transient failure',
    () async {
      final value = _budget();
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) async => value);
      await controller.load();
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenThrow(
        const AppError(message: 'Offline', errorCode: 'NETWORK_ERROR'),
      );

      await controller.refresh();

      expect(controller.budget.value, same(value));
      expect(controller.listErrorMessage.value, 'Offline');
    },
  );

  test(
    'create sends categories and refreshes dashboard and current budget',
    () async {
      final value = _budget();
      when(
        () => repository.createBudget(
          month: 8,
          year: 2026,
          totalBudget: 900,
          categories: any(named: 'categories'),
          currency: FinanceCurrency.usd,
        ),
      ).thenAnswer((_) async => value);
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) async => value);

      final ok = await controller.createBudget(
        totalBudget: 900,
        categories: const [
          FinanceBudgetAllocation(category: 'Food', allocatedAmount: 300),
        ],
      );

      expect(ok, isTrue);
      expect(controller.budget.value, same(value));
      verify(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).called(1);
    },
  );

  test('invalid total and category allocations are blocked locally', () async {
    expect(await controller.createBudget(totalBudget: 0), isFalse);
    expect(controller.mutationErrorMessage.value, isNotNull);
    verifyNever(
      () => repository.createBudget(
        month: 8,
        year: 2026,
        totalBudget: 0,
        categories: null,
        currency: FinanceCurrency.usd,
      ),
    );
  });

  test('create double-submit protection allows only one mutation', () async {
    final create = Completer<FinanceBudgetEntity>();
    when(
      () => repository.createBudget(
        month: 8,
        year: 2026,
        totalBudget: 900,
        categories: any(named: 'categories'),
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => create.future);
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => _budget());

    final first = controller.createBudget(totalBudget: 900);
    await Future<void>.delayed(Duration.zero);
    expect(await controller.createBudget(totalBudget: 900), isFalse);
    create.complete(_budget());
    expect(await first, isTrue);
    verify(
      () => repository.createBudget(
        month: 8,
        year: 2026,
        totalBudget: 900,
        categories: null,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test(
    'update uses the existing budget currency and refreshes state',
    () async {
      final existing = _budget(currency: FinanceCurrency.khr, total: 300000);
      final updated = _budget(currency: FinanceCurrency.khr, total: 350000);
      controller.selectedCurrency.value = FinanceCurrency.khr;
      when(
        () => repository.updateBudget(
          budgetId: 'budget-1',
          month: 8,
          year: 2026,
          totalBudget: 350000,
          categories: any(named: 'categories'),
          currency: FinanceCurrency.khr,
        ),
      ).thenAnswer((_) async => updated);
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.khr,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) async => updated);

      expect(
        await controller.updateBudget(existing: existing, totalBudget: 350000),
        isTrue,
      );
      verify(
        () => repository.updateBudget(
          budgetId: 'budget-1',
          month: 8,
          year: 2026,
          totalBudget: 350000,
          categories: null,
          currency: FinanceCurrency.khr,
        ),
      ).called(1);
    },
  );

  test(
    'delete failure keeps the budget and exposes the backend error',
    () async {
      final value = _budget();
      controller.budget.value = value;
      when(() => repository.deleteBudget('budget-1')).thenThrow(
        const AppError(message: 'Cannot delete', errorCode: 'DELETE_FAILED'),
      );

      expect(await controller.deleteBudget(), isFalse);
      expect(controller.budget.value, same(value));
      expect(controller.mutationErrorMessage.value, 'Cannot delete');
    },
  );

  test('delete double-submit protection allows only one request', () async {
    final value = _budget();
    controller.budget.value = value;
    final deletion = Completer<void>();
    when(
      () => repository.deleteBudget('budget-1'),
    ).thenAnswer((_) => deletion.future);
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => _budget());

    final first = controller.deleteBudget();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.deleteBudget(), isFalse);
    deletion.complete();
    expect(await first, isTrue);
    verify(() => repository.deleteBudget('budget-1')).called(1);
  });

  test('previous month navigation rolls the year back safely', () async {
    controller
      ..selectedMonth.value = 1
      ..selectedYear.value = 2026;
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 12,
        year: 2025,
      ),
    ).thenAnswer((_) async => _budget(month: 12, year: 2025));

    await controller.selectPreviousMonth();

    expect(controller.selectedMonth.value, 12);
    expect(controller.selectedYear.value, 2025);
  });

  test('create failure does not refresh or fabricate a budget', () async {
    when(
      () => repository.createBudget(
        month: 8,
        year: 2026,
        totalBudget: 900,
        categories: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(
        message: 'Already exists',
        errorCode: 'BUDGET_ALREADY_EXISTS',
      ),
    );

    expect(await controller.createBudget(totalBudget: 900), isFalse);
    expect(controller.budget.value, isNull);
    expect(controller.mutationErrorMessage.value, 'Already exists');
    verifyNever(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    );
  });

  test('update failure preserves the current budget', () async {
    final existing = _budget();
    controller.budget.value = existing;
    when(
      () => repository.updateBudget(
        budgetId: 'budget-1',
        month: 8,
        year: 2026,
        totalBudget: 1000,
        categories: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(message: 'Update failed', errorCode: 'UPDATE_FAILED'),
    );

    expect(
      await controller.updateBudget(existing: existing, totalBudget: 1000),
      isFalse,
    );
    expect(controller.budget.value, same(existing));
    expect(controller.mutationErrorMessage.value, 'Update failed');
  });

  test('delete success refreshes the dashboard and current period', () async {
    controller.budget.value = _budget();
    when(() => repository.deleteBudget('budget-1')).thenAnswer((_) async {});
    when(
      () => repository.getCurrentBudget(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenThrow(
      const AppError(
        message: 'Not found',
        errorCode: 'NOT_FOUND',
        statusCode: 404,
      ),
    );

    expect(await controller.deleteBudget(), isTrue);
    expect(controller.budget.value, isNull);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).called(1);
  });

  test(
    'refresh during initial load clears the stale loading indicator',
    () async {
      final initial = Completer<FinanceBudgetEntity>();
      final refreshed = Completer<FinanceBudgetEntity>();
      var calls = 0;
      when(
        () => repository.getCurrentBudget(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) {
        calls++;
        return calls == 1 ? initial.future : refreshed.future;
      });

      final loading = controller.load();
      expect(controller.isLoading.value, isTrue);
      final refreshing = controller.refresh();
      expect(controller.isLoading.value, isFalse);
      expect(controller.isRefreshing.value, isTrue);

      refreshed.complete(_budget(total: 1200));
      await refreshing;
      initial.complete(_budget(total: 900));
      await loading;

      expect(controller.isLoading.value, isFalse);
      expect(controller.isRefreshing.value, isFalse);
      expect(controller.budget.value?.totalBudget, 1200);
    },
  );
}
