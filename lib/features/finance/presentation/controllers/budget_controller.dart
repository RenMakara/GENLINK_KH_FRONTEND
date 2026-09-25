import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_localization.dart';
import 'finance_controller.dart';

class BudgetController extends GetxController {
  BudgetController({
    required this._repository,
    required this._financeController,
  });

  final FinanceRepository _repository;
  final FinanceController _financeController;

  Rx<FinanceCurrency> get selectedCurrency =>
      _financeController.selectedCurrency;

  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final budget = Rxn<FinanceBudgetEntity>();

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final listErrorMessage = RxnString();
  final mutationErrorMessage = RxnString();
  final isCreateSubmitting = false.obs;
  final isUpdateSubmitting = false.obs;
  final isDeleteSubmitting = false.obs;

  int _requestSequence = 0;
  Worker? _currencyWorker;
  bool _suppressCurrencyWorker = false;

  bool get isEmpty => budget.value == null && listErrorMessage.value == null;

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
    listErrorMessage.value = null;
    budget.value = null;
    await _load(request, preserveExisting: false);
    if (request == _requestSequence) isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    final request = ++_requestSequence;
    isRefreshing.value = true;
    isLoading.value = false;
    listErrorMessage.value = null;
    try {
      await _load(request, preserveExisting: true);
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
      listErrorMessage.value = financeText(
        'finance.budget.invalidPeriod',
        'Invalid budget period.',
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

  Future<bool> createBudget({
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
  }) async {
    if (isCreateSubmitting.value) return false;
    if (!_validAmount(totalBudget)) {
      mutationErrorMessage.value = financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
      return false;
    }
    final normalizedCategories = _normalizeCategories(categories);
    final validation = _validateCategories(normalizedCategories);
    if (validation != null) {
      mutationErrorMessage.value = validation;
      return false;
    }
    isCreateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.createBudget(
        month: selectedMonth.value,
        year: selectedYear.value,
        totalBudget: totalBudget,
        categories: normalizedCategories,
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

  Future<bool> updateBudget({
    required FinanceBudgetEntity existing,
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
    int? month,
    int? year,
  }) async {
    if (isUpdateSubmitting.value) return false;
    if (!_validAmount(totalBudget)) {
      mutationErrorMessage.value = financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
      return false;
    }
    final normalizedCategories = _normalizeCategories(categories);
    final validation = _validateCategories(normalizedCategories);
    if (validation != null) {
      mutationErrorMessage.value = validation;
      return false;
    }
    isUpdateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.updateBudget(
        budgetId: existing.budgetId,
        month: month ?? existing.month,
        year: year ?? existing.year,
        totalBudget: totalBudget,
        categories: normalizedCategories,
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

  Future<bool> deleteBudget({String? budgetId}) async {
    final existing = budget.value;
    final id = budgetId ?? existing?.budgetId;
    if (id == null || isDeleteSubmitting.value) return false;
    isDeleteSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await _repository.deleteBudget(id);
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
    await Future.wait<void>([load(), _financeController.reload()]);
  }

  Future<void> _load(int request, {required bool preserveExisting}) async {
    try {
      final result = await _repository.getCurrentBudget(
        currency: selectedCurrency.value,
        month: selectedMonth.value,
        year: selectedYear.value,
      );
      if (request != _requestSequence) return;
      if (result.currency != selectedCurrency.value ||
          result.month != selectedMonth.value ||
          result.year != selectedYear.value) {
        throw const FormatException('Budget scope mismatch');
      }
      budget.value = result;
    } on AppError catch (error) {
      if (request != _requestSequence) return;
      if (error.isNotFound) {
        budget.value = null;
        listErrorMessage.value = null;
      } else {
        if (!preserveExisting) budget.value = null;
        listErrorMessage.value = error.message;
      }
    } on FormatException catch (error) {
      if (request != _requestSequence) return;
      if (!preserveExisting) budget.value = null;
      listErrorMessage.value = error.message;
    } catch (_) {
      if (request != _requestSequence) return;
      if (!preserveExisting) budget.value = null;
      listErrorMessage.value = 'common.error'.tr;
    }
  }

  String? _validateCategories(List<FinanceBudgetAllocation>? categories) {
    if (categories == null) return null;
    final seen = <String>{};
    for (final category in categories) {
      final name = category.category.trim();
      if (name.isEmpty) {
        return financeText(
          'finance.budget.categoryRequired',
          'Category name is required.',
        );
      }
      if (name.length > 80) {
        return financeText(
          'finance.budget.categoryTooLong',
          'Category name is too long.',
        );
      }
      if (!_validAmount(category.allocatedAmount)) {
        return financeText(
          'finance.budget.categoryAmount',
          'Category amounts must be greater than zero.',
        );
      }
      if (!seen.add(name)) {
        return financeText(
          'finance.budget.categoriesUnique',
          'Categories must be unique.',
        );
      }
    }
    return null;
  }

  List<FinanceBudgetAllocation>? _normalizeCategories(
    List<FinanceBudgetAllocation>? categories,
  ) {
    return categories
        ?.map(
          (category) => FinanceBudgetAllocation(
            category: category.category.trim(),
            allocatedAmount: category.allocatedAmount,
          ),
        )
        .toList(growable: false);
  }

  bool _validAmount(double amount) => amount.isFinite && amount > 0;
}
