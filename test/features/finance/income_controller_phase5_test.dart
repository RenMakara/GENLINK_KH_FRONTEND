import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceIncomeEntity _income({
  String id = 'income-1',
  FinanceCurrency currency = FinanceCurrency.usd,
  String? source = 'ALLOWANCE',
  double amount = 300,
}) {
  return FinanceIncomeEntity(
    incomeId: id,
    title: 'Allowance',
    amount: amount,
    currency: currency,
    source: source,
    description: 'Monthly support',
    incomeDate: '2026-08-01',
    createdAt: '2026-08-01T10:00:00Z',
  );
}

FinancePage<FinanceIncomeEntity> _page(
  List<FinanceIncomeEntity> content, {
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
  late IncomeController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller = IncomeController(
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

  test('loads page zero with selected USD currency', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_income()]));

    await controller.loadInitial();

    expect(controller.incomes.single.incomeId, 'income-1');
    expect(controller.currentPage.value, 0);
    expect(controller.totalElements.value, 1);
    verify(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).called(1);
  });

  test('exposes list failure without fabricating rows', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenThrow(
      const AppError(message: 'Income unavailable', errorCode: 'API_ERROR'),
    );

    await controller.loadInitial();

    expect(controller.incomes, isEmpty);
    expect(controller.listErrorMessage.value, 'Income unavailable');
  });

  test('currency selection resets pagination and sends KHR', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.khr,
        page: 0,
        size: 20,
      ),
    ).thenAnswer(
      (_) async => _page([_income(id: 'khr-1', currency: FinanceCurrency.khr)]),
    );

    await controller.selectCurrency(FinanceCurrency.khr);

    expect(controller.selectedCurrency.value, FinanceCurrency.khr);
    expect(controller.incomes.single.currency, FinanceCurrency.khr);
    verify(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.khr,
        page: 0,
        size: 20,
      ),
    ).called(1);
  });

  test(
    'source filter preserves backend value and resets to page zero',
    () async {
      when(
        () => repository.getIncomes(
          source: 'salary',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) async => _page([_income(source: 'SALARY')]));

      await controller.selectSource(' salary ');

      expect(controller.selectedSource.value, 'salary');
      verify(
        () => repository.getIncomes(
          source: 'salary',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).called(1);
    },
  );

  test('clearing source filter sends null', () async {
    controller.selectedSource.value = 'SALARY';
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    await controller.selectSource('');

    expect(controller.selectedSource.value, isNull);
    verify(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).called(1);
  });

  test('next page appends and deduplicates by income id', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_income(id: 'one')], hasNext: true));
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenAnswer(
      (_) async => _page(
        [_income(id: 'one'), _income(id: 'two')],
        page: 1,
        totalElements: 3,
      ),
    );

    await controller.loadInitial();
    await controller.loadNextPage();

    expect(controller.incomes.map((item) => item.incomeId), ['one', 'two']);
    expect(controller.currentPage.value, 1);
  });

  test('pagination failure preserves loaded income rows', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_income()], hasNext: true));
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenThrow(
      const AppError(message: 'Next page failed', errorCode: 'API_ERROR'),
    );

    await controller.loadInitial();
    await controller.loadNextPage();

    expect(controller.incomes, hasLength(1));
    expect(controller.currentPage.value, 0);
    expect(controller.paginationErrorMessage.value, 'Next page failed');
  });

  test(
    'refresh replaces page zero and preserves active source filter',
    () async {
      var calls = 0;
      when(
        () => repository.getIncomes(
          source: 'allowance',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) async {
        calls++;
        return _page([_income(id: 'fresh-$calls')]);
      });

      await controller.selectSource('allowance');
      await controller.refresh();

      expect(controller.incomes.single.incomeId, 'fresh-2');
      verify(
        () => repository.getIncomes(
          source: 'allowance',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).called(2);
    },
  );

  test('refresh failure keeps the last successful rows visible', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_income()]));
    await controller.loadInitial();
    reset(repository);
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenThrow(
      const AppError(message: 'Refresh failed', errorCode: 'API_ERROR'),
    );

    await controller.refresh();

    expect(controller.incomes.single.incomeId, 'income-1');
    expect(controller.listErrorMessage.value, 'Refresh failed');
  });

  test('stale currency response cannot overwrite current KHR state', () async {
    final usd = Completer<FinancePage<FinanceIncomeEntity>>();
    final khr = Completer<FinancePage<FinanceIncomeEntity>>();
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) => usd.future);
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.khr,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) => khr.future);

    final first = controller.loadInitial();
    final second = controller.selectCurrency(FinanceCurrency.khr);
    usd.complete(_page([_income(id: 'usd')]));
    await first;
    khr.complete(_page([_income(id: 'khr', currency: FinanceCurrency.khr)]));
    await second;

    expect(controller.incomes.single.incomeId, 'khr');
    expect(controller.selectedCurrency.value, FinanceCurrency.khr);
  });

  test(
    'create uses selected currency and refreshes dashboard and cash flow',
    () async {
      var cashFlowRefreshCalls = 0;
      controller = IncomeController(
        repository: repository,
        financeController: financeController,
        refreshCashFlow: () async {
          cashFlowRefreshCalls++;
        },
      );
      when(
        () => repository.createIncome(
          title: 'Allowance',
          amount: 300,
          incomeDate: '2026-08-01',
          source: 'allowance',
          description: 'Monthly support',
          currency: FinanceCurrency.usd,
        ),
      ).thenAnswer((_) async => _income());
      when(
        () => repository.getIncomes(
          source: null,
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) async => _page([_income()]));

      expect(
        await controller.createIncome(
          title: 'Allowance',
          amount: 300,
          incomeDate: '2026-08-01',
          source: 'allowance',
          description: 'Monthly support',
        ),
        isTrue,
      );
      verify(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).called(1);
      expect(cashFlowRefreshCalls, 1);
    },
  );

  test('create failure preserves operation state and error', () async {
    when(
      () => repository.createIncome(
        title: 'Allowance',
        amount: 300,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(message: 'Create failed', errorCode: 'API_ERROR'),
    );

    expect(
      await controller.createIncome(
        title: 'Allowance',
        amount: 300,
        incomeDate: '2026-08-01',
      ),
      isFalse,
    );
    expect(controller.mutationErrorMessage.value, 'Create failed');
    expect(controller.isCreateSubmitting.value, isFalse);
  });

  test('invalid amount is rejected before create API', () async {
    expect(
      await controller.createIncome(
        title: 'Invalid',
        amount: 0,
        incomeDate: '2026-08-01',
      ),
      isFalse,
    );
    verifyNever(
      () => repository.createIncome(
        title: 'Invalid',
        amount: 0,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.usd,
      ),
    );
  });

  test('create double-submit protection allows one request', () async {
    final gate = Completer<FinanceIncomeEntity>();
    when(
      () => repository.createIncome(
        title: 'Allowance',
        amount: 300,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => gate.future);
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    final first = controller.createIncome(
      title: 'Allowance',
      amount: 300,
      incomeDate: '2026-08-01',
    );
    final second = controller.createIncome(
      title: 'Allowance',
      amount: 300,
      incomeDate: '2026-08-01',
    );
    expect(await second, isFalse);
    gate.complete(_income());
    expect(await first, isTrue);
    verify(
      () => repository.createIncome(
        title: 'Allowance',
        amount: 300,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('update sends full PUT fields and refreshes state', () async {
    final existing = _income(amount: 300);
    when(
      () => repository.updateIncome(
        incomeId: 'income-1',
        title: 'Updated allowance',
        amount: 350,
        incomeDate: '2026-08-02',
        source: 'SALARY',
        description: 'Updated',
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async => existing);
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([existing]));

    expect(
      await controller.updateIncome(
        existing: existing,
        title: 'Updated allowance',
        amount: 350,
        incomeDate: '2026-08-02',
        source: 'SALARY',
        description: 'Updated',
      ),
      isTrue,
    );
    verify(
      () => repository.updateIncome(
        incomeId: 'income-1',
        title: 'Updated allowance',
        amount: 350,
        incomeDate: '2026-08-02',
        source: 'SALARY',
        description: 'Updated',
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('update failure does not report success', () async {
    final existing = _income();
    when(
      () => repository.updateIncome(
        incomeId: 'income-1',
        title: 'Allowance',
        amount: 310,
        incomeDate: '2026-08-01',
        source: 'allowance',
        description: 'Monthly support',
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(message: 'Update failed', errorCode: 'API_ERROR'),
    );

    expect(
      await controller.updateIncome(
        existing: existing,
        title: 'Allowance',
        amount: 310,
        incomeDate: '2026-08-01',
        source: 'allowance',
        description: 'Monthly support',
      ),
      isFalse,
    );
    expect(controller.mutationErrorMessage.value, 'Update failed');
  });

  test('update double-submit protection allows one request', () async {
    final existing = _income();
    final gate = Completer<FinanceIncomeEntity>();
    when(
      () => repository.updateIncome(
        incomeId: 'income-1',
        title: 'Allowance',
        amount: 310,
        incomeDate: '2026-08-01',
        source: 'ALLOWANCE',
        description: 'Monthly support',
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => gate.future);
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([existing]));

    final first = controller.updateIncome(
      existing: existing,
      title: 'Allowance',
      amount: 310,
      incomeDate: '2026-08-01',
      source: 'ALLOWANCE',
      description: 'Monthly support',
    );
    final second = controller.updateIncome(
      existing: existing,
      title: 'Allowance',
      amount: 310,
      incomeDate: '2026-08-01',
      source: 'ALLOWANCE',
      description: 'Monthly support',
    );
    expect(await second, isFalse);
    gate.complete(existing);
    expect(await first, isTrue);
    verify(
      () => repository.updateIncome(
        incomeId: 'income-1',
        title: 'Allowance',
        amount: 310,
        incomeDate: '2026-08-01',
        source: 'ALLOWANCE',
        description: 'Monthly support',
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('successful delete refreshes the list', () async {
    when(() => repository.deleteIncome('income-1')).thenAnswer((_) async {});
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    expect(await controller.deleteIncome('income-1'), isTrue);
    expect(controller.incomes, isEmpty);
    verify(() => repository.deleteIncome('income-1')).called(1);
  });

  test('failed delete preserves the current income state', () async {
    controller.incomes.add(_income());
    when(() => repository.deleteIncome('income-1')).thenThrow(
      const AppError(message: 'Delete failed', errorCode: 'API_ERROR'),
    );

    expect(await controller.deleteIncome('income-1'), isFalse);
    expect(controller.incomes.single.incomeId, 'income-1');
    expect(controller.mutationErrorMessage.value, 'Delete failed');
  });

  test('delete double-submit protection allows one request', () async {
    final gate = Completer<void>();
    when(
      () => repository.deleteIncome('income-1'),
    ).thenAnswer((_) => gate.future);

    final first = controller.deleteIncome('income-1');
    final second = controller.deleteIncome('income-1');
    expect(await second, isFalse);
    gate.complete();
    expect(await first, isTrue);
    verify(() => repository.deleteIncome('income-1')).called(1);
  });

  test('income detail factory preserves backend fields and currency', () {
    final screen = IncomeDetailScreen.fromEntity(
      _income(currency: FinanceCurrency.khr),
    );

    expect(screen.title, 'Allowance');
    expect(screen.amount, '+៛300');
    expect(screen.source, 'ALLOWANCE');
    expect(screen.currency, FinanceCurrency.khr);
    expect(screen.date, '2026-08-01');
  });

  test('empty first page stays empty without an error', () async {
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    await controller.loadInitial();

    expect(controller.incomes, isEmpty);
    expect(controller.listErrorMessage.value, isNull);
    expect(controller.currentPage.value, 0);
  });

  test('negative amount is rejected before mutation', () async {
    expect(
      await controller.createIncome(
        title: 'Invalid',
        amount: -1,
        incomeDate: '2026-08-01',
      ),
      isFalse,
    );
    verifyNever(
      () => repository.createIncome(
        title: 'Invalid',
        amount: -1,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.usd,
      ),
    );
  });

  test('KHR create sends the matching currency to the backend', () async {
    financeController.selectedCurrency.value = FinanceCurrency.khr;
    when(
      () => repository.createIncome(
        title: 'Support',
        amount: 100000,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.khr,
      ),
    ).thenAnswer((_) async => _income(currency: FinanceCurrency.khr));
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.khr,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([]));

    expect(
      await controller.createIncome(
        title: 'Support',
        amount: 100000,
        incomeDate: '2026-08-01',
      ),
      isTrue,
    );
    verify(
      () => repository.createIncome(
        title: 'Support',
        amount: 100000,
        incomeDate: '2026-08-01',
        source: null,
        description: null,
        currency: FinanceCurrency.khr,
      ),
    ).called(1);
  });

  test(
    'stale source response cannot overwrite a newer source filter',
    () async {
      final allowance = Completer<FinancePage<FinanceIncomeEntity>>();
      final salary = Completer<FinancePage<FinanceIncomeEntity>>();
      when(
        () => repository.getIncomes(
          source: 'allowance',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) => allowance.future);
      when(
        () => repository.getIncomes(
          source: 'salary',
          currency: FinanceCurrency.usd,
          page: 0,
          size: 20,
        ),
      ).thenAnswer((_) => salary.future);

      final first = controller.selectSource('allowance');
      final second = controller.selectSource('salary');
      allowance.complete(_page([_income(id: 'allowance')]));
      await first;
      salary.complete(_page([_income(id: 'salary', source: 'salary')]));
      await second;

      expect(controller.selectedSource.value, 'salary');
      expect(controller.incomes.single.incomeId, 'salary');
    },
  );

  test('pagination guard does not request the same page twice', () async {
    final gate = Completer<FinancePage<FinanceIncomeEntity>>();
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) async => _page([_income()], hasNext: true));
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).thenAnswer((_) => gate.future);

    await controller.loadInitial();
    final first = controller.loadNextPage();
    final second = controller.loadNextPage();
    await second;
    expect(controller.isLoadingMore.value, isTrue);
    gate.complete(_page([_income(id: 'next')], page: 1));
    await first;

    verify(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 1,
        size: 20,
      ),
    ).called(1);
  });

  test('unknown source remains safe in detail mapping', () {
    final screen = IncomeDetailScreen.fromEntity(_income(source: 'BONUS'));
    expect(screen.source, 'BONUS');
  });

  test('refresh during page loading does not leave pagination stuck', () async {
    final nextPage = Completer<FinancePage<FinanceIncomeEntity>>();
    final refreshedPage = Completer<FinancePage<FinanceIncomeEntity>>();
    var pageZeroCalls = 0;
    when(
      () => repository.getIncomes(
        source: null,
        currency: FinanceCurrency.usd,
        page: 0,
        size: 20,
      ),
    ).thenAnswer((_) {
      pageZeroCalls++;
      return pageZeroCalls == 1
          ? Future.value(_page([_income()], hasNext: true))
          : refreshedPage.future;
    });
    when(
      () => repository.getIncomes(
        source: null,
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

    nextPage.complete(_page([_income(id: 'next')], page: 1));
    await loadingNextPage;
    refreshedPage.complete(_page([_income(id: 'refreshed')]));
    await refreshing;

    expect(controller.isLoadingMore.value, isFalse);
    expect(controller.incomes.single.incomeId, 'refreshed');
  });

  test(
    'refresh during initial load clears the stale initial indicator',
    () async {
      final initialPage = Completer<FinancePage<FinanceIncomeEntity>>();
      final refreshedPage = Completer<FinancePage<FinanceIncomeEntity>>();
      var pageZeroCalls = 0;
      when(
        () => repository.getIncomes(
          source: null,
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

      refreshedPage.complete(_page([_income(id: 'refreshed')]));
      await refreshing;
      initialPage.complete(_page([_income(id: 'stale')]));
      await loading;

      expect(controller.isInitialLoading.value, isFalse);
      expect(controller.isRefreshing.value, isFalse);
      expect(controller.incomes.single.incomeId, 'refreshed');
    },
  );
}
