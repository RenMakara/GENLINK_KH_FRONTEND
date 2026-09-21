import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/widgets/finance_widget.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceDashboardEntity _createMockDashboard({
  required FinanceCurrency currency,
  double balance = 999900000.00,
  double spent = 100000.00,
  double budget = 100000.00,
}) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 9,
      year: 2026,
      currency: currency,
      spent: spent,
      budgetTotal: budget,
      budgetRemaining: 0,
      budgetStatus: 'SAFE',
    ),
    topCategories: [
      FinanceCategorySpend(
        category: 'BILLS',
        currency: currency,
        amount: spent,
      ),
    ],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 1000.0,
      totalSaved: 100.0,
      progressPercent: 10,
      activeGoals: 1,
    ),
    recentExpenses: [
      FinanceRecentExpense(
        expenseId: 'exp-1',
        title: 'Buy new car 🚗',
        category: 'BILLS',
        currency: currency,
        amount: 100000.00,
        expenseDate: 'Sep 17, 2026',
      ),
      FinanceRecentExpense(
        expenseId: 'exp-2',
        title: 'Trade money',
        category: 'INCOME',
        currency: currency,
        amount: 1000000000.00,
        expenseDate: 'Sep 17, 2026',
      ),
    ],
    wallet: FinanceWalletSummary(
      balanceUsd: balance,
      balanceKhr: balance * 4000,
    ),
    financialTip: 'Pay yourself first: move money to savings before you spend.',
    quickActions: const [
      'ADD_EXPENSE',
      'SET_BUDGET',
      'NEW_SAVING_GOAL',
      'TOP_UP_WALLET',
    ],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController controller;

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();
    controller = FinanceController(repository: repository);
  });

  tearDown(Get.reset);

  testWidgets(
    'renders redesigned FinanceScreen with large amounts without overflow',
    (tester) async {
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.usd));
      controller.dashboard.value = _createMockDashboard(currency: FinanceCurrency.usd);
      Get.put<FinanceController>(controller);

      // Test standard phone size
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check large amount renders
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('KHR'), findsOneWidget);
      expect(find.byType(BalanceCard), findsOneWidget);
      expect(find.byType(DonutChart), findsOneWidget);
      expect(find.text('Buy new car 🚗'), findsOneWidget);
      expect(find.text('Trade money'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly on narrow screen (320px width) without overflow',
    (tester) async {
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.usd));
      controller.dashboard.value = _createMockDashboard(currency: FinanceCurrency.usd);
      Get.put<FinanceController>(controller);

      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly in Khmer language without overflow',
    (tester) async {
      when(
        () => repository.getFinanceDashboard(currency: any(named: 'currency')),
      ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.khr));
      controller.selectedCurrency.value = FinanceCurrency.khr;
      controller.dashboard.value = _createMockDashboard(currency: FinanceCurrency.khr);
      Get.put<FinanceController>(controller);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Get.clearTranslations();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('km', 'KH');

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Khmer translation strings
      expect(find.text('ហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(find.text('សមតុល្យសរុប'), findsOneWidget);
      expect(find.text('សមតុល្យដែលអាចប្រើបាន'), findsOneWidget);
      expect(find.text('សកម្មភាពរហ័ស'), findsOneWidget);
      expect(find.text('ការចំណាយប្រចាំខែ'), findsOneWidget);
      expect(find.text('ប្រាក់សន្សំ'), findsOneWidget);
      expect(find.text('ប្រតិបត្តិការថ្មីៗ'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'eye toggle on BalanceCard hides and reveals balance',
    (tester) async {
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.usd));
      controller.dashboard.value = _createMockDashboard(currency: FinanceCurrency.usd);
      Get.put<FinanceController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap eye icon to hide (blur balance)
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap eye icon to show again
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.text(r'$999,900,000.00'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping See All in Quick Actions opens all actions sheet',
    (tester) async {
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async => _createMockDashboard(currency: FinanceCurrency.usd));
      controller.dashboard.value = _createMockDashboard(currency: FinanceCurrency.usd);
      Get.put<FinanceController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first "See All" button for Quick Actions
      final seeAllButtons = find.text('See All');
      expect(seeAllButtons, findsAtLeastNWidgets(1));
      await tester.tap(seeAllButtons.first);
      await tester.pumpAndSettle();

      // Modal sheet opens with All Actions
      expect(find.text('All Actions'), findsOneWidget);
    },
  );
}
