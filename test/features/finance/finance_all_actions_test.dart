import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_tools_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/finance_tools_feature/finance_tools_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController controller;

  final now = DateTime.now();
  final mockDashboard = FinanceDashboardEntity(
    currency: FinanceCurrency.usd,
    month: FinanceMonthOverview(
      month: now.month,
      year: now.year,
      currency: FinanceCurrency.usd,
      spent: 0,
    ),
    topCategories: const [],
    saving: const FinanceSavingProgress(
      currency: FinanceCurrency.usd,
      totalTarget: 0,
      totalSaved: 0,
      progressPercent: 0,
      activeGoals: 0,
    ),
    recentExpenses: const [],
    wallet: const FinanceWalletSummary(balanceUsd: 42.5, balanceKhr: 900000),
    financialTip: 'Track every expense.',
    quickActions: const [
      'ADD_EXPENSE',
      'SET_BUDGET',
      'NEW_SAVING_GOAL',
      'TOP_UP_WALLET',
    ],
  );

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();
    controller = FinanceController(repository: repository);
    Get.put<FinanceController>(controller);
    Get.put<FinanceToolsController>(
      FinanceToolsController(
        repository: repository,
        financeController: controller,
      ),
    );

    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => mockDashboard);
    when(
      () => repository.getFinanceInsights(
        currency: FinanceCurrency.usd,
        month: now.month,
        year: now.year,
      ),
    ).thenAnswer(
      (_) async => FinanceInsightsEntity(
        currency: FinanceCurrency.usd,
        month: now.month,
        year: now.year,
        income: 0,
        expense: 0,
        net: 0,
        savingsRatePercent: 0,
        insights: const [],
      ),
    );
    when(() => repository.getRecurringTransactions())
        .thenAnswer((_) async => const []);
    when(() => repository.getAutoSaveRules()).thenAnswer((_) async => const []);
  });

  tearDown(Get.reset);

  testWidgets(
    'All Actions sheet renders 3 boxes per row including Smart Insight and Finance tools',
    (tester) async {
      controller.dashboard.value = mockDashboard;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const FinanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open "All Actions" bottom sheet
      expect(find.text('See All'), findsWidgets);
      await tester.tap(find.text('See All').first);
      await tester.pumpAndSettle();

      // Verify All Actions title
      expect(find.text('All Actions'), findsOneWidget);

      // Verify Smart Insight is present in All Actions (and on dashboard card)
      expect(find.text('Smart Insight'), findsNWidgets(2));
      expect(find.text('Finance tools'), findsOneWidget);
      expect(find.text('Expense'), findsNWidgets(2));
      expect(find.text('Budget'), findsNWidgets(2));
      expect(find.text('Save Goal'), findsAtLeastNWidgets(2));
      expect(find.text('E-Wallet'), findsNWidgets(2));
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Learn'), findsNWidgets(2));

      // Tap on Smart Insight in the modal to verify navigation
      await tester.tap(find.text('Smart Insight').last);
      await tester.pumpAndSettle();

      // FinanceToolsScreen opens
      expect(find.byType(FinanceToolsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
