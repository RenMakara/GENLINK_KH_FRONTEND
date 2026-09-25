import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_localization.dart';
import 'finance_controller.dart';

class CashFlowController extends GetxController {
  CashFlowController({
    required this._repository,
    required this._financeController,
  });

  final FinanceRepository _repository;
  final FinanceController _financeController;

  Rx<FinanceCurrency> get selectedCurrency =>
      _financeController.selectedCurrency;

  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final cashFlow = Rxn<FinanceCashFlowEntity>();
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();

  int _requestSequence = 0;
  Worker? _currencyWorker;
  bool _suppressCurrencyWorker = false;

  @override
  void onInit() {
    super.onInit();
    _currencyWorker = ever<FinanceCurrency>(
      _financeController.selectedCurrency,
      (_) {
        if (!_suppressCurrencyWorker) load();
      },
    );
    load();
  }

  @override
  void onClose() {
    _currencyWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final request = ++_requestSequence;
    isLoading.value = true;
    isRefreshing.value = false;
    errorMessage.value = null;
    cashFlow.value = null;
    await _load(request);
    if (request == _requestSequence) isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    final request = ++_requestSequence;
    isRefreshing.value = true;
    isLoading.value = false;
    errorMessage.value = null;
    try {
      await _load(request, clearBeforeLoad: false);
    } finally {
      if (request == _requestSequence) isRefreshing.value = false;
    }
  }

  Future<void> selectCurrency(FinanceCurrency currency) async {
    if (currency == selectedCurrency.value) return;
    _suppressCurrencyWorker = true;
    try {
      selectedCurrency.value = currency;
      await Future.wait<void>([
        _financeController.loadDashboard(currency: currency),
        load(),
      ]);
    } finally {
      _suppressCurrencyWorker = false;
    }
  }

  Future<void> selectPeriod({required int month, required int year}) async {
    if (month < 1 || month > 12 || year < 1) {
      errorMessage.value = financeText(
        'finance.cashFlow.invalidPeriod',
        'Invalid cash flow period.',
      );
      return;
    }
    if (month == selectedMonth.value && year == selectedYear.value) return;
    selectedMonth.value = month;
    selectedYear.value = year;
    await load();
  }

  Future<void> selectPreviousMonth() async {
    final previous = DateTime(selectedYear.value, selectedMonth.value - 1);
    await selectPeriod(month: previous.month, year: previous.year);
  }

  Future<void> selectNextMonth() async {
    final next = DateTime(selectedYear.value, selectedMonth.value + 1);
    await selectPeriod(month: next.month, year: next.year);
  }

  bool get isEmpty {
    final value = cashFlow.value;
    return value != null &&
        value.totalIncome == 0 &&
        value.totalExpense == 0 &&
        value.net == 0;
  }

  Future<void> _load(int request, {bool clearBeforeLoad = true}) async {
    if (clearBeforeLoad) cashFlow.value = null;
    try {
      final result = await _repository.getCashFlow(
        currency: selectedCurrency.value,
        month: selectedMonth.value,
        year: selectedYear.value,
      );
      if (request != _requestSequence) return;
      if (result.currency != selectedCurrency.value ||
          result.month != selectedMonth.value ||
          result.year != selectedYear.value) {
        throw const FormatException('Cash flow scope mismatch');
      }
      cashFlow.value = result;
    } on AppError catch (error) {
      if (request == _requestSequence) errorMessage.value = error.message;
    } on FormatException catch (error) {
      if (request == _requestSequence) errorMessage.value = error.message;
    } catch (_) {
      if (request == _requestSequence) errorMessage.value = 'common.error'.tr;
    }
  }
}
