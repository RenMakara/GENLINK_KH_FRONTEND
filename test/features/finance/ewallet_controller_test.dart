import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceWalletEntity _wallet({double usd = 20, double khr = 100000}) {
  return FinanceWalletEntity(
    walletId: 'wallet-1',
    balanceUsd: usd,
    balanceKhr: khr,
  );
}

FinanceWalletTransactionEntity _transaction({
  required String id,
  required FinanceCurrency currency,
  String type = 'DEPOSIT',
  String direction = 'CREDIT',
}) {
  return FinanceWalletTransactionEntity(
    transactionId: id,
    transactionType: type,
    direction: direction,
    currency: currency,
    amount: currency == FinanceCurrency.usd ? 5 : 5000,
    description: 'Test transaction',
    status: 'SUCCESS',
    createdAt: '2026-08-20T10:00:00Z',
  );
}

FinancePage<FinanceWalletTransactionEntity> _page(
  List<FinanceWalletTransactionEntity> content, {
  int page = 0,
  bool hasNext = false,
}) {
  return FinancePage(
    content: content,
    page: page,
    size: 20,
    totalElements: content.length,
    totalPages: hasNext ? page + 2 : page + 1,
    hasNext: hasNext,
  );
}

FinanceDashboardEntity _dashboard() {
  return const FinanceDashboardEntity(
    currency: FinanceCurrency.usd,
    month: FinanceMonthOverview(
      month: 8,
      year: 2026,
      currency: FinanceCurrency.usd,
      spent: 0,
    ),
    topCategories: [],
    saving: FinanceSavingProgress(
      currency: FinanceCurrency.usd,
      totalTarget: 0,
      totalSaved: 0,
      progressPercent: 0,
      activeGoals: 0,
    ),
    recentExpenses: [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late EWalletController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller = EWalletController(repository, financeController);
  });

  tearDown(Get.reset);

  void stubInitial({
    FinanceWalletEntity wallet = const FinanceWalletEntity(
      walletId: 'wallet-1',
      balanceUsd: 20,
      balanceKhr: 100000,
    ),
    FinancePage<FinanceWalletTransactionEntity> page =
        const FinancePage<FinanceWalletTransactionEntity>(
          content: [],
          page: 0,
          size: 20,
          totalElements: 0,
          totalPages: 0,
          hasNext: false,
        ),
  }) {
    when(() => repository.getWallet()).thenAnswer((_) async => wallet);
    when(
      () => repository.getWalletTransactions(page: 0, size: 20),
    ).thenAnswer((_) async => page);
  }

  test(
    'loads wallet and first history page without mixing currencies',
    () async {
      stubInitial(
        page: _page([
          _transaction(id: 'usd', currency: FinanceCurrency.usd),
          _transaction(id: 'khr', currency: FinanceCurrency.khr),
        ]),
      );

      await controller.loadInitial();

      expect(controller.balanceFor(FinanceCurrency.usd), 20);
      expect(controller.balanceFor(FinanceCurrency.khr), 100000);
      expect(controller.visibleTransactions.map((item) => item.transactionId), [
        'usd',
      ]);
      financeController.selectedCurrency.value = FinanceCurrency.khr;
      expect(controller.visibleTransactions.map((item) => item.transactionId), [
        'khr',
      ]);
      verify(() => repository.getWallet()).called(1);
      verify(
        () => repository.getWalletTransactions(page: 0, size: 20),
      ).called(1);
    },
  );

  test('preserves backend wallet load error', () async {
    when(() => repository.getWallet()).thenThrow(
      const AppError(
        message: 'Wallet unavailable',
        errorCode: 'API_ERROR',
        statusCode: 503,
      ),
    );
    when(
      () => repository.getWalletTransactions(page: 0, size: 20),
    ).thenAnswer((_) async => _page([]));

    await controller.loadInitial();

    expect(controller.wallet.value, isNull);
    expect(controller.walletErrorMessage.value, 'Wallet unavailable');
    expect(controller.isInitialLoading.value, isFalse);
  });

  test('loads the next history page and prevents duplicate rows', () async {
    stubInitial(
      page: _page([
        _transaction(id: 'one', currency: FinanceCurrency.usd),
      ], hasNext: true),
    );
    when(() => repository.getWalletTransactions(page: 1, size: 20)).thenAnswer(
      (_) async => _page([
        _transaction(id: 'one', currency: FinanceCurrency.usd),
        _transaction(id: 'two', currency: FinanceCurrency.usd),
      ], page: 1),
    );

    await controller.loadInitial();
    await controller.loadNextPage();

    expect(controller.transactions.map((item) => item.transactionId), [
      'one',
      'two',
    ]);
    verify(() => repository.getWalletTransactions(page: 1, size: 20)).called(1);
  });

  test('refresh resets history to page zero', () async {
    stubInitial(
      page: _page([
        _transaction(id: 'one', currency: FinanceCurrency.usd),
      ], hasNext: true),
    );
    when(() => repository.getWalletTransactions(page: 1, size: 20)).thenAnswer(
      (_) async => _page([
        _transaction(id: 'two', currency: FinanceCurrency.usd),
      ], page: 1),
    );

    await controller.loadInitial();
    await controller.loadNextPage();
    await controller.refresh();

    expect(controller.transactions.map((item) => item.transactionId), ['one']);
    verify(() => repository.getWalletTransactions(page: 0, size: 20)).called(2);
  });

  test(
    'refresh during history pagination does not leave loading stuck',
    () async {
      final nextPage = Completer<FinancePage<FinanceWalletTransactionEntity>>();
      final refreshedPage =
          Completer<FinancePage<FinanceWalletTransactionEntity>>();
      var pageZeroCalls = 0;
      when(() => repository.getWallet()).thenAnswer((_) async => _wallet());
      when(
        () => repository.getWalletTransactions(page: 0, size: 20),
      ).thenAnswer((_) {
        pageZeroCalls++;
        return pageZeroCalls == 1
            ? Future.value(
                _page([
                  _transaction(id: 'one', currency: FinanceCurrency.usd),
                ], hasNext: true),
              )
            : refreshedPage.future;
      });
      when(
        () => repository.getWalletTransactions(page: 1, size: 20),
      ).thenAnswer((_) => nextPage.future);

      await controller.loadInitial();
      final loadingNextPage = controller.loadNextPage();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isLoadingMore.value, isTrue);

      final refreshing = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isLoadingMore.value, isFalse);

      nextPage.complete(
        _page([
          _transaction(id: 'next', currency: FinanceCurrency.usd),
        ], page: 1),
      );
      await loadingNextPage;
      refreshedPage.complete(
        _page([_transaction(id: 'refreshed', currency: FinanceCurrency.usd)]),
      );
      await refreshing;

      expect(controller.isLoadingMore.value, isFalse);
      expect(controller.transactions.map((item) => item.transactionId), [
        'refreshed',
      ]);
    },
  );

  test('top-up sends selected currency and refreshes wallet state', () async {
    var currentWallet = _wallet(usd: 20, khr: 100000);
    when(() => repository.getWallet()).thenAnswer((_) async => currentWallet);
    when(
      () => repository.getWalletTransactions(page: 0, size: 20),
    ).thenAnswer((_) async => _page([]));
    when(
      () => repository.topUpWallet(
        amount: 12,
        note: 'cash',
        currency: FinanceCurrency.khr,
      ),
    ).thenAnswer((_) async {
      currentWallet = _wallet(usd: 20, khr: 100012);
      return currentWallet;
    });
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer(
      (_) async => const FinanceDashboardEntity(
        currency: FinanceCurrency.khr,
        month: FinanceMonthOverview(
          month: 8,
          year: 2026,
          currency: FinanceCurrency.khr,
          spent: 0,
        ),
        topCategories: [],
        saving: FinanceSavingProgress(
          currency: FinanceCurrency.khr,
          totalTarget: 0,
          totalSaved: 0,
          progressPercent: 0,
          activeGoals: 0,
        ),
        recentExpenses: [],
      ),
    );
    financeController.selectedCurrency.value = FinanceCurrency.khr;

    expect(await controller.topUpWallet(amount: 12, note: 'cash'), isTrue);

    expect(controller.wallet.value?.balanceKhr, 100012);
    expect(controller.isOperationLoading.value, isFalse);
    verify(
      () => repository.topUpWallet(
        amount: 12,
        note: 'cash',
        currency: FinanceCurrency.khr,
      ),
    ).called(1);
    verify(() => repository.getWalletTransactions(page: 0, size: 20)).called(1);
  });

  test('payment failure is exposed and does not refresh as success', () async {
    stubInitial();
    when(
      () => repository.makePayment(
        amount: 100,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(
        message: 'Not enough balance',
        errorCode: 'DEMO_WALLET_INSUFFICIENT_BALANCE',
        statusCode: 422,
      ),
    );

    expect(
      await controller.makePayment(amount: 100, merchant: 'ShopABC · KHQR'),
      isFalse,
    );
    expect(controller.operationErrorMessage.value, 'Not enough balance');
    verifyNever(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    );
  });

  test(
    'top-up failure preserves the wallet snapshot and exposes backend error',
    () async {
      final initial = _wallet();
      when(() => repository.getWallet()).thenAnswer((_) async => initial);
      when(
        () => repository.getWalletTransactions(page: 0, size: 20),
      ).thenAnswer((_) async => _page([]));
      when(
        () => repository.topUpWallet(
          amount: 5,
          note: null,
          currency: FinanceCurrency.usd,
        ),
      ).thenThrow(
        const AppError(
          message: 'Top-up rejected',
          errorCode: 'VALIDATION_ERROR',
          statusCode: 422,
        ),
      );

      controller.wallet.value = initial;
      expect(await controller.topUpWallet(amount: 5), isFalse);
      expect(controller.wallet.value, same(initial));
      expect(controller.operationErrorMessage.value, 'Top-up rejected');
    },
  );

  test('generic payment errors are preserved for the user', () async {
    when(
      () => repository.makePayment(
        amount: 5,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(
        message: 'Payment provider unavailable',
        errorCode: 'PAYMENT_DECLINED',
        statusCode: 422,
      ),
    );

    expect(
      await controller.makePayment(amount: 5, merchant: 'ShopABC · KHQR'),
      isFalse,
    );
    expect(
      controller.operationErrorMessage.value,
      'Payment provider unavailable',
    );
  });

  test('successful payment refreshes wallet and dashboard state', () async {
    var currentWallet = _wallet();
    when(() => repository.getWallet()).thenAnswer((_) async => currentWallet);
    when(
      () => repository.getWalletTransactions(page: 0, size: 20),
    ).thenAnswer((_) async => _page([]));
    when(
      () => repository.makePayment(
        amount: 3,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async {
      currentWallet = _wallet(usd: 17);
      return currentWallet;
    });
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard());

    expect(
      await controller.makePayment(amount: 3, merchant: 'ShopABC · KHQR'),
      isTrue,
    );
    expect(controller.wallet.value?.balanceUsd, 17);
    verify(() => repository.getWallet()).called(1);
    verify(() => repository.getWalletTransactions(page: 0, size: 20)).called(1);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).called(1);
  });

  test(
    'stale history response cannot overwrite a newly selected currency',
    () async {
      final stalePage =
          Completer<FinancePage<FinanceWalletTransactionEntity>>();
      final currentPage =
          Completer<FinancePage<FinanceWalletTransactionEntity>>();
      var calls = 0;
      when(() => repository.getWallet()).thenAnswer((_) async => _wallet());
      when(
        () => repository.getWalletTransactions(page: 0, size: 20),
      ).thenAnswer((_) => calls++ == 0 ? stalePage.future : currentPage.future);
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
      ).thenAnswer((_) async => _dashboard());

      final initial = controller.loadInitial();
      await Future<void>.delayed(Duration.zero);
      final changed = controller.selectCurrency(FinanceCurrency.khr);
      stalePage.complete(
        _page([_transaction(id: 'usd', currency: FinanceCurrency.usd)]),
      );
      await initial;
      expect(controller.transactions, isEmpty);

      currentPage.complete(
        _page([_transaction(id: 'khr', currency: FinanceCurrency.khr)]),
      );
      await changed;
      expect(controller.visibleTransactions.map((item) => item.transactionId), [
        'khr',
      ]);
    },
  );

  test(
    'stale wallet response cannot overwrite a newer balance snapshot',
    () async {
      final staleWallet = Completer<FinanceWalletEntity>();
      final currentWallet = Completer<FinanceWalletEntity>();
      var calls = 0;
      when(() => repository.getWallet()).thenAnswer(
        (_) => calls++ == 0 ? staleWallet.future : currentWallet.future,
      );

      final first = controller.loadWallet();
      final second = controller.loadWallet();
      currentWallet.complete(_wallet(usd: 18, khr: 90000));
      await second;
      staleWallet.complete(_wallet(usd: 99, khr: 999999));
      await first;

      expect(controller.wallet.value?.balanceUsd, 18);
      expect(controller.wallet.value?.balanceKhr, 90000);
    },
  );

  test('unknown transaction types map to a safe generic presentation', () {
    final data = walletTransactionData(
      _transaction(
        id: 'unknown',
        currency: FinanceCurrency.usd,
        type: 'FUTURE_TYPE',
      ),
      FinanceCurrency.usd,
      Colors.black,
    );

    expect(data.title, 'Wallet Transaction');
    expect(data.icon, Icons.account_balance_wallet_outlined);
  });

  test('double payment submission produces one backend request', () async {
    final response = Completer<FinanceWalletEntity>();
    stubInitial();
    when(
      () => repository.makePayment(
        amount: 2,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => response.future);
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard());

    final first = controller.makePayment(amount: 2, merchant: 'ShopABC · KHQR');
    await Future<void>.delayed(Duration.zero);
    final second = controller.makePayment(
      amount: 2,
      merchant: 'ShopABC · KHQR',
    );
    expect(await second, isFalse);
    response.complete(_wallet(usd: 18));
    expect(await first, isTrue);
    verify(
      () => repository.makePayment(
        amount: 2,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  testWidgets('payment failure never navigates to success', (tester) async {
    stubInitial();
    when(
      () => repository.makePayment(
        amount: 100,
        merchant: 'ShopABC · KHQR',
        note: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(
      const AppError(
        message: 'Not enough balance',
        errorCode: 'DEMO_WALLET_INSUFFICIENT_BALANCE',
        statusCode: 422,
      ),
    );
    Get.put<EWalletController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const PaymentProcessScreen(),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.ensureVisible(find.text('Confirm Payment'));
    await tester.tap(find.text('Confirm Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Successful!'), findsNothing);
    expect(find.text('Not enough balance'), findsOneWidget);
  });
}
