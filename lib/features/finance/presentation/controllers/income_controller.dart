import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_localization.dart';
import 'cash_flow_controller.dart';
import 'finance_controller.dart';

class IncomeController extends GetxController {
  IncomeController({
    required this._repository,
    required this._financeController,
    this.refreshCashFlow,
  });

  final FinanceRepository _repository;
  final FinanceController _financeController;
  final Future<void> Function()? refreshCashFlow;

  Rx<FinanceCurrency> get selectedCurrency =>
      _financeController.selectedCurrency;

  final selectedSource = RxnString();
  final incomes = <FinanceIncomeEntity>[].obs;

  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = (-1).obs;
  final totalElements = 0.obs;
  final totalPages = 0.obs;

  final listErrorMessage = RxnString();
  final paginationErrorMessage = RxnString();
  final mutationErrorMessage = RxnString();
  final isCreateSubmitting = false.obs;
  final isUpdateSubmitting = false.obs;
  final isDeleteSubmitting = false.obs;

  static const int pageSize = 20;
  int _requestSequence = 0;
  Worker? _currencyWorker;
  bool _suppressCurrencyWorker = false;

  @override
  void onInit() {
    super.onInit();
    _currencyWorker = ever<FinanceCurrency>(
      _financeController.selectedCurrency,
      (_) {
        if (!_suppressCurrencyWorker) loadInitial();
      },
    );
    loadInitial();
  }

  @override
  void onClose() {
    _currencyWorker?.dispose();
    super.onClose();
  }

  Future<void> loadInitial() async {
    final request = ++_requestSequence;
    isInitialLoading.value = true;
    isRefreshing.value = false;
    isLoadingMore.value = false;
    listErrorMessage.value = null;
    paginationErrorMessage.value = null;
    incomes.clear();
    _resetPagination();

    await _loadPage(request, page: 0, replace: true);
    if (request == _requestSequence) isInitialLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    final request = ++_requestSequence;
    isRefreshing.value = true;
    isInitialLoading.value = false;
    isLoadingMore.value = false;
    listErrorMessage.value = null;
    paginationErrorMessage.value = null;
    try {
      await _loadPage(request, page: 0, replace: true);
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
        loadInitial(),
      ]);
    } finally {
      _suppressCurrencyWorker = false;
    }
  }

  Future<void> selectSource(String? source) async {
    final trimmed = source?.trim();
    final filter = trimmed == null || trimmed.isEmpty ? null : trimmed;
    if (filter == selectedSource.value) return;
    selectedSource.value = filter;
    await loadInitial();
  }

  Future<void> loadNextPage() async {
    if (isInitialLoading.value ||
        isRefreshing.value ||
        isLoadingMore.value ||
        !hasNextPage.value ||
        currentPage.value < 0) {
      return;
    }

    final request = ++_requestSequence;
    final nextPage = currentPage.value + 1;
    isLoadingMore.value = true;
    paginationErrorMessage.value = null;
    try {
      await _loadPage(request, page: nextPage, replace: false);
    } finally {
      if (request == _requestSequence) isLoadingMore.value = false;
    }
  }

  Future<bool> createIncome({
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
  }) async {
    if (isCreateSubmitting.value) return false;
    if (!_validAmount(amount)) {
      mutationErrorMessage.value = financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
      return false;
    }
    isCreateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.createIncome(
        title: title,
        amount: amount,
        incomeDate: incomeDate,
        source: _optional(source),
        description: _optional(description),
        currency: selectedCurrency.value,
      );
      await _refreshAfterMutation();
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isCreateSubmitting.value = false;
    }
  }

  Future<bool> updateIncome({
    required FinanceIncomeEntity existing,
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
  }) async {
    if (isUpdateSubmitting.value) return false;
    if (!_validAmount(amount)) {
      mutationErrorMessage.value = financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
      return false;
    }
    isUpdateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.updateIncome(
        incomeId: existing.incomeId,
        title: title,
        amount: amount,
        incomeDate: incomeDate,
        source: _optional(source),
        description: _optional(description),
        currency: existing.currency,
      );
      await _refreshAfterMutation();
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isUpdateSubmitting.value = false;
    }
  }

  Future<bool> deleteIncome(String incomeId) async {
    if (isDeleteSubmitting.value) return false;
    isDeleteSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.deleteIncome(incomeId);
      await _refreshAfterMutation();
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isDeleteSubmitting.value = false;
    }
  }

  void clearMutationError() => mutationErrorMessage.value = null;

  Future<void> _refreshAfterMutation() async {
    final refreshes = <Future<void>>[
      loadInitial(),
      _financeController.reload(),
    ];
    final cashFlowRefresh = refreshCashFlow;
    if (cashFlowRefresh != null) {
      refreshes.add(cashFlowRefresh());
    } else if (Get.isRegistered<CashFlowController>()) {
      refreshes.add(Get.find<CashFlowController>().refresh());
    }
    await Future.wait<void>(refreshes);
  }

  Future<void> _loadPage(
    int request, {
    required int page,
    required bool replace,
  }) async {
    try {
      final result = await _repository.getIncomes(
        source: selectedSource.value,
        currency: selectedCurrency.value,
        page: page,
        size: pageSize,
      );
      if (request != _requestSequence) return;

      if (replace) {
        incomes
          ..clear()
          ..addAll(result.content);
      } else {
        _appendDeduplicated(result.content);
      }
      currentPage.value = result.page;
      totalElements.value = result.totalElements;
      totalPages.value = result.totalPages;
      hasNextPage.value = result.hasNext;
    } on AppError catch (error) {
      if (request != _requestSequence) return;
      if (replace) {
        listErrorMessage.value = error.message;
      } else {
        paginationErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request != _requestSequence) return;
      if (replace) {
        listErrorMessage.value = 'common.error'.tr;
      } else {
        paginationErrorMessage.value = 'common.error'.tr;
      }
    }
  }

  void _appendDeduplicated(List<FinanceIncomeEntity> items) {
    final existing = incomes.map((item) => item.incomeId).toSet();
    for (final item in items) {
      if (existing.add(item.incomeId)) incomes.add(item);
    }
  }

  void _resetPagination() {
    currentPage.value = -1;
    totalElements.value = 0;
    totalPages.value = 0;
    hasNextPage.value = false;
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  bool _validAmount(double amount) => amount.isFinite && amount > 0;
}
