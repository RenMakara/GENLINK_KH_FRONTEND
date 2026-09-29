import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_tools_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/finance_tools_feature/finance_tools_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  late _MockFinanceRepository repository;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 1);
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer(
      (_) async => FinanceDashboardEntity(
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
      ),
    );
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
    when(
      () => repository.getCashFlow(
        currency: FinanceCurrency.usd,
        month: previous.month,
        year: previous.year,
      ),
    ).thenAnswer(
      (_) async => FinanceCashFlowEntity(
        currency: FinanceCurrency.usd,
        month: previous.month,
        year: previous.year,
        totalIncome: 0,
        totalExpense: 0,
        net: 0,
        savingsRatePercent: 0,
      ),
    );
    when(
      () => repository.getRecurringTransactions(),
    ).thenAnswer((_) async => const []);
    when(() => repository.getAutoSaveRules()).thenAnswer((_) async => const []);
  });

  tearDown(Get.reset);

  Future<void> openScreen(WidgetTester tester, {bool dark = false}) async {
    final financeController = FinanceController(repository: repository);
    Get.put<FinanceController>(financeController);
    Get.put<FinanceToolsController>(
      FinanceToolsController(
        repository: repository,
        financeController: financeController,
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const FinanceToolsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('separates empty Auto Save state from a recurring API failure', (
    tester,
  ) async {
    when(() => repository.getRecurringTransactions()).thenThrow(
      const AppError(
        message: 'Recurring service unavailable',
        errorCode: 'API_ERROR',
        statusCode: 503,
      ),
    );
    when(() => repository.getAutoSaveRules()).thenAnswer((_) async => const []);
    await openScreen(tester);

    await tester.tap(find.text('Recurring').first);
    await tester.pumpAndSettle();
    expect(find.text('Recurring service unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Auto Save').first);
    await tester.pumpAndSettle();
    expect(find.text('No Auto Save rules yet.'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets(
    'shows the successful empty Insights state separately from errors',
    (tester) async {
      when(
        () => repository.getRecurringTransactions(),
      ).thenAnswer((_) async => const []);
      when(
        () => repository.getAutoSaveRules(),
      ).thenAnswer((_) async => const []);
      await openScreen(tester);

      expect(Get.find<FinanceController>().financeInsights.value, isNotNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('No finance activity for this period.'), findsOneWidget);
      expect(find.text('Recurring service unavailable'), findsNothing);
    },
  );

  testWidgets('renders API returned recurring and Auto Save history', (
    tester,
  ) async {
    when(() => repository.getRecurringTransactions()).thenAnswer(
      (_) async => const [
        FinanceRecurringTransactionEntity(
          id: 'recurring-netflix',
          type: FinanceRecurringType.expense,
          title: 'Streaming subscription',
          amount: 9.99,
          currency: FinanceCurrency.usd,
          category: 'Entertainment',
          frequency: FinanceRecurringFrequency.monthly,
          fromWallet: false,
          nextRunDate: '2026-10-01',
          lastRunDate: '2026-09-01',
          startDate: '2026-01-01',
          active: true,
        ),
      ],
    );
    when(() => repository.getAutoSaveRules()).thenAnswer(
      (_) async => const [
        FinanceAutoSaveRuleEntity(
          id: 'autosave-emergency',
          savingGoalId: 'goal-emergency',
          goalTitle: 'Emergency buffer',
          type: FinanceAutoSaveType.percentOfIncome,
          percent: 10,
          currency: FinanceCurrency.usd,
          nextRunDate: '2026-10-01',
          lastRunDate: '2026-09-01',
          active: true,
        ),
      ],
    );

    await openScreen(tester);
    await tester.tap(find.text('Recurring').first);
    await tester.pumpAndSettle();
    expect(find.text('Streaming subscription'), findsNWidgets(2));
    expect(find.text('Expense · Entertainment · Monthly'), findsNWidgets(2));
    expect(find.text('Next scheduled date: 2026-10-01'), findsNWidgets(2));
    expect(find.text('Last executed: 2026-09-01'), findsNWidgets(2));

    await tester.tap(find.text('Auto Save').first);
    await tester.pumpAndSettle();
    expect(find.text('Emergency buffer'), findsOneWidget);
    expect(find.text('Last executed: 2026-09-01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'recurring form validates locally and remains usable on a dark narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openScreen(tester, dark: true);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Recurring').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('finance_tools_add_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Create recurring transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      final createButton = find.widgetWithText(FilledButton, 'Create').last;
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      await tester.pumpAndSettle();
      expect(find.text('Enter a title up to 160 characters.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Rent');
      await tester.showKeyboard(titleField);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(createButton, findsOneWidget);
    },
  );

  testWidgets('Auto Save form uses live goals and validates its percent', (
    tester,
  ) async {
    when(
      () => repository.getSavingGoals(
        status: 'IN_PROGRESS',
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer(
      (_) async => const [
        FinanceSavingGoalEntity(
          savingGoalId: 'goal-emergency',
          title: 'Emergency buffer',
          targetAmount: 1000,
          currentAmount: 250,
          remainingAmount: 750,
          progressPercent: 25,
          status: 'IN_PROGRESS',
          currency: FinanceCurrency.usd,
        ),
      ],
    );

    await openScreen(tester);
    await tester.tap(find.text('Auto Save').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance_tools_add_button')));
    await tester.pumpAndSettle();

    final goalDropdown = find.byType(DropdownButtonFormField<String>);
    expect(goalDropdown, findsOneWidget);
    await tester.tap(goalDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emergency buffer').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Enter a percent from 0.01 to 100 with up to 2 decimal places.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelling recurring and auto save modals does not throw controller disposed errors',
    (tester) async {
      await openScreen(tester);
      await tester.tap(find.text('Recurring').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finance_tools_add_button')));
      await tester.pumpAndSettle();

      expect(find.text('Create recurring transaction'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Gym Membership');
      await tester.pumpAndSettle();

      // Tap Cancel button to dismiss bottom sheet
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create recurring transaction'), findsNothing);
      expect(tester.takeException(), isNull);

      // Switch to Auto Save and test opening & closing
      await tester.tap(find.text('Auto Save').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finance_tools_add_button')));
      await tester.pumpAndSettle();

      // When modal is open, title appears in modal header and in dashed action card
      expect(find.text('Create Auto Save rule'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Auto Save rule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping insight card opens detail modal with full message and action button',
    (tester) async {
      final now = DateTime.now();
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
          income: 3000,
          expense: 0,
          net: 3000,
          savingsRatePercent: 100,
          insights: const [
            FinanceInsightEntity(
              type: 'SAVINGS',
              severity: 'POSITIVE',
              title: 'Great savings this month',
              message:
                  'You kept 100% of your income. Once you have an emergency fund, consider setting up a saving goal.',
            ),
          ],
        ),
      );

      await openScreen(tester);

      expect(find.text('Great savings this month'), findsOneWidget);
      // Tap on the insight card
      await tester.tap(find.text('Great savings this month'));
      await tester.pumpAndSettle();

      // Verify the detail modal opened with the message and action button
      expect(
        find.text(
          'You kept 100% of your income. Once you have an emergency fund, consider setting up a saving goal.',
        ),
        findsNWidgets(2),
      );
      expect(find.text('Save Goal'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
