import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_controller.dart';

class FinanceToolsController extends GetxController {
  FinanceToolsController({
    required this._repository,
    required this._financeController,
  });

  final FinanceRepository _repository;
  final FinanceController _financeController;

  final recurringTransactions = <FinanceRecurringTransactionEntity>[].obs;
  final autoSaveRules = <FinanceAutoSaveRuleEntity>[].obs;
  final savingGoals = <FinanceSavingGoalEntity>[].obs;

  final isRecurringLoading = false.obs;
  final isAutoSaveLoading = false.obs;
  final isGoalsLoading = false.obs;
  final isRecurringSubmitting = false.obs;
  final isAutoSaveSubmitting = false.obs;
  final deletingRecurringId = RxnString();
  final deletingAutoSaveId = RxnString();

  final recurringErrorMessage = RxnString();
  final autoSaveErrorMessage = RxnString();
  final goalsErrorMessage = RxnString();
  final recurringMutationError = RxnString();
  final autoSaveMutationError = RxnString();

  final insightsCurrency = FinanceCurrency.usd.obs;
  final insightsMonth = DateTime.now().month.obs;
  final insightsYear = DateTime.now().year.obs;

  FinanceCurrency? _goalsCurrency;
  int _recurringRequest = 0;
  int _autoSaveRequest = 0;
  int _goalsRequest = 0;

  @override
  void onInit() {
    super.onInit();
    insightsCurrency.value = _financeController.selectedCurrency.value;
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait<void>([
      loadRecurringTransactions(),
      loadAutoSaveRules(),
      loadInsights(),
    ]);
  }

  Future<void> loadRecurringTransactions() async {
    final request = ++_recurringRequest;
    isRecurringLoading.value = true;
    recurringErrorMessage.value = null;
    try {
      final items = await _repository.getRecurringTransactions();
      if (request == _recurringRequest) {
        recurringTransactions.assignAll(items);
      }
    } on AppError catch (error) {
      if (request == _recurringRequest) {
        recurringErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _recurringRequest) {
        recurringErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _recurringRequest) isRecurringLoading.value = false;
    }
  }

  Future<void> loadAutoSaveRules() async {
    final request = ++_autoSaveRequest;
    isAutoSaveLoading.value = true;
    autoSaveErrorMessage.value = null;
    try {
      final items = await _repository.getAutoSaveRules();
      if (request == _autoSaveRequest) autoSaveRules.assignAll(items);
    } on AppError catch (error) {
      if (request == _autoSaveRequest) {
        autoSaveErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _autoSaveRequest) {
        autoSaveErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _autoSaveRequest) isAutoSaveLoading.value = false;
    }
  }

  Future<void> loadInsights() async {
    await _financeController.loadFinanceInsights(
      currency: insightsCurrency.value,
      month: insightsMonth.value,
      year: insightsYear.value,
    );
  }

  Future<void> selectInsightsCurrency(FinanceCurrency currency) async {
    if (currency == insightsCurrency.value) return;
    insightsCurrency.value = currency;
    await loadInsights();
  }

  Future<void> selectInsightsPeriod({
    required int month,
    required int year,
  }) async {
    if (month < 1 || month > 12 || year < 1) return;
    if (month == insightsMonth.value && year == insightsYear.value) return;
    insightsMonth.value = month;
    insightsYear.value = year;
    await loadInsights();
  }

  Future<void> previousInsightsMonth() async {
    final previous = DateTime(insightsYear.value, insightsMonth.value - 1, 1);
    await selectInsightsPeriod(month: previous.month, year: previous.year);
  }

  Future<void> nextInsightsMonth() async {
    final next = DateTime(insightsYear.value, insightsMonth.value + 1, 1);
    await selectInsightsPeriod(month: next.month, year: next.year);
  }

  Future<bool> createRecurringTransaction({
    required FinanceRecurringType type,
    required String title,
    required String amountText,
    required FinanceRecurringFrequency frequency,
    required String startDate,
    required FinanceCurrency currency,
    String? category,
    bool fromWallet = false,
    String? endDate,
  }) async {
    if (isRecurringSubmitting.value) return false;
    recurringMutationError.value = null;
    final trimmedTitle = title.trim();
    final amount = FinanceMoney.tryParseInput(amountText);
    if (trimmedTitle.isEmpty || trimmedTitle.length > 160) {
      recurringMutationError.value = 'finance.tools.validationTitle'.tr;
      return false;
    }
    if (amount == null || amount.sign <= 0) {
      recurringMutationError.value = 'finance.tools.validationAmount'.tr;
      return false;
    }
    final parsedStart = DateTime.tryParse(startDate);
    final validStart =
        parsedStart != null &&
        '${parsedStart.year.toString().padLeft(4, '0')}-${parsedStart.month.toString().padLeft(2, '0')}-${parsedStart.day.toString().padLeft(2, '0')}' ==
            startDate;
    if (!validStart) {
      recurringMutationError.value = 'finance.tools.validationStartDate'.tr;
      return false;
    }
    final parsedEnd = endDate == null ? null : DateTime.tryParse(endDate);
    if (endDate != null &&
        (parsedEnd == null ||
            '${parsedEnd.year.toString().padLeft(4, '0')}-${parsedEnd.month.toString().padLeft(2, '0')}-${parsedEnd.day.toString().padLeft(2, '0')}' !=
                endDate ||
                parsedEnd.isBefore(parsedStart))) {
      recurringMutationError.value = 'finance.tools.validationDateRange'.tr;
      return false;
    }
    final normalizedCategory = _optional(category);
    if (normalizedCategory != null && normalizedCategory.length > 80) {
      recurringMutationError.value = 'finance.tools.validationCategory'.tr;
      return false;
    }

    isRecurringSubmitting.value = true;
    try {
      final created = await _repository.createRecurringTransaction(
        type: type,
        title: trimmedTitle,
        amount: double.parse(amount.toDecimalString()),
        frequency: frequency,
        startDate: startDate,
        currency: currency,
        category: normalizedCategory,
        fromWallet: type == FinanceRecurringType.expense && fromWallet,
        endDate: endDate,
      );
      recurringTransactions.insert(0, created);
      await loadRecurringTransactions();
      return true;
    } on AppError catch (error) {
      recurringMutationError.value = error.message;
      return false;
    } catch (_) {
      recurringMutationError.value = 'common.error'.tr;
      return false;
    } finally {
      isRecurringSubmitting.value = false;
    }
  }

  Future<bool> deleteRecurringTransaction(String id) async {
    if (deletingRecurringId.value != null) return false;
    recurringMutationError.value = null;
    deletingRecurringId.value = id;
    try {
      await _repository.deleteRecurringTransaction(id);
      recurringTransactions.removeWhere((item) => item.id == id);
      return true;
    } on AppError catch (error) {
      recurringMutationError.value = error.message;
      return false;
    } catch (_) {
      recurringMutationError.value = 'common.error'.tr;
      return false;
    } finally {
      deletingRecurringId.value = null;
    }
  }

  Future<void> loadSavingGoals(FinanceCurrency currency) async {
    final request = ++_goalsRequest;
    if (_goalsCurrency != currency) savingGoals.clear();
    _goalsCurrency = currency;
    isGoalsLoading.value = true;
    goalsErrorMessage.value = null;
    try {
      final goals = await _repository.getSavingGoals(
        status: 'IN_PROGRESS',
        currency: currency,
      );
      if (request == _goalsRequest) savingGoals.assignAll(goals);
    } on AppError catch (error) {
      if (request == _goalsRequest) goalsErrorMessage.value = error.message;
    } catch (_) {
      if (request == _goalsRequest) goalsErrorMessage.value = 'common.error'.tr;
    } finally {
      if (request == _goalsRequest) isGoalsLoading.value = false;
    }
  }

  Future<bool> createAutoSaveRule({
    required String savingGoalId,
    required FinanceAutoSaveType type,
    String? percentText,
  }) async {
    if (isAutoSaveSubmitting.value) return false;
    autoSaveMutationError.value = null;
    FinanceSavingGoalEntity? goal;
    for (final candidate in savingGoals) {
      if (candidate.savingGoalId == savingGoalId) {
        goal = candidate;
        break;
      }
    }
    if (goal == null) {
      autoSaveMutationError.value = 'finance.tools.selectGoal'.tr;
      return false;
    }

    double? percent;
    if (type == FinanceAutoSaveType.percentOfIncome) {
      final value = FinanceMoney.tryParseInput(percentText ?? '');
      if (value == null ||
          value.sign <= 0 ||
          value.compareTo(FinanceMoney.tryParseInput('100')!) > 0) {
        autoSaveMutationError.value = 'finance.tools.validationPercent'.tr;
        return false;
      }
      percent = double.parse(value.toDecimalString());
    }

    isAutoSaveSubmitting.value = true;
    try {
      final created = await _repository.createAutoSaveRule(
        savingGoalId: savingGoalId,
        type: type,
        currency: goal.currency,
        percent: percent,
      );
      autoSaveRules.insert(0, created);
      await loadAutoSaveRules();
      return true;
    } on AppError catch (error) {
      autoSaveMutationError.value = error.message;
      return false;
    } catch (_) {
      autoSaveMutationError.value = 'common.error'.tr;
      return false;
    } finally {
      isAutoSaveSubmitting.value = false;
    }
  }

  Future<bool> deleteAutoSaveRule(String id) async {
    if (deletingAutoSaveId.value != null) return false;
    autoSaveMutationError.value = null;
    deletingAutoSaveId.value = id;
    try {
      await _repository.deleteAutoSaveRule(id);
      autoSaveRules.removeWhere((item) => item.id == id);
      return true;
    } on AppError catch (error) {
      autoSaveMutationError.value = error.message;
      return false;
    } catch (_) {
      autoSaveMutationError.value = 'common.error'.tr;
      return false;
    } finally {
      deletingAutoSaveId.value = null;
    }
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
