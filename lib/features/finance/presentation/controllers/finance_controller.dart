import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_money_formatter.dart';

enum FinanceTrendMetric { income, expense, net, savingsRate }

class FinanceTrendInfo {
  const FinanceTrendInfo({required this.text, required this.direction});

  final String text;
  final int direction;
}

class FinanceController extends GetxController {
  FinanceController({required this._repository});

  final FinanceRepository _repository;

  final selectedCurrency = FinanceCurrency.usd.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final dashboard = Rxn<FinanceDashboardEntity>();
  final financeInsights = Rxn<FinanceInsightsEntity>();
  final previousPeriodCashFlow = Rxn<FinanceCashFlowEntity>();
  final isInsightsLoading = false.obs;
  final insightsErrorMessage = RxnString();
  final previousPeriodErrorMessage = RxnString();

  int _requestSequence = 0;
  int _insightsRequestSequence = 0;
  FinanceCurrency? _insightsCurrency;
  int? _insightsMonth;
  int? _insightsYear;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard({FinanceCurrency? currency}) async {
    if (currency != null) {
      selectedCurrency.value = currency;
    }

    final requestedCurrency = selectedCurrency.value;
    final requestId = ++_requestSequence;

    // Keep a same-currency snapshot visible while refreshing. A snapshot from a
    // different currency cannot safely be shown under the new selection.
    if (dashboard.value?.currency != requestedCurrency) {
      dashboard.value = null;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.getFinanceDashboard(
        currency: requestedCurrency,
      );

      if (requestId != _requestSequence) return;
      _validateCurrencyScope(result, requestedCurrency);
      dashboard.value = result;
    } on AppError catch (error) {
      if (requestId != _requestSequence) return;
      errorMessage.value = error.message;
    } catch (_) {
      if (requestId != _requestSequence) return;
      errorMessage.value = 'common.error'.tr;
    } finally {
      if (requestId == _requestSequence) {
        isLoading.value = false;
      }
    }
  }

  Future<void> selectCurrency(FinanceCurrency currency) {
    if (currency == selectedCurrency.value && dashboard.value != null) {
      return Future<void>.value();
    }
    return loadDashboard(currency: currency);
  }

  Future<void> reload() => loadDashboard();

  Future<void> ensureFinanceInsights({
    required FinanceCurrency currency,
    required int month,
    required int year,
  }) async {
    if (_insightsCurrency == currency &&
        _insightsMonth == month &&
        _insightsYear == year &&
        (financeInsights.value != null || isInsightsLoading.value)) {
      return;
    }
    await loadFinanceInsights(currency: currency, month: month, year: year);
  }

  Future<void> loadFinanceInsights({
    required FinanceCurrency currency,
    required int month,
    required int year,
  }) async {
    if (month < 1 || month > 12 || year < 1) {
      insightsErrorMessage.value = 'finance.trend.invalidPeriod'.tr;
      return;
    }
    final requestId = ++_insightsRequestSequence;
    final scopeChanged =
        _insightsCurrency != currency ||
        _insightsMonth != month ||
        _insightsYear != year;
    _insightsCurrency = currency;
    _insightsMonth = month;
    _insightsYear = year;
    if (scopeChanged) {
      financeInsights.value = null;
      previousPeriodCashFlow.value = null;
    }
    isInsightsLoading.value = true;
    insightsErrorMessage.value = null;
    previousPeriodErrorMessage.value = null;

    final previous = DateTime(year, month - 1, 1);
    try {
      final current = await _repository.getFinanceInsights(
        currency: currency,
        month: month,
        year: year,
      );
      if (requestId != _insightsRequestSequence) return;
      if (current.currency != currency ||
          current.month != month ||
          current.year != year) {
        throw const FormatException('Finance insights scope mismatch');
      }
      financeInsights.value = current;
      try {
        final prior = await _repository.getCashFlow(
          currency: currency,
          month: previous.month,
          year: previous.year,
        );
        if (requestId != _insightsRequestSequence) return;
        if (prior.currency != currency ||
            prior.month != previous.month ||
            prior.year != previous.year) {
          throw const FormatException('Prior period scope mismatch');
        }
        previousPeriodCashFlow.value = prior;
      } on AppError catch (error) {
        if (requestId == _insightsRequestSequence) {
          previousPeriodErrorMessage.value = error.message;
        }
      } catch (_) {
        if (requestId == _insightsRequestSequence) {
          previousPeriodErrorMessage.value = 'common.error'.tr;
        }
      }
    } on AppError catch (error) {
      if (requestId == _insightsRequestSequence) {
        insightsErrorMessage.value = error.message;
      }
    } on FormatException catch (error) {
      if (requestId == _insightsRequestSequence) {
        insightsErrorMessage.value = error.message;
      }
    } catch (_) {
      if (requestId == _insightsRequestSequence) {
        insightsErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (requestId == _insightsRequestSequence) {
        isInsightsLoading.value = false;
      }
    }
  }

  FinanceTrendInfo? trendFor(FinanceTrendMetric metric) {
    final current = financeInsights.value;
    final previous = previousPeriodCashFlow.value;
    if (current == null || previous == null) return null;

    final currentAmount = switch (metric) {
      FinanceTrendMetric.income => current.income,
      FinanceTrendMetric.expense => current.expense,
      FinanceTrendMetric.net => current.net,
      FinanceTrendMetric.savingsRate => current.savingsRatePercent,
    };
    final previousAmount = switch (metric) {
      FinanceTrendMetric.income => previous.totalIncome,
      FinanceTrendMetric.expense => previous.totalExpense,
      FinanceTrendMetric.net => previous.net,
      FinanceTrendMetric.savingsRate => previous.savingsRatePercent,
    };
    final currentMoney = FinanceMoney.tryFromNumber(currentAmount);
    final previousMoney = FinanceMoney.tryFromNumber(previousAmount);
    if (currentMoney == null || previousMoney == null) return null;

    if (metric == FinanceTrendMetric.net) {
      final delta = currentMoney - previousMoney;
      final direction = delta.sign;
      if (direction == 0) {
        return FinanceTrendInfo(
          text: 'finance.trend.noChange'.tr,
          direction: 0,
        );
      }
      return FinanceTrendInfo(
        text: 'finance.trend.netChange'.trParams({
          'direction': direction > 0 ? '+' : '−',
          'amount': FinanceMoneyFormatter.formatExact(
            delta.abs(),
            current.currency,
          ),
        }),
        direction: direction,
      );
    }

    if (metric == FinanceTrendMetric.savingsRate) {
      final delta = currentMoney - previousMoney;
      final direction = delta.sign;
      if (direction == 0) {
        return FinanceTrendInfo(
          text: 'finance.trend.noChange'.tr,
          direction: 0,
        );
      }
      final points = delta.abs().toDecimalString().replaceFirst(
        RegExp(r'\.0+$'),
        '',
      );
      return FinanceTrendInfo(
        text: 'finance.trend.pointsChange'.trParams({
          'direction': direction > 0 ? '+' : '−',
          'points': points,
        }),
        direction: direction,
      );
    }

    final change = FinanceMoney.percentChange(currentMoney, previousMoney);
    if (change == null) {
      return FinanceTrendInfo(
        text: 'finance.trend.noBaseline'.tr,
        direction: currentMoney.sign,
      );
    }
    final direction = change.sign;
    if (direction == 0) {
      return FinanceTrendInfo(text: 'finance.trend.noChange'.tr, direction: 0);
    }
    return FinanceTrendInfo(
      text: 'finance.trend.percentChange'.trParams({
        'direction': direction > 0 ? '+' : '−',
        'percent': change.abs().toString(),
      }),
      direction: direction,
    );
  }

  void _validateCurrencyScope(
    FinanceDashboardEntity result,
    FinanceCurrency requestedCurrency,
  ) {
    if (result.currency != requestedCurrency ||
        result.month.currency != requestedCurrency ||
        result.saving.currency != requestedCurrency ||
        result.topCategories.any(
          (category) => category.currency != requestedCurrency,
        ) ||
        result.recentExpenses.any(
          (expense) => expense.currency != requestedCurrency,
        )) {
      throw const FormatException('Finance dashboard currency mismatch');
    }
  }
}
