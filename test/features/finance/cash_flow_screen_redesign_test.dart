import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/cash_flow_feature/cash_flow_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/cash_flow_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceCashFlowEntity _mockCashFlow({
  FinanceCurrency currency = FinanceCurrency.usd,
  int month = 9,
  int year = 2026,
  double totalIncome = 1000000.0,
  double totalExpense = 100000.0,
  double net = 900000.0,
  double savingsRatePercent = 90.0,
}) {
  return FinanceCashFlowEntity(
    currency: currency,
    month: month,
    year: year,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    net: net,
    savingsRatePercent: savingsRatePercent,
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
  late CashFlowController cashFlowController;

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

    when(
      () => repository.getCashFlow(
        currency: any(named: 'currency'),
        month: any(named: 'month'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => _mockCashFlow());

    financeController = FinanceController(repository: repository);
    cashFlowController = CashFlowController(
      repository: repository,
      financeController: financeController,
    );

    Get.put<FinanceController>(financeController);
    Get.put<CashFlowController>(cashFlowController);
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
      home: const CashFlowScreen(),
    );
  }

  testWidgets(
    'renders redesigned CashFlowScreen with 2x2 grid, dual-bar chart, monthly details, and zero overflow',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('See how your money moves'), findsOneWidget);
      expect(find.text('Sep 2026'), findsOneWidget);

      // Currency Switcher
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('KHR'), findsOneWidget);

      // 2x2 Summary Metric Cards
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text(r'$1,000,000.00'), findsOneWidget);

      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text(r'$100,000.00'), findsOneWidget);

      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text(r'$900,000.00'), findsOneWidget);

      expect(find.text('Savings Rate'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);

      // Chart Card
      expect(find.text('Income vs Expenses'), findsOneWidget);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text(r'$1.0M'), findsOneWidget); // Floating badge

      // Scroll down to view Monthly Details
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Monthly Details Section
      expect(find.text('Monthly Details'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('1 transaction'), findsOneWidget);
      expect(find.text('5 transactions'), findsOneWidget);
      expect(find.text('Income - Expenses'), findsOneWidget);

      // Scroll further to view Smart Insight & Bottom Action Buttons
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Smart Insight
      expect(find.text('Smart Insight'), findsOneWidget);
      expect(
        find.text("You're saving 90% of your income this month. Great job! 🎉"),
        findsNothing,
      );

      // Bottom Action Buttons
      expect(find.text('View Income'), findsOneWidget);
      expect(find.text('View Expenses'), findsOneWidget);

      // Verify no RenderFlex errors occurred
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    r'handles massive balances ($999,900,000.00) without RenderFlex overflow',
    (tester) async {
      when(
        () => repository.getCashFlow(
          currency: any(named: 'currency'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer(
        (_) async => _mockCashFlow(
          totalIncome: 999900000.0,
          totalExpense: 123456789.0,
          net: 876443211.0,
          savingsRatePercent: 87.7,
        ),
      );

      await cashFlowController.load();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(r'$999,900,000.00'), findsOneWidget);
      expect(find.text(r'$123,456,789.00'), findsOneWidget);
      expect(find.text(r'$876,443,211.00'), findsOneWidget);
      expect(find.text('87.7%'), findsOneWidget);

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

      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Income vs Expenses'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('View Income'), findsOneWidget);
      expect(find.text('View Expenses'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders in Dark mode with proper semantic colors',
    (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text(r'$1,000,000.00'), findsOneWidget);
      expect(find.text('Income vs Expenses'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Smart Insight'), findsOneWidget);
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

      expect(find.text('លំហូរសាច់ប្រាក់'), findsOneWidget);
      expect(find.text('មើលពីរបៀបដែលលុយរបស់អ្នកផ្លាស់ទី'), findsOneWidget);
      expect(find.text('ចំណូលសរុប'), findsOneWidget);
      expect(find.text('ចំណាយសរុប'), findsOneWidget);
      expect(find.text('លំហូរសាច់ប្រាក់សុទ្ធ'), findsOneWidget);
      expect(find.text('អត្រាសន្សំ'), findsOneWidget);
      expect(find.text('ចំណូល ធៀបនឹង ចំណាយ'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('ព័ត៌មានលម្អិតប្រចាំខែ'), findsOneWidget);
      expect(find.text('មើលចំណូល'), findsOneWidget);
      expect(find.text('មើលចំណាយ'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opens month picker modal bottom sheet when calendar pill is tapped',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap the Sep 2026 header pill
      await tester.tap(find.text('Sep 2026'));
      await tester.pumpAndSettle();

      // Modal bottom sheet should show 12 months (Jan, Feb, Mar, etc.) and year
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Aug'), findsWidgets);
      expect(find.text('Dec'), findsOneWidget);

      // Tap 'Oct'
      await tester.tap(find.text('Oct'));
      await tester.pumpAndSettle();

      // Bottom sheet is dismissed
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(cashFlowController.selectedMonth.value, 10);
    },
  );
}
