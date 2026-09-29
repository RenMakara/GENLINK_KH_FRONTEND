import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceDashboardEntity _dashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 8,
      year: 2026,
      currency: currency,
      spent: currency == FinanceCurrency.usd ? 12.5 : 120000,
      budgetTotal: currency == FinanceCurrency.usd ? 100 : 500000,
      budgetRemaining: currency == FinanceCurrency.usd ? 87.5 : 380000,
      budgetStatus: 'SAFE',
    ),
    topCategories: [
      FinanceCategorySpend(
        category: 'FOOD',
        currency: currency,
        amount: currency == FinanceCurrency.usd ? 12.5 : 120000,
      ),
    ],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: currency == FinanceCurrency.usd ? 100 : 1000000,
      totalSaved: currency == FinanceCurrency.usd ? 25 : 250000,
      progressPercent: 25,
      activeGoals: 1,
    ),
    recentExpenses: [
      FinanceRecentExpense(
        expenseId: 'expense-1',
        title: 'Lunch',
        category: 'FOOD',
        currency: currency,
        amount: currency == FinanceCurrency.usd ? 12.5 : 120000,
        expenseDate: '2026-08-20',
      ),
    ],
    wallet: const FinanceWalletSummary(balanceUsd: 42.5, balanceKhr: 900000),
    financialTip: 'Track every expense.',
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

  setUp(() {
    repository = _MockFinanceRepository();
    controller = FinanceController(repository: repository);
  });

  tearDown(Get.reset);

  test('currency switching requests KHR after USD', () async {
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.khr));

    await controller.loadDashboard();
    await controller.selectCurrency(FinanceCurrency.khr);

    expect(controller.selectedCurrency.value, FinanceCurrency.khr);
    expect(controller.dashboard.value?.currency, FinanceCurrency.khr);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).called(1);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).called(1);
  });

  test('currency switching requests USD after KHR', () async {
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.khr));
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));

    await controller.loadDashboard(currency: FinanceCurrency.khr);
    await controller.selectCurrency(FinanceCurrency.usd);

    expect(controller.selectedCurrency.value, FinanceCurrency.usd);
    expect(controller.dashboard.value?.currency, FinanceCurrency.usd);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).called(1);
    verify(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).called(1);
  });

  test(
    'a stale USD response cannot overwrite an in-flight KHR request',
    () async {
      final usd = Completer<FinanceDashboardEntity>();
      final khr = Completer<FinanceDashboardEntity>();
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) => usd.future);
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
      ).thenAnswer((_) => khr.future);

      final usdRequest = controller.loadDashboard();
      final khrRequest = controller.selectCurrency(FinanceCurrency.khr);
      usd.complete(_dashboard(FinanceCurrency.usd));
      await usdRequest;

      expect(controller.dashboard.value, isNull);
      expect(controller.selectedCurrency.value, FinanceCurrency.khr);
      expect(controller.isLoading.value, isTrue);

      khr.complete(_dashboard(FinanceCurrency.khr));
      await khrRequest;

      expect(controller.dashboard.value?.currency, FinanceCurrency.khr);
      expect(controller.isLoading.value, isFalse);
    },
  );

  test('dashboard currency mismatch becomes a safe error state', () async {
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.khr),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));

    await controller.loadDashboard(currency: FinanceCurrency.khr);

    expect(controller.dashboard.value, isNull);
    expect(controller.errorMessage.value, 'common.error'.tr);
    expect(controller.isLoading.value, isFalse);
  });

  test(
    'reload retries a failed dashboard request in the selected currency',
    () async {
      var calls = 0;
      when(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const AppError(
            message: 'Temporary failure',
            errorCode: 'NETWORK_ERROR',
          );
        }
        return _dashboard(FinanceCurrency.usd);
      });

      await controller.loadDashboard();
      expect(controller.dashboard.value, isNull);
      expect(controller.errorMessage.value, 'Temporary failure');

      await controller.reload();
      expect(controller.dashboard.value?.currency, FinanceCurrency.usd);
      expect(controller.errorMessage.value, isNull);
      expect(calls, 2);
    },
  );

  testWidgets('renders API-backed dashboard values and currency selector', (
    tester,
  ) async {
    when(
      () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
    ).thenAnswer((_) async => _dashboard(FinanceCurrency.usd));
    controller.dashboard.value = _dashboard(FinanceCurrency.usd);
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

    expect(find.text(r'$42.50'), findsOneWidget);
    expect(find.text(r'$12.50'), findsAtLeastNWidgets(1));
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('KHR'), findsOneWidget);
    expect(find.text('Track every expense.'), findsNothing);
  });

  testWidgets('renders loading and error retry states', (tester) async {
    Get.put<FinanceController>(controller);
    controller.isLoading.value = true;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const FinanceScreen(),
      ),
    );
    expect(find.text('Loading finance dashboard…'), findsOneWidget);

    controller.isLoading.value = false;
    controller.errorMessage.value = 'Unable to reach the server.';
    await tester.pump();
    expect(find.text('Unable to reach the server.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  test('formats USD and KHR without conversion', () {
    expect(
      FinanceMoneyFormatter.format(1250.5, FinanceCurrency.usd),
      r'$1,250.50',
    );
    expect(
      FinanceMoneyFormatter.format(1250000, FinanceCurrency.khr),
      '៛1,250,000',
    );
    expect(
      FinanceMoneyFormatter.signed(5, FinanceCurrency.usd, debit: true),
      r'-$5.00',
    );
  });
}
