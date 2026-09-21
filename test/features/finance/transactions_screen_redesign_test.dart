import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_transaction.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceWalletTransactionEntity _mockTx({
  required String id,
  required String type,
  required String direction,
  required double amount,
  String? description,
  String? createdAt,
  String status = 'SUCCESS',
  FinanceCurrency currency = FinanceCurrency.usd,
}) {
  return FinanceWalletTransactionEntity(
    transactionId: id,
    transactionType: type,
    direction: direction,
    currency: currency,
    amount: amount,
    description: description,
    status: status,
    createdAt: createdAt,
  );
}

FinanceWalletEntity _mockWallet() {
  return const FinanceWalletEntity(
    walletId: 'w-1',
    balanceUsd: 1000000.0,
    balanceKhr: 4100000000.0,
  );
}

FinancePage<FinanceWalletTransactionEntity> _mockPage(
  List<FinanceWalletTransactionEntity> items,
) {
  return FinancePage(
    content: items,
    page: 0,
    size: 20,
    totalElements: items.length,
    totalPages: 1,
    hasNext: false,
  );
}

FinanceDashboardEntity _mockDashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: 100000.0,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 500000.0,
      totalSaved: 450000.0,
      progressPercent: 90,
      activeGoals: 3,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late EWalletController ewalletController;

  final sampleTransactions = [
    _mockTx(
      id: 'tx-1',
      type: 'INCOME',
      direction: 'CREDIT',
      amount: 1000000000.0,
      description: 'Income: Trade money',
      createdAt: '2026-09-17T14:30:00.000Z',
    ),
    _mockTx(
      id: 'tx-2',
      type: 'EXPENSE',
      direction: 'DEBIT',
      amount: 100000.0,
      description: 'Expense: Buy new car',
      createdAt: '2026-09-17T10:15:00.000Z',
    ),
    _mockTx(
      id: 'tx-3',
      type: 'DEPOSIT',
      direction: 'CREDIT',
      amount: 50.0,
      description: 'Bank: Top up from bank',
      createdAt: '2026-09-17T09:20:00.000Z',
    ),
    _mockTx(
      id: 'tx-4',
      type: 'EXPENSE',
      direction: 'DEBIT',
      amount: 25.0,
      description: 'Utilities: Pay electricity bill',
      createdAt: '2026-09-16T18:45:00.000Z',
    ),
    _mockTx(
      id: 'tx-5',
      type: 'EXPENSE',
      direction: 'DEBIT',
      amount: 9.99,
      description: 'Entertainment: Spotify Premium',
      createdAt: '2026-09-16T12:10:00.000Z',
    ),
    _mockTx(
      id: 'tx-6',
      type: 'INCOME',
      direction: 'CREDIT',
      amount: 3000.0,
      description: 'Business: Freelance payment',
      createdAt: '2026-09-15T16:00:00.000Z',
    ),
    _mockTx(
      id: 'tx-7',
      type: 'EXPENSE',
      direction: 'DEBIT',
      amount: 12.50,
      description: 'Food: Lunch at cafe',
      createdAt: '2026-09-15T12:30:00.000Z',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    repository = _MockFinanceRepository();
    when(
      () => repository.getFinanceDashboard(currency: any(named: 'currency')),
    ).thenAnswer((_) async => _mockDashboard(FinanceCurrency.usd));

    when(() => repository.getWallet()).thenAnswer((_) async => _mockWallet());

    when(
      () => repository.getWalletTransactions(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => _mockPage(sampleTransactions));

    financeController = FinanceController(repository: repository);
    ewalletController = EWalletController(repository, financeController);

    Get.put<FinanceController>(financeController);
    Get.put<EWalletController>(ewalletController);
  });

  tearDown(Get.reset);

  Widget buildTestApp({
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en', 'US'),
  }) {
    final isDark = brightness == Brightness.dark;
    Get.locale = locale;
    return GetMaterialApp(
      locale: locale,
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      ),
      home: const TransactionsScreen(),
    );
  }

  Finder mainScrollable() => find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      );

  testWidgets(
    'renders redesigned TransactionsScreen with header, search, filters, summary, and date groups',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('All your financial activity'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Search & Filter
      expect(find.text('Search transactions...'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Filter Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expense'), findsWidgets);
      expect(find.text('Transfer'), findsOneWidget);

      // Summary Cards
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);

      // Date Group 1 (Sep 17, 2026)
      expect(find.text('Sep 17, 2026'), findsOneWidget);
      expect(find.text('Trade money'), findsOneWidget);
      expect(find.text('Buy new car'), findsOneWidget);
      expect(find.text('Top up from bank'), findsOneWidget);

      // Scroll down to check remaining groups & motivation card
      await tester.drag(mainScrollable(), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Sep 16, 2026'), findsOneWidget);
      expect(find.text('Pay electricity bill'), findsOneWidget);
      expect(find.text('Spotify Premium'), findsOneWidget);

      await tester.drag(mainScrollable(), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Sep 15, 2026'), findsOneWidget);
      expect(find.text('Freelance payment'), findsOneWidget);
      expect(find.text('Lunch at cafe'), findsOneWidget);

      expect(find.text('Keep tracking!'), findsOneWidget);
      expect(
        find.text("You're doing great at managing your money."),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filters transactions dynamically using search query',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Both Trade money and Buy new car are visible initially
      expect(find.text('Trade money'), findsOneWidget);
      expect(find.text('Buy new car'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Spotify');
      await tester.pumpAndSettle();

      // Only Spotify Premium should appear
      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.text('Trade money'), findsNothing);
      expect(find.text('Buy new car'), findsNothing);

      // Clear search query
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Trade money'), findsOneWidget);
    },
  );

  testWidgets(
    'filters transactions by filter chip (Income, Expense, Transfer)',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap 'Income' filter chip
      await tester.tap(find.text('Income').first);
      await tester.pumpAndSettle();

      // Should show Trade money (credit/income) and not Buy new car (debit/expense)
      expect(find.text('Trade money'), findsOneWidget);
      expect(find.text('Buy new car'), findsNothing);

      // Tap 'Expense' filter chip
      await tester.tap(find.text('Expense').first);
      await tester.pumpAndSettle();

      expect(find.text('Buy new car'), findsOneWidget);
      expect(find.text('Trade money'), findsNothing);
    },
  );

  testWidgets(
    r'handles massive balances ($999,900,000,000.00) without RenderFlex overflow',
    (tester) async {
      final hugeList = [
        _mockTx(
          id: 'huge-1',
          type: 'INCOME',
          direction: 'CREDIT',
          amount: 999900000000.0,
          description: 'Mega Unicorn Exit',
          createdAt: '2026-09-17T12:00:00.000Z',
        ),
      ];

      when(
        () => repository.getWalletTransactions(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _mockPage(hugeList));

      await ewalletController.loadInitial();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(r'+$999,900,000,000.00'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly on narrow 320px screen width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 3.0, 700 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Trade money'), findsOneWidget);

      await tester.drag(mainScrollable(), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Keep tracking!'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders in Dark mode with proper semantic colors',
    (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Trade money'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders with Khmer locale (km_KH) cleanly',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(locale: const Locale('km', 'KH')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ប្រតិបត្តិការ'), findsOneWidget);
      expect(find.text('សកម្មភាពហិរញ្ញវត្ថុរបស់អ្នកទាំងអស់'), findsOneWidget);
      expect(find.text('ទាំងអស់'), findsOneWidget);
      expect(find.text('ចំណូលសរុប'), findsOneWidget);
      expect(find.text('ចំណាយសរុប'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping transaction item opens transaction details modal bottom sheet',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap on Trade money item
      await tester.tap(find.text('Trade money'));
      await tester.pumpAndSettle();

      // Details bottom sheet should be visible
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('SUCCESS'), findsOneWidget);
      expect(find.text(r'+$1,000,000,000.00'), findsWidgets);
    },
  );

  testWidgets(
    'tapping add button opens action sheet with options',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap the + button in header
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Add options should appear
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expense'), findsWidgets);
    },
  );
}
