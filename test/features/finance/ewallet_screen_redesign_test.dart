import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceWalletEntity _mockWallet({
  double usd = 999900000.00,
  double khr = 4000000000000.00,
}) {
  return FinanceWalletEntity(
    walletId: 'wallet-001',
    balanceUsd: usd,
    balanceKhr: khr,
  );
}

FinanceWalletTransactionEntity _mockTransaction({
  required String id,
  required String type,
  required String direction,
  required double amount,
  required String description,
  required String createdAt,
  FinanceCurrency currency = FinanceCurrency.usd,
}) {
  return FinanceWalletTransactionEntity(
    transactionId: id,
    transactionType: type,
    direction: direction,
    currency: currency,
    amount: amount,
    description: description,
    status: 'SUCCESS',
    createdAt: createdAt,
  );
}

FinanceDashboardEntity _mockDashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: 100000.00,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 1000000.0,
      totalSaved: 500000.0,
      progressPercent: 50,
      activeGoals: 2,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late EWalletController ewalletController;

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

    when(() => repository.getWallet()).thenAnswer(
      (_) async => _mockWallet(),
    );

    when(
      () => repository.getWalletTransactions(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => FinancePage<FinanceWalletTransactionEntity>(
        content: [
          _mockTransaction(
            id: 'tx-1',
            type: 'EXPENSE',
            direction: 'DEBIT',
            amount: 100000.00,
            description: 'Buy new car',
            createdAt: '2026-09-17T14:30:00Z',
          ),
          _mockTransaction(
            id: 'tx-2',
            type: 'INCOME',
            direction: 'CREDIT',
            amount: 1000000000.00,
            description: 'Trade money',
            createdAt: '2026-09-17T10:20:00Z',
          ),
          _mockTransaction(
            id: 'tx-3',
            type: 'DEPOSIT',
            direction: 'CREDIT',
            amount: 50.00,
            description: 'Top up from bank',
            createdAt: '2026-09-16T09:15:00Z',
          ),
          _mockTransaction(
            id: 'tx-4',
            type: 'EXPENSE',
            direction: 'DEBIT',
            amount: 25.00,
            description: 'Pay electricity bill',
            createdAt: '2026-09-15T18:45:00Z',
          ),
          _mockTransaction(
            id: 'tx-5',
            type: 'EXPENSE',
            direction: 'DEBIT',
            amount: 10.00,
            description: 'Send to friend',
            createdAt: '2026-09-14T12:10:00Z',
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 5,
        totalPages: 1,
        hasNext: false,
      ),
    );

    financeController = FinanceController(repository: repository);
    ewalletController = EWalletController(repository, financeController);

    Get.put<FinanceController>(financeController);
    Get.put<EWalletController>(ewalletController);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    return GetMaterialApp(
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: isDark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
      ),
      home: const EWalletScreen(),
    );
  }

  testWidgets(
    r'renders redesigned EWalletScreen with large balance ($999,900,000.00) without overflow',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Top Bar Header
      expect(find.text('E-Wallet'), findsOneWidget);
      expect(find.text('Manage your wallet, fast and secure'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // Hero Wallet Card
      expect(find.text('Demo Wallet'), findsWidgets);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('KHR'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text(r'$999,900,000.00'), findsOneWidget);

      // Primary Actions Row
      expect(find.text('Pay'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Top Up'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Quick Actions Section
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Card'), findsOneWidget);
      expect(find.text('Request Money'), findsOneWidget);
      expect(find.text('Transfer to Bank'), findsOneWidget);
      expect(find.text('Bill Payment'), findsOneWidget);

      // Summary Metrics Row
      expect(find.text('Total Incoming'), findsOneWidget);
      expect(find.text('Total Spending'), findsOneWidget);

      // Recent Transactions
      final recentFinder = find.text('Recent Transactions');
      await tester.scrollUntilVisible(recentFinder, 200);
      expect(recentFinder, findsOneWidget);
      expect(find.text('See All'), findsWidgets);
      expect(find.textContaining('Buy new car'), findsOneWidget);
      expect(find.textContaining('Trade money'), findsOneWidget);

      // Demo Wallet Notice
      final noticeFinder = find.byIcon(Icons.info_outline_rounded);
      await tester.scrollUntilVisible(noticeFinder, 200);
      expect(noticeFinder, findsOneWidget);
      expect(find.text('Wallet Security'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'eye toggle on E-Wallet card hides and reveals balance',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initially balance is visible without blur
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);

      // Tap eye icon to hide balance (blur balance)
      final eyeButton = find.byIcon(Icons.visibility_outlined);
      expect(eyeButton, findsOneWidget);
      await tester.tap(eyeButton);
      await tester.pumpAndSettle();

      // Balance is now blurred
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap eye icon again to reveal balance
      final eyeOffButton = find.byIcon(Icons.visibility_off_outlined);
      expect(eyeOffButton, findsOneWidget);
      await tester.tap(eyeOffButton);
      await tester.pumpAndSettle();

      // Balance is restored without blur
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'renders properly in dark mode with semantic colors',
    (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('E-Wallet'), findsOneWidget);
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      final recentFinder = find.text('Recent Transactions');
      await tester.scrollUntilVisible(recentFinder, 200);
      expect(recentFinder, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders properly in Khmer locale with zero overflow',
    (tester) async {
      Get.locale = const Locale('km', 'KH');

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Khmer Title
      expect(find.text('កាបូបលុយឌីជីថល'), findsOneWidget);
      // Khmer Primary Badge
      expect(find.text('ចម្បង'), findsOneWidget);
      // Khmer Quick Actions
      expect(find.text('សកម្មភាពរហ័ស'), findsOneWidget);
      // Khmer Recent Transactions
      final recentKhmer = find.text('ប្រតិបត្តិការថ្មីៗ');
      await tester.scrollUntilVisible(recentKhmer, 200);
      expect(recentKhmer, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'supports narrow small screen (320px width) with zero overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 700 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('E-Wallet'), findsOneWidget);
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping more menu opens options modal bottom sheet',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_horiz_rounded);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('History'), findsWidgets);
      expect(find.text('Wallet Security'), findsWidgets);
    },
  );

  testWidgets(
    'tapping quick action card triggers feedback without error',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final addCard = find.text('Add Card');
      expect(addCard, findsOneWidget);
      await tester.tap(addCard);
      await tester.pumpAndSettle();

      expect(find.text('This feature is coming soon.'), findsOneWidget);
    },
  );
}
