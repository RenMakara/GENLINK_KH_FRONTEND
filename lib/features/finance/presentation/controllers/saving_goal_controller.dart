import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../formatters/finance_localization.dart';
import 'finance_controller.dart';

class SavingGoalController extends GetxController {
  SavingGoalController({
    required this.repository,
    required this.financeController,
    this.refreshWalletState,
  });

  final FinanceRepository repository;
  final FinanceController financeController;
  final Future<void> Function()? refreshWalletState;

  Rx<FinanceCurrency> get selectedCurrency =>
      financeController.selectedCurrency;

  final selectedStatus = RxnString();
  final goals = <FinanceSavingGoalEntity>[].obs;
  final selectedGoal = Rxn<FinanceSavingGoalEntity>();
  final deposits = <FinanceSavingDepositEntity>[].obs;

  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isDetailLoading = false.obs;
  final isDepositsLoading = false.obs;
  final listErrorMessage = RxnString();
  final detailErrorMessage = RxnString();
  final depositsErrorMessage = RxnString();
  final mutationErrorMessage = RxnString();
  final isCreateSubmitting = false.obs;
  final isUpdateSubmitting = false.obs;
  final isDeleteSubmitting = false.obs;
  final isContributionSubmitting = false.obs;

  bool get isEmpty => goals.isEmpty && listErrorMessage.value == null;

  static const statuses = <String>{'IN_PROGRESS', 'COMPLETED', 'CANCELLED'};

  int _listRequestSequence = 0;
  int _detailRequestSequence = 0;
  int _depositRequestSequence = 0;
  Worker? _currencyWorker;
  bool _suppressCurrencyWorker = false;

  @override
  void onInit() {
    super.onInit();
    _currencyWorker = ever<FinanceCurrency>(
      financeController.selectedCurrency,
      (_) {
        if (!_suppressCurrencyWorker) loadGoals();
      },
    );
    loadGoals();
  }

  @override
  void onClose() {
    _currencyWorker?.dispose();
    super.onClose();
  }

  Future<void> loadGoals() async {
    final request = ++_listRequestSequence;
    isInitialLoading.value = true;
    isRefreshing.value = false;
    listErrorMessage.value = null;
    goals.clear();
    try {
      final result = await repository.getSavingGoals(
        status: selectedStatus.value,
        currency: selectedCurrency.value,
      );
      if (request != _listRequestSequence) return;
      _validateCurrencyScope(result, selectedCurrency.value);
      goals.assignAll(result);
    } on AppError catch (error) {
      if (request != _listRequestSequence) return;
      if (!error.isNotFound) listErrorMessage.value = error.message;
    } on FormatException catch (error) {
      if (request != _listRequestSequence) return;
      listErrorMessage.value = error.message;
    } catch (_) {
      if (request != _listRequestSequence) return;
      listErrorMessage.value = 'common.error'.tr;
    } finally {
      if (request == _listRequestSequence) isInitialLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    final request = ++_listRequestSequence;
    final previous = List<FinanceSavingGoalEntity>.from(goals);
    isRefreshing.value = true;
    isInitialLoading.value = false;
    listErrorMessage.value = null;
    try {
      final result = await repository.getSavingGoals(
        status: selectedStatus.value,
        currency: selectedCurrency.value,
      );
      if (request != _listRequestSequence) return;
      _validateCurrencyScope(result, selectedCurrency.value);
      goals.assignAll(result);
    } on AppError catch (error) {
      if (request != _listRequestSequence) return;
      goals.assignAll(previous);
      listErrorMessage.value = error.message;
    } on FormatException catch (error) {
      if (request != _listRequestSequence) return;
      goals.assignAll(previous);
      listErrorMessage.value = error.message;
    } catch (_) {
      if (request != _listRequestSequence) return;
      goals.assignAll(previous);
      listErrorMessage.value = 'common.error'.tr;
    } finally {
      if (request == _listRequestSequence) isRefreshing.value = false;
    }
  }

  Future<void> selectCurrency(FinanceCurrency currency) async {
    if (currency == selectedCurrency.value) return;
    _suppressCurrencyWorker = true;
    try {
      selectedCurrency.value = currency;
      await Future.wait<void>([
        financeController.loadDashboard(currency: currency),
        loadGoals(),
      ]);
    } finally {
      _suppressCurrencyWorker = false;
    }
  }

  Future<void> selectStatus(String? status) async {
    final normalized = status?.trim().toUpperCase();
    if (normalized != null && !statuses.contains(normalized)) {
      listErrorMessage.value = financeText(
        'finance.goal.invalidStatus',
        'Invalid saving goal status.',
      );
      return;
    }
    final next = normalized?.isEmpty == true ? null : normalized;
    if (next == selectedStatus.value) return;
    selectedStatus.value = next;
    await loadGoals();
  }

  Future<void> loadGoal(String savingGoalId) async {
    final request = ++_detailRequestSequence;
    isDetailLoading.value = true;
    detailErrorMessage.value = null;
    try {
      final result = await repository.getSavingGoal(savingGoalId);
      if (request != _detailRequestSequence) return;
      _validateCurrencyScope(<FinanceSavingGoalEntity>[
        result,
      ], selectedCurrency.value);
      selectedGoal.value = result;
    } on AppError catch (error) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = error.message;
      }
    } on FormatException catch (error) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _detailRequestSequence) isDetailLoading.value = false;
    }
  }

  Future<void> loadDeposits(String savingGoalId) async {
    final request = ++_depositRequestSequence;
    isDepositsLoading.value = true;
    depositsErrorMessage.value = null;
    deposits.clear();
    try {
      final result = await repository.getSavingDeposits(savingGoalId);
      if (request != _depositRequestSequence) return;
      deposits.assignAll(result);
    } on AppError catch (error) {
      if (request == _depositRequestSequence) {
        depositsErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _depositRequestSequence) {
        depositsErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _depositRequestSequence) isDepositsLoading.value = false;
    }
  }

  Future<bool> createGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    if (isCreateSubmitting.value) return false;
    final validation = _validateGoal(title, targetAmount);
    if (validation != null) {
      mutationErrorMessage.value = validation;
      return false;
    }
    isCreateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await repository.createSavingGoal(
        title: title.trim(),
        targetAmount: targetAmount,
        targetDate: _optional(targetDate),
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

  Future<bool> updateGoal({
    required FinanceSavingGoalEntity existing,
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    if (isUpdateSubmitting.value) return false;
    final validation = _validateGoal(title, targetAmount);
    if (validation != null) {
      mutationErrorMessage.value = validation;
      return false;
    }
    isUpdateSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      final result = await repository.updateSavingGoal(
        savingGoalId: existing.savingGoalId,
        title: title.trim(),
        targetAmount: targetAmount,
        targetDate: _optional(targetDate),
        currency: existing.currency,
      );
      selectedGoal.value = result;
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

  Future<bool> deleteGoal(String savingGoalId) async {
    if (isDeleteSubmitting.value) return false;
    isDeleteSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      await repository.deleteSavingGoal(savingGoalId);
      if (selectedGoal.value?.savingGoalId == savingGoalId) {
        selectedGoal.value = null;
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
      isDeleteSubmitting.value = false;
    }
  }

  Future<bool> contribute({
    required FinanceSavingGoalEntity goal,
    required double amount,
    String? note,
    String? depositDate,
    required bool fromWallet,
  }) async {
    if (isContributionSubmitting.value) return false;
    if (goal.currency != selectedCurrency.value) {
      mutationErrorMessage.value = financeText(
        'finance.goal.currencyMismatch',
        'Currency does not match the selected goal.',
      );
      return false;
    }
    if (!_validAmount(amount)) {
      mutationErrorMessage.value = financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
      return false;
    }
    isContributionSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      final result = await repository.depositToSavingGoal(
        savingGoalId: goal.savingGoalId,
        amount: amount,
        note: _optional(note),
        depositDate: _optional(depositDate),
        fromWallet: fromWallet,
      );
      selectedGoal.value = result;
      await Future.wait<void>([
        loadGoals(),
        financeController.reload(),
        if (refreshWalletState != null) refreshWalletState!(),
        loadDeposits(goal.savingGoalId),
      ]);
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isContributionSubmitting.value = false;
    }
  }

  void clearMutationError() => mutationErrorMessage.value = null;

  Future<void> _refreshAfterMutation() async {
    await Future.wait<void>([loadGoals(), financeController.reload()]);
  }

  String? _validateGoal(String title, double targetAmount) {
    if (title.trim().isEmpty) {
      return financeText(
        'finance.goal.titleRequired',
        'A goal title is required.',
      );
    }
    if (title.trim().length > 160) {
      return financeText(
        'finance.goal.titleTooLong',
        'Goal title is too long.',
      );
    }
    if (!_validAmount(targetAmount)) {
      return financeText(
        'finance.validation.invalidAmount',
        'Amount must be greater than zero.',
      );
    }
    return null;
  }

  bool _validAmount(double amount) => amount.isFinite && amount > 0;

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _validateCurrencyScope(
    List<FinanceSavingGoalEntity> values,
    FinanceCurrency currency,
  ) {
    if (values.any((goal) => goal.currency != currency)) {
      throw const FormatException('Saving goal currency mismatch');
    }
  }
}
