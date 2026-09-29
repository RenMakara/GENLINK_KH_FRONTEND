import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceInsightsEntity _insights({
  required FinanceCurrency currency,
  required int month,
  required int year,
  double income = 120,
  double expense = 60,
  double net = 60,
  double savingsRatePercent = 50,
}) => FinanceInsightsEntity(
  currency: currency,
  month: month,
  year: year,
  income: income,
  expense: expense,
  net: net,
  savingsRatePercent: savingsRatePercent,
  insights: const [],
);

FinanceCashFlowEntity _cashFlow({
  required FinanceCurrency currency,
  required int month,
  required int year,
  double income = 100,
  double expense = 50,
  double net = 50,
  double savingsRatePercent = 50,
}) => FinanceCashFlowEntity(
  currency: currency,
  month: month,
  year: year,
  totalIncome: income,
  totalExpense: expense,
  net: net,
  savingsRatePercent: savingsRatePercent,
);

void main() {
  late _MockFinanceRepository repository;
  late FinanceController controller;

  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();
    controller = FinanceController(repository: repository);
  });

  tearDown(Get.reset);

  test('uses actual currency and month data for the trend', () async {
    when(
      () => repository.getFinanceInsights(
        currency: FinanceCurrency.usd,
        month: 9,
        year: 2026,
      ),
    ).thenAnswer(
      (_) async =>
          _insights(currency: FinanceCurrency.usd, month: 9, year: 2026),
    );
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer(
      (_) async =>
          _cashFlow(currency: FinanceCurrency.usd, month: 8, year: 2026),
    );

    await controller.loadFinanceInsights(
      currency: FinanceCurrency.usd,
      month: 9,
      year: 2026,
    );

    expect(
      controller.trendFor(FinanceTrendMetric.income)?.text,
      '+20% vs last month',
    );
    expect(
      controller.trendFor(FinanceTrendMetric.expense)?.text,
      '+20% vs last month',
    );
    expect(
      controller.trendFor(FinanceTrendMetric.net)?.text,
      '+\$10.00 net vs last month',
    );
    verify(
      () => repository.getFinanceInsights(
        currency: FinanceCurrency.usd,
        month: 9,
        year: 2026,
      ),
    ).called(1);
    verify(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: 8,
        year: 2026,
      ),
    ).called(1);
  });

  test(
    'does not fabricate percentages when the prior amount is zero',
    () async {
      when(
        () => repository.getFinanceInsights(
          currency: FinanceCurrency.usd,
          month: 1,
          year: 2026,
        ),
      ).thenAnswer(
        (_) async => _insights(
          currency: FinanceCurrency.usd,
          month: 1,
          year: 2026,
          income: 25,
        ),
      );
      when(
        () => repository.getCashFlow(
          currency: FinanceCurrency.usd,
          month: 12,
          year: 2025,
        ),
      ).thenAnswer(
        (_) async => _cashFlow(
          currency: FinanceCurrency.usd,
          month: 12,
          year: 2025,
          income: 0,
          expense: 0,
          net: 0,
          savingsRatePercent: 0,
        ),
      );

      await controller.loadFinanceInsights(
        currency: FinanceCurrency.usd,
        month: 1,
        year: 2026,
      );

      expect(
        controller.trendFor(FinanceTrendMetric.income)?.text,
        'No prior month comparison',
      );
      expect(controller.trendFor(FinanceTrendMetric.income)?.direction, 1);
    },
  );

  test('keeps the insight snapshot when the next request fails', () async {
    final snapshot = _insights(
      currency: FinanceCurrency.khr,
      month: 8,
      year: 2026,
    );
    when(
      () => repository.getFinanceInsights(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).thenAnswer((_) async => snapshot);
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.khr,
        month: 7,
        year: 2026,
      ),
    ).thenAnswer(
      (_) async =>
          _cashFlow(currency: FinanceCurrency.khr, month: 7, year: 2026),
    );
    await controller.loadFinanceInsights(
      currency: FinanceCurrency.khr,
      month: 8,
      year: 2026,
    );

    when(
      () => repository.getFinanceInsights(
        currency: FinanceCurrency.khr,
        month: 8,
        year: 2026,
      ),
    ).thenThrow(
      const AppError(
        message: 'Insights unavailable',
        errorCode: 'API_ERROR',
        statusCode: 503,
      ),
    );
    await controller.loadFinanceInsights(
      currency: FinanceCurrency.khr,
      month: 8,
      year: 2026,
    );

    expect(controller.financeInsights.value, same(snapshot));
    expect(controller.insightsErrorMessage.value, 'Insights unavailable');
  });
}
