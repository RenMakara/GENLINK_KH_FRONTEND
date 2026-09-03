import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_controller.dart';

/// Owns the state for the demo wallet screens.
///
/// Wallet operations are deliberately backend-confirmed.  The controller does
/// not calculate a new authoritative balance locally; after a successful
/// mutation it refreshes both wallet resources and the dashboard snapshot.
class EWalletController extends GetxController {
  EWalletController(this._repository, this._financeController);

  final FinanceRepository _repository;
  final FinanceController _financeController;

  /// The wallet follows the Finance dashboard's single currency selection.
  Rx<FinanceCurrency> get selectedCurrency =>
      _financeController.selectedCurrency;

  final wallet = Rxn<FinanceWalletEntity>();
  final transactions = <FinanceWalletTransactionEntity>[].obs;

  final isInitialLoading = false.obs;
  final isWalletLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasNextPage = false.obs;

  final walletErrorMessage = RxnString();
  final historyErrorMessage = RxnString();
  final operationErrorMessage = RxnString();
  final isOperationLoading = false.obs;

  static const int pageSize = 20;
  int _currentPage = -1;
  int _walletRequestSequence = 0;
  int _historyRequestSequence = 0;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  /// Loads balance and the first history page without displaying fake data.
  Future<void> loadInitial() async {
    final walletRequest = ++_walletRequestSequence;
    final historyRequest = ++_historyRequestSequence;

    isInitialLoading.value = true;
    // A reload supersedes an in-flight next-page request. The stale request
    // must not be allowed to leave pagination disabled in its guarded finally
    // block.
    isLoadingMore.value = false;
    walletErrorMessage.value = null;
    historyErrorMessage.value = null;
    wallet.value = null;
    transactions.clear();
    _currentPage = -1;
    hasNextPage.value = false;

    // GET /finance/wallet creates the user's zero-balance wallet on first
    // access.  Load it before history so the page-0 request cannot race that
    // creation and incorrectly report a missing wallet.
    await _loadWallet(walletRequest);
    if (walletRequest == _walletRequestSequence) {
      await _loadHistory(historyRequest, reset: true);
    }

    if (walletRequest == _walletRequestSequence &&
        historyRequest == _historyRequestSequence) {
      isInitialLoading.value = false;
    }
  }

  /// Pull-to-refresh resets history pagination and reloads the current wallet.
  @override
  Future<void> refresh() => loadInitial();

  Future<void> loadWallet() async {
    await _loadWallet(++_walletRequestSequence);
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value ||
        isHistoryLoading.value ||
        !hasNextPage.value ||
        _currentPage < 0) {
      return;
    }

    final request = ++_historyRequestSequence;
    final nextPage = _currentPage + 1;
    isLoadingMore.value = true;
    historyErrorMessage.value = null;
    try {
      final result = await _repository.getWalletTransactions(
        page: nextPage,
        size: pageSize,
      );
      if (request != _historyRequestSequence) return;
      _appendTransactions(result.content);
      _currentPage = result.page;
      hasNextPage.value = result.hasNext;
    } on AppError catch (error) {
      if (request == _historyRequestSequence) {
        historyErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _historyRequestSequence) {
        historyErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _historyRequestSequence) {
        isLoadingMore.value = false;
      }
    }
  }

  /// Changes the shared Finance currency and reloads all currency-dependent
  /// presentation state.  The wallet endpoint returns both balances, so no
  /// conversion or cross-currency arithmetic is performed here.
  Future<void> selectCurrency(FinanceCurrency currency) async {
    if (currency == selectedCurrency.value) return;
    selectedCurrency.value = currency;
    // Do not render the previous currency's snapshot while the new request is
    // in flight.  The wallet endpoint returns both balances, but the selected
    // view must still wait for a current authenticated response.
    wallet.value = null;
    walletErrorMessage.value = null;
    isLoadingMore.value = false;
    await Future.wait<void>([
      _financeController.loadDashboard(currency: currency),
      loadWallet(),
      _loadHistory(++_historyRequestSequence, reset: true),
    ]);
    isInitialLoading.value = false;
  }

  Future<bool> topUpWallet({required double amount, String? note}) {
    return _runOperation(
      () => _repository.topUpWallet(
        amount: amount,
        note: note,
        currency: selectedCurrency.value,
      ),
    );
  }

  Future<bool> makePayment({
    required double amount,
    String? merchant,
    String? note,
  }) {
    return _runOperation(
      () => _repository.makePayment(
        amount: amount,
        merchant: merchant,
        note: note,
        currency: selectedCurrency.value,
      ),
    );
  }

  void clearOperationError() => operationErrorMessage.value = null;

  double balanceFor(FinanceCurrency currency) {
    final current = wallet.value;
    if (current == null) return 0;
    return currency == FinanceCurrency.usd
        ? current.balanceUsd
        : current.balanceKhr;
  }

  List<FinanceWalletTransactionEntity> get visibleTransactions => transactions
      .where((transaction) => transaction.currency == selectedCurrency.value)
      .toList(growable: false);

  double get recentDebits => _sumByDirection('DEBIT');

  double get recentCredits => _sumByDirection('CREDIT');

  Future<void> _loadWallet(int request) async {
    isWalletLoading.value = true;
    walletErrorMessage.value = null;
    try {
      final result = await _repository.getWallet();
      if (request == _walletRequestSequence) {
        wallet.value = result;
      }
    } on AppError catch (error) {
      if (request == _walletRequestSequence) {
        walletErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _walletRequestSequence) {
        walletErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _walletRequestSequence) {
        isWalletLoading.value = false;
      }
    }
  }

  Future<void> _loadHistory(int request, {required bool reset}) async {
    isHistoryLoading.value = true;
    historyErrorMessage.value = null;
    if (reset) {
      transactions.clear();
      _currentPage = -1;
      hasNextPage.value = false;
    }
    try {
      final result = await _repository.getWalletTransactions(
        page: 0,
        size: pageSize,
      );
      if (request != _historyRequestSequence) return;
      _appendTransactions(result.content);
      _currentPage = result.page;
      hasNextPage.value = result.hasNext;
    } on AppError catch (error) {
      if (request == _historyRequestSequence) {
        historyErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _historyRequestSequence) {
        historyErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _historyRequestSequence) {
        isHistoryLoading.value = false;
      }
    }
  }

  Future<bool> _runOperation(
    Future<FinanceWalletEntity> Function() operation,
  ) async {
    if (isOperationLoading.value) return false;
    isOperationLoading.value = true;
    operationErrorMessage.value = null;
    try {
      // The response is useful as an immediate backend-confirmed snapshot,
      // but the follow-up reads keep history and dashboard state consistent.
      wallet.value = await operation();
      await Future.wait<void>([
        loadWallet(),
        _loadHistory(++_historyRequestSequence, reset: true),
        _financeController.reload(),
      ]);
      return true;
    } on AppError catch (error) {
      operationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      operationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isOperationLoading.value = false;
    }
  }

  void _appendTransactions(List<FinanceWalletTransactionEntity> items) {
    final existing = transactions.map((item) => item.transactionId).toSet();
    for (final item in items) {
      if (existing.add(item.transactionId)) transactions.add(item);
    }
  }

  double _sumByDirection(String direction) {
    return visibleTransactions
        .where(
          (transaction) =>
              transaction.status.toUpperCase() == 'SUCCESS' &&
              transaction.direction.toUpperCase() == direction,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount.abs());
  }
}
