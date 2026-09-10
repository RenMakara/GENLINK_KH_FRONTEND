import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';

class FinanceController extends GetxController {
  FinanceController({required this._repository});

  final FinanceRepository _repository;

  final selectedCurrency = FinanceCurrency.usd.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final dashboard = Rxn<FinanceDashboardEntity>();

  int _requestSequence = 0;

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

    dashboard.value = null;
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
