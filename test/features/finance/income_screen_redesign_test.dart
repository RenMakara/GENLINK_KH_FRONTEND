import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceIncomeEntity _mockIncome({
  String id = 'inc-1',
  String title = 'Trade money',
  double amount = 1000000.0,
  String source = 'Business',
  String date = '2026-09-17',
  FinanceCurrency currency = FinanceCurrency.usd,
}) {
  return FinanceIncomeEntity(
    incomeId: id,
    title: title,
    amount: amount,
    currency: currency,
    source: source,
    incomeDate: date,
  );
}

FinancePage<FinanceIncomeEntity> _mockPage(List<FinanceIncomeEntity> items) {
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
      spent: 50.0,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 5000.0,
      totalSaved: 1250.0,
      progressPercent: 25,
      activeGoals: 4,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late IncomeController incomeController;

  final sampleIncomes = [
    _mockIncome(
      id: 'i-1',
      title: 'Trade money',
      amount: 1000000.0,
      source: 'Business',
      date: '2026-09-17',
    ),
    _mockIncome(
      id: 'i-2',
      title: 'Salary from company',
      amount: 800000.0,
      source: 'Salary',
      date: '2026-09-01',
    ),
    _mockIncome(
      id: 'i-3',
      title: 'Birthday gift',
      amount: 30000.0,
      source: 'Gift',
      date: '2026-08-28',
    ),
    _mockIncome(
      id: 'i-4',
      title: 'Refund',
      amount: 20000.0,
      source: 'Others',
      date: '2026-08-20',
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

    when(
      () => repository.getIncomes(
        source: any(named: 'source'),
        currency: any(named: 'currency'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => _mockPage(sampleIncomes));

    financeController = FinanceController(repository: repository);
    incomeController = IncomeController(
      repository: repository,
      financeController: financeController,
    );

    Get.put<FinanceController>(financeController);
    Get.put<IncomeController>(incomeController);
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
        scaffoldBackgroundColor: isDark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
      ),
      home: const IncomeScreen(),
    );
  }

  testWidgets(
    'renders redesigned IncomeScreen with Hero card, 6-bar chart, sources, and zero overflow',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Top Bar
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Track and manage your income'), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets);

      // Currency Pill
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('KHR'), findsOneWidget);

      // Period / Month Selector
      expect(find.text('September 2026'), findsOneWidget);

      // Hero Total Income Card
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text(r'$1,850,000.00'), findsOneWidget);
      expect(find.text('+16% from last month'), findsNothing);
      expect(find.text(r'$1.9M'), findsOneWidget); // Mini chart badge

      // Income by Source Section
      expect(find.text('Income by Source'), findsOneWidget);
      expect(find.text('Business'), findsWidgets);
      expect(find.text('Salary'), findsWidgets);
      expect(find.text('Gift'), findsWidgets);

      // Recent Income Section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Recent Income'), findsOneWidget);
      expect(find.text('Trade money'), findsOneWidget);
      expect(find.text('Salary from company'), findsOneWidget);

      // Smart Insight Card
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Smart Insight'), findsOneWidget);

      // Sticky Bottom Add Income CTA
      expect(find.text('Add Income'), findsWidgets);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    r'handles massive income balances ($999,900,000.00) without RenderFlex overflow',
    (tester) async {
      final hugeIncomes = [
        _mockIncome(
          id: 'huge-1',
          title: 'Unicorn Tech Exit',
          amount: 999900000.0,
          source: 'Business',
        ),
      ];

      when(
        () => repository.getIncomes(
          source: any(named: 'source'),
          currency: any(named: 'currency'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _mockPage(hugeIncomes));

      await incomeController.loadInitial();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(r'$999,900,000.00'), findsWidgets);
      expect(find.text(r'$999.9M'), findsOneWidget);
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

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders in Dark mode with proper semantic colors',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
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

      expect(find.text('ចំណូល'), findsOneWidget);
      expect(find.text('តាមដាន និងគ្រប់គ្រងចំណូលរបស់អ្នក'), findsOneWidget);
      expect(find.text('ចំណូលសរុប'), findsOneWidget);
      expect(find.text('ចំណូលតាមប្រភព'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping source card filters by that source',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final businessTile = find.text('Business').first;
      await tester.tap(businessTile);
      await tester.pumpAndSettle();

      expect(incomeController.selectedSource.value, 'Business');
      expect(find.text('Filtered by: Business'), findsOneWidget);
    },
  );
}
