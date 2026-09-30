import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_localization.dart';
import 'finance_controller.dart';

class ExpenseController extends GetxController {
  ExpenseController({
    required this._repository,
    required this._financeController,
  });

  final FinanceRepository _repository;
  final FinanceController _financeController;

  Rx<FinanceCurrency> get selectedCurrency =>
      _financeController.selectedCurrency;

  final selectedCategory = RxnString();
  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final hasExplicitMonthFilter = false.obs;

  final expenses = <FinanceExpenseEntity>[].obs;
  final budgetCategories = <String>[].obs;

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
  int _budgetCategoryRequestSequence = 0;
  Worker? _currencyWorker;
  Worker? _dashboardWorker;
  bool _suppressCurrencyWorker = false;

  @override
  void onInit() {
    super.onInit();
    final dMonth = _financeController.dashboard.value?.month;
    if (dMonth != null) {
      selectedMonth.value = dMonth.month;
      selectedYear.value = dMonth.year;
    }
    _dashboardWorker = ever<FinanceDashboardEntity?>(
      _financeController.dashboard,
      (d) {
        if (!hasExplicitMonthFilter.value && d?.month != null) {
          selectedMonth.value = d!.month.month;
          selectedYear.value = d.month.year;
        }
      },
    );
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
    _dashboardWorker?.dispose();
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
    expenses.clear();
    _resetPagination();

    await _loadPage(request, page: 0, replace: true);
    if (request == _requestSequence) {
      isInitialLoading.value = false;
    }
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

  Future<void> selectCategory(String? category) async {
    final normalized = category?.trim().isEmpty == true
        ? null
        : category?.trim().toUpperCase();
    if (normalized == selectedCategory.value) return;
    selectedCategory.value = normalized;
    await loadInitial();
  }

  Future<void> selectPeriod({required int month, required int year}) async {
    if (month < 1 || month > 12 || year < 1) return;
    if (month == selectedMonth.value &&
        year == selectedYear.value &&
        hasExplicitMonthFilter.value) {
      return;
    }
    hasExplicitMonthFilter.value = true;
    selectedMonth.value = month;
    selectedYear.value = year;
    await Future.wait<void>([
      loadInitial(),
      loadBudgetCategories(
        currency: selectedCurrency.value,
        month: month,
        year: year,
      ),
    ]);
  }

  Future<void> selectPreviousMonth() async {
    final previous = DateTime(selectedYear.value, selectedMonth.value - 1, 1);
    await selectPeriod(month: previous.month, year: previous.year);
  }

  Future<void> selectNextMonth() async {
    final next = DateTime(selectedYear.value, selectedMonth.value + 1, 1);
    await selectPeriod(month: next.month, year: next.year);
  }

  Future<void> loadBudgetCategories({
    required FinanceCurrency currency,
    required int month,
    required int year,
  }) async {
    final request = ++_budgetCategoryRequestSequence;
    budgetCategories.clear();
    try {
      final currentBudget = await _repository.getCurrentBudget(
        currency: currency,
        month: month,
        year: year,
      );
      if (request != _budgetCategoryRequestSequence ||
          currentBudget.currency != currency ||
          currentBudget.month != month ||
          currentBudget.year != year) {
        return;
      }
      budgetCategories.assignAll(
        currentBudget.categories
            .map((allocation) => allocation.category.trim())
            .where((category) => category.isNotEmpty),
      );
    } catch (_) {
      // Standard expense categories remain available if no budget exists or the
      // budget endpoint is temporarily unavailable.
    }
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
      if (request == _requestSequence) {
        isLoadingMore.value = false;
      }
    }
  }

  FinanceExpenseEntity? findExpense(String expenseId) {
    for (final expense in expenses) {
      if (expense.expenseId == expenseId) return expense;
    }
    return null;
  }

  Future<void> clearMonthFilter() async {
    if (!hasExplicitMonthFilter.value) return;
    hasExplicitMonthFilter.value = false;
    await refresh();
  }

  Future<bool> createExpense({
    required String title,
    required double amount,
    required String expenseDate,
    String? category,
    String? description,
    String? paymentMethod,
    bool paidFromWallet = false,
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
      final created = await _repository.createExpense(
        title: title,
        amount: amount,
        expenseDate: expenseDate,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        paidFromWallet: paidFromWallet,
        currency: selectedCurrency.value,
      );
      if (!expenses.any((e) => e.expenseId == created.expenseId)) {
        expenses.insert(0, created);
      }
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

  Future<bool> updateExpense({
    required FinanceExpenseEntity existing,
    required String title,
    required double amount,
    required String expenseDate,
    String? category,
    String? description,
    String? paymentMethod,
    required bool paidFromWallet,
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
      final updated = await _repository.updateExpense(
        expenseId: existing.expenseId,
        title: title,
        amount: amount,
        expenseDate: expenseDate,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        paidFromWallet: paidFromWallet,
        currency: existing.currency,
      );
      final index = expenses.indexWhere(
        (e) => e.expenseId == existing.expenseId,
      );
      if (index >= 0) {
        expenses[index] = updated;
      } else {
        expenses.insert(0, updated);
      }
      expenses.refresh();
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

  Future<bool> deleteExpense(String expenseId) async {
    if (isDeleteSubmitting.value) return false;
    isDeleteSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.deleteExpense(expenseId);
      expenses.removeWhere((e) => e.expenseId == expenseId);
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
    await Future.wait<void>([refresh(), _financeController.reload()]);
  }

  Future<void> _loadPage(
    int request, {
    required int page,
    required bool replace,
  }) async {
    try {
      final result = await _repository.getExpenses(
        category: selectedCategory.value,
        currency: selectedCurrency.value,
        month: hasExplicitMonthFilter.value ? selectedMonth.value : null,
        year: hasExplicitMonthFilter.value ? selectedYear.value : null,
        page: page,
        size: pageSize,
      );
      if (request != _requestSequence) return;

      if (replace) {
        expenses
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

  void _appendDeduplicated(List<FinanceExpenseEntity> items) {
    final existing = expenses.map((item) => item.expenseId).toSet();
    for (final item in items) {
      if (existing.add(item.expenseId)) expenses.add(item);
    }
  }

  void _resetPagination() {
    currentPage.value = -1;
    totalElements.value = 0;
    totalPages.value = 0;
    hasNextPage.value = false;
  }

  bool _validAmount(double amount) =>
      FinanceMoney.tryFromNumber(amount)?.sign == 1;
}
