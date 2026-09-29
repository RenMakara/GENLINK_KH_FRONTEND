import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    controller = FinanceController(repository: repository);
  });

  tearDown(Get.reset);

  test('loads dashboard with the selected currency', () async {
    const dashboard = FinanceDashboardEntity(
      currency: FinanceCurrency.khr,
      month: FinanceMonthOverview(
        month: 8,
        year: 2026,
        currency: FinanceCurrency.khr,
        spent: 100,
      ),
      topCategories: [],
      saving: FinanceSavingProgress(
        currency: FinanceCurrency.khr,
        totalTarget: 0,
        totalSaved: 0,
        progressPercent: 0,
        activeGoals: 0,
      ),
      recentExpenses: [],
    );
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => dashboard);

    await controller.loadDashboard(currency: FinanceCurrency.khr);

    expect(controller.selectedCurrency.value, FinanceCurrency.khr);
    expect(controller.dashboard.value, same(dashboard));
    expect(controller.errorMessage.value, isNull);
    expect(controller.isLoading.value, isFalse);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).called(1);
  });

  test('preserves useful backend error messages', () async {
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenThrow(
      const AppError(
        message: 'Not enough balance',
        errorCode: 'DEMO_WALLET_INSUFFICIENT_BALANCE',
        statusCode: 422,
      ),
    );

    await controller.loadDashboard();

    expect(controller.errorMessage.value, 'Not enough balance');
    expect(controller.isLoading.value, isFalse);
  });

  test(
    'keeps the last dashboard visible when a same-currency refresh fails',
    () async {
      const dashboard = FinanceDashboardEntity(
        currency: FinanceCurrency.usd,
        month: FinanceMonthOverview(
          month: 8,
          year: 2026,
          currency: FinanceCurrency.usd,
          spent: 25,
        ),
        topCategories: [],
        saving: FinanceSavingProgress(
          currency: FinanceCurrency.usd,
          totalTarget: 0,
          totalSaved: 0,
          progressPercent: 0,
          activeGoals: 0,
        ),
        recentExpenses: [],
      );
      var calls = 0;
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) return dashboard;
        throw const AppError(
          message: 'Dashboard unavailable',
          errorCode: 'API_ERROR',
          statusCode: 503,
        );
      });

      await controller.loadDashboard();
      await controller.reload();

      expect(controller.dashboard.value, same(dashboard));
      expect(controller.errorMessage.value, 'Dashboard unavailable');
      expect(controller.isLoading.value, isFalse);
    },
  );
}
