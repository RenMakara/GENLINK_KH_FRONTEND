import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_transaction.dart';
import 'package:genlink_frontend/features/finance/widgets/finance_widget.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceDashboardEntity _createMockDashboard({
  required FinanceCurrency currency,
}) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: 50.0,
      budgetTotal: 200.0,
      budgetRemaining: 150.0,
      budgetStatus: 'SAFE',
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 1000.0,
      totalSaved: 100.0,
      progressPercent: 10,
      activeGoals: 1,
    ),
    recentExpenses: const [],
    wallet: const FinanceWalletSummary(balanceUsd: 1000, balanceKhr: 4000000),
    financialTip: 'Track your spending.',
    quickActions: const ['ADD_EXPENSE'],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late EWalletController walletController;

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();

    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.usd));

    when(
      () => repository.getWallet(),
    ).thenAnswer((_) async => const FinanceWalletEntity(
          walletId: 'w1',
          balanceUsd: 500,
          balanceKhr: 2000000,
        ));

    when(
      () => repository.getWalletTransactions(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const FinancePage<FinanceWalletTransactionEntity>(
          content: [],
          page: 0,
          size: 20,
          totalElements: 0,
          totalPages: 0,
          hasNext: false,
        ));

    financeController = FinanceController(repository: repository);
    financeController.dashboard.value =
        _createMockDashboard(currency: FinanceCurrency.usd);
    Get.put<FinanceController>(financeController);

    walletController = EWalletController(repository, financeController);
    Get.put<EWalletController>(walletController);
  });

  tearDown(Get.reset);

  testWidgets(
    'Recent Transactions shows both income and outcome transactions, limited to 5',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Populate 7 transactions (mix of CREDIT/income and DEBIT/outcome)
      walletController.transactions.assignAll([
        const FinanceWalletTransactionEntity(
          transactionId: 't1',
          transactionType: 'INCOME',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 500.00,
          description: 'Income: Monthly Freelance',
          status: 'SUCCESS',
          createdAt: '2026-09-28T10:00:00.000Z',
        ),
        const FinanceWalletTransactionEntity(
          transactionId: 't2',
          transactionType: 'EXPENSE',
          direction: 'DEBIT',
          currency: FinanceCurrency.usd,
          amount: 35.50,
          description: 'Expense: Grocery Market',
          status: 'SUCCESS',
          createdAt: '2026-09-27T12:00:00.000Z',
        ),
        const FinanceWalletTransactionEntity(
          transactionId: 't3',
          transactionType: 'DEPOSIT',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 100.00,
          description: 'Top-up from ABA Bank',
          status: 'SUCCESS',
          createdAt: '2026-09-26T08:00:00.000Z',
        ),
        const FinanceWalletTransactionEntity(
          transactionId: 't4',
          transactionType: 'KHQR_PAYMENT',
          direction: 'DEBIT',
          currency: FinanceCurrency.usd,
          amount: 12.00,
          description: 'Coffee Shop KHQR',
          status: 'SUCCESS',
          createdAt: '2026-09-25T09:30:00.000Z',
        ),
        const FinanceWalletTransactionEntity(
          transactionId: 't5',
          transactionType: 'REWARD',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 5.00,
          description: 'Quiz Level-up Bonus',
          status: 'SUCCESS',
          createdAt: '2026-09-24T14:15:00.000Z',
        ),
        // 6th and 7th transaction - should be excluded by the 5-item limit
        const FinanceWalletTransactionEntity(
          transactionId: 't6',
          transactionType: 'EXPENSE',
          direction: 'DEBIT',
          currency: FinanceCurrency.usd,
          amount: 88.00,
          description: 'Expense: Electric Bill 6th',
          status: 'SUCCESS',
          createdAt: '2026-09-23T10:00:00.000Z',
        ),
        const FinanceWalletTransactionEntity(
          transactionId: 't7',
          transactionType: 'INCOME',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 200.00,
          description: 'Income: 7th Item',
          status: 'SUCCESS',
          createdAt: '2026-09-22T10:00:00.000Z',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Recent Transactions
      final recentSectionFinder = find.text('Recent Transactions');
      await tester.scrollUntilVisible(
        recentSectionFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(recentSectionFinder, findsOneWidget);

      // Verify first 5 items are displayed with stripped prefix / proper title
      expect(find.text('Monthly Freelance'), findsOneWidget);
      expect(find.text(r'+$500.00'), findsOneWidget);

      expect(find.text('Grocery Market'), findsOneWidget);
      expect(find.text(r'-$35.50'), findsOneWidget);

      expect(find.text('Top-up from ABA Bank'), findsOneWidget);
      expect(find.text(r'+$100.00'), findsOneWidget);

      expect(find.text('Coffee Shop KHQR'), findsOneWidget);
      expect(find.text(r'-$12.00'), findsOneWidget);

      expect(find.text('Quiz Level-up Bonus'), findsOneWidget);
      expect(find.text(r'+$5.00'), findsOneWidget);

      // Verify 6th and 7th items are NOT shown
      expect(find.text('Electric Bill 6th'), findsNothing);
      expect(find.text('7th Item'), findsNothing);

      // Exactly 5 Transaction widgets rendered in Recent Transactions
      expect(find.byType(Transaction), findsNWidgets(5));
    },
  );

  testWidgets(
    'Tapping See All in Recent Transactions navigates to TransactionsScreen',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      walletController.transactions.assignAll([
        const FinanceWalletTransactionEntity(
          transactionId: 't1',
          transactionType: 'INCOME',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 50.00,
          description: 'Income: Bonus',
          status: 'SUCCESS',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final seeAllFinder = find.byKey(const ValueKey('recent_transactions_see_all'));
      await tester.scrollUntilVisible(
        seeAllFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(seeAllFinder);
      await tester.pumpAndSettle();
      expect(seeAllFinder, findsOneWidget);

      await tester.tap(seeAllFinder);
      await tester.pumpAndSettle();

      // Verified redirect to TransactionsScreen
      expect(find.byType(TransactionsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping a transaction row in Recent Transactions opens transaction detail bottom sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      walletController.transactions.assignAll([
        const FinanceWalletTransactionEntity(
          transactionId: 't1',
          transactionType: 'INCOME',
          direction: 'CREDIT',
          currency: FinanceCurrency.usd,
          amount: 25.00,
          description: 'Income: Cashback',
          status: 'SUCCESS',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinder = find.text('Cashback');
      await tester.scrollUntilVisible(
        itemFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(itemFinder);
      await tester.pumpAndSettle();
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Verified transaction detail bottom sheet is displayed
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('SUCCESS'), findsOneWidget);
      expect(find.text(r'+$25.00'), findsWidgets);
      expect(find.text('Income: Cashback'), findsOneWidget);
    },
  );

  testWidgets(
    'Shows empty state when no transactions exist',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      walletController.transactions.clear();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final emptyStateFinder = find.text('No recent transactions');
      await tester.scrollUntilVisible(
        emptyStateFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(emptyStateFinder, findsOneWidget);
    },
  );
}
