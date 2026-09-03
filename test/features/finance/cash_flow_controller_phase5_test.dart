import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/cash_flow_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceCashFlowEntity _cashFlow({
  FinanceCurrency currency = FinanceCurrency.usd,
  int month = 8,
  int year = 2026,
  double totalIncome = 300,
  double totalExpense = 120,
  double net = 180,
  double savingsRatePercent = 60,
}) {
  return FinanceCashFlowEntity(
    currency: currency,
    month: month,
    year: year,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    net: net,
    savingsRatePercent: savingsRatePercent,
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
  late CashFlowController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller = CashFlowController(
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

  test('loads the documented USD month/year cash flow request', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => _cashFlow());

    await controller.load();

    expect(controller.cashFlow.value?.totalIncome, 300);
    expect(controller.cashFlow.value?.totalExpense, 120);
    expect(controller.cashFlow.value?.net, 180);
    verify(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).called(1);
  });

  test('loads KHR without mixing the USD aggregate', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer(
      (_) async => _cashFlow(
        currency: FinanceCurrency.khr,
        totalIncome: 100000,
        totalExpense: 50000,
        net: 50000,
      ),
    );

    await controller.selectCurrency(FinanceCurrency.khr);

    expect(controller.cashFlow.value?.currency, FinanceCurrency.khr);
    expect(controller.cashFlow.value?.net, 50000);
    verify(
      () => repository.getCashFlow(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).called(1);
  });

  test('period changes use exact documented month/year parameters', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 7,
        year: 2026,
      ),
    ).thenAnswer((_) async => _cashFlow(month: 7));

    await controller.selectPeriod(month: 7, year: 2026);

    expect(controller.selectedMonth.value, 7);
    expect(controller.selectedYear.value, 2026);
    verify(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 7,
        year: 2026,
      ),
    ).called(1);
  });

  test('previous and next month navigation stays calendar-safe', () async {
    controller
      ..selectedMonth.value = 1
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 12,
        year: 2025,
      ),
    ).thenAnswer((_) async => _cashFlow(month: 12, year: 2025));
    await controller.selectPreviousMonth();
    expect(controller.selectedMonth.value, 12);
    expect(controller.selectedYear.value, 2025);

    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 1,
        year: 2026,
      ),
    ).thenAnswer((_) async => _cashFlow(month: 1, year: 2026));
    await controller.selectNextMonth();
    expect(controller.selectedMonth.value, 1);
    expect(controller.selectedYear.value, 2026);
  });

  test('exposes cash flow failures without stale data', () async {
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    ).thenThrow(
      const AppError(message: 'Cash flow unavailable', errorCode: 'API_ERROR'),
    );

    await controller.load();

    expect(controller.cashFlow.value, isNull);
    expect(controller.errorMessage.value, 'Cash flow unavailable');
  });

  test('refresh preserves the last aggregate on transient failure', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    ).thenAnswer((_) async => _cashFlow());
    await controller.load();
    reset(repository);
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    ).thenThrow(
      const AppError(message: 'Refresh failed', errorCode: 'API_ERROR'),
    );

    await controller.refresh();

    expect(controller.cashFlow.value?.net, 180);
    expect(controller.errorMessage.value, 'Refresh failed');
  });

  test('rejects an out-of-scope backend response', () async {
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    ).thenAnswer((_) async => _cashFlow(month: 7));

    await controller.load();

    expect(controller.cashFlow.value, isNull);
    expect(controller.errorMessage.value, 'Cash flow scope mismatch');
  });

  test('stale response cannot overwrite a newer period', () async {
    final august = Completer<FinanceCashFlowEntity>();
    final july = Completer<FinanceCashFlowEntity>();
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) => august.future);
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 7,
        year: 2026,
      ),
    ).thenAnswer((_) => july.future);

    final first = controller.load();
    final second = controller.selectPeriod(month: 7, year: 2026);
    august.complete(_cashFlow(month: 8));
    await first;
    july.complete(_cashFlow(month: 7, totalIncome: 200));
    await second;

    expect(controller.selectedMonth.value, 7);
    expect(controller.cashFlow.value?.month, 7);
    expect(controller.cashFlow.value?.totalIncome, 200);
  });

  test('zero totals are exposed as an empty period', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    ).thenAnswer(
      (_) async => _cashFlow(totalIncome: 0, totalExpense: 0, net: 0),
    );

    await controller.load();

    expect(controller.isEmpty, isTrue);
  });

  test(
    'negative backend net is preserved without currency conversion',
    () async {
      controller
        ..selectedMonth.value = 8
        ..selectedYear.value = 2026;
      when(
        () => repository.getCashFlow(
          currency: FinanceCurrency.khr,
          month: controller.selectedMonth.value,
          year: controller.selectedYear.value,
        ),
      ).thenAnswer(
        (_) async => _cashFlow(
          currency: FinanceCurrency.khr,
          totalIncome: 100000,
          totalExpense: 150000,
          net: -50000,
          savingsRatePercent: -50,
        ),
      );

      await controller.selectCurrency(FinanceCurrency.khr);

      expect(controller.cashFlow.value?.net, -50000);
      expect(controller.cashFlow.value?.savingsRatePercent, -50);
    },
  );

  test('invalid period is rejected before the repository call', () async {
    await controller.selectPeriod(month: 13, year: 2026);

    expect(controller.errorMessage.value, 'Invalid cash flow period.');
    verifyNever(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 13,
        year: 2026,
      ),
    );
  });

  test(
    'selecting the active period does not issue a duplicate request',
    () async {
      controller
        ..selectedMonth.value = 8
        ..selectedYear.value = 2026;

      await controller.selectPeriod(month: 8, year: 2026);

      verifyNever(
        () => repository.getCashFlow(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      );
    },
  );

  test(
    'successful refresh replaces the current aggregate for the same scope',
    () async {
      controller
        ..selectedMonth.value = 8
        ..selectedYear.value = 2026;
      var calls = 0;
      when(
        () => repository.getCashFlow(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).thenAnswer((_) async {
        calls++;
        return _cashFlow(net: calls == 1 ? 180 : 250);
      });

      await controller.load();
      await controller.refresh();

      expect(controller.cashFlow.value?.net, 250);
      verify(
        () => repository.getCashFlow(
          currency: FinanceCurrency.usd,
          month: 8,
          year: 2026,
        ),
      ).called(2);
    },
  );

  test('refresh and scoped load do not leave either indicator stuck', () async {
    controller
      ..selectedMonth.value = 8
      ..selectedYear.value = 2026;
    final initial = Completer<FinanceCashFlowEntity>();
    final refreshed = Completer<FinanceCashFlowEntity>();
    var calls = 0;
    when(
      () => repository.getCashFlow(
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

    refreshed.complete(_cashFlow(net: 250));
    await refreshing;
    initial.complete(_cashFlow(net: 180));
    await loading;

    expect(controller.isLoading.value, isFalse);
    expect(controller.isRefreshing.value, isFalse);
    expect(controller.cashFlow.value?.net, 250);
  });
}
