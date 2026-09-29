import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_tools_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceRecurringTransactionEntity _recurring() =>
    const FinanceRecurringTransactionEntity(
      id: 'recurring-1',
      type: FinanceRecurringType.expense,
      title: 'Rent',
      amount: 12.3,
      currency: FinanceCurrency.usd,
      frequency: FinanceRecurringFrequency.monthly,
      fromWallet: false,
      nextRunDate: '2026-10-01',
      startDate: '2026-10-01',
      active: true,
    );

FinanceAutoSaveRuleEntity _autoSave() => const FinanceAutoSaveRuleEntity(
  id: 'autosave-1',
  savingGoalId: 'goal-1',
  goalTitle: 'Emergency',
  type: FinanceAutoSaveType.percentOfIncome,
  percent: 10,
  currency: FinanceCurrency.khr,
  nextRunDate: '2026-10-01',
  active: true,
);

FinanceSavingGoalEntity _goal() => const FinanceSavingGoalEntity(
  savingGoalId: 'goal-1',
  title: 'Emergency',
  targetAmount: 1000,
  currentAmount: 200,
  remainingAmount: 800,
  progressPercent: 20,
  status: 'IN_PROGRESS',
  currency: FinanceCurrency.khr,
);

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late FinanceToolsController controller;

  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    controller = FinanceToolsController(
      repository: repository,
      financeController: financeController,
    );
  });

  tearDown(Get.reset);

  test('rejects recurring money with more than two decimal places', () async {
    final created = await controller.createRecurringTransaction(
      type: FinanceRecurringType.expense,
      title: 'Rent',
      amountText: '10.123',
      frequency: FinanceRecurringFrequency.monthly,
      startDate: '2026-10-01',
      currency: FinanceCurrency.usd,
    );

    expect(created, isFalse);
    expect(controller.recurringMutationError.value, isNotNull);
    verifyNever(
      () => repository.createRecurringTransaction(
        type: FinanceRecurringType.expense,
        title: 'Rent',
        amount: 10.123,
        frequency: FinanceRecurringFrequency.monthly,
        startDate: '2026-10-01',
        currency: FinanceCurrency.usd,
      ),
    );
  });

  test(
    'creates and reloads a recurring transaction using the supported fields',
    () async {
      final created = _recurring();
      when(
        () => repository.createRecurringTransaction(
          type: FinanceRecurringType.expense,
          title: 'Rent',
          amount: 12.3,
          frequency: FinanceRecurringFrequency.monthly,
          startDate: '2026-10-01',
          currency: FinanceCurrency.usd,
          category: 'HOME',
          fromWallet: true,
          endDate: null,
        ),
      ).thenAnswer((_) async => created);
      when(
        () => repository.getRecurringTransactions(),
      ).thenAnswer((_) async => [created]);

      final success = await controller.createRecurringTransaction(
        type: FinanceRecurringType.expense,
        title: ' Rent ',
        amountText: '12.30',
        frequency: FinanceRecurringFrequency.monthly,
        startDate: '2026-10-01',
        currency: FinanceCurrency.usd,
        category: ' HOME ',
        fromWallet: true,
      );

      expect(success, isTrue, reason: controller.recurringMutationError.value);
      expect(controller.recurringTransactions.single.id, 'recurring-1');
      verify(
        () => repository.createRecurringTransaction(
          type: FinanceRecurringType.expense,
          title: 'Rent',
          amount: 12.3,
          frequency: FinanceRecurringFrequency.monthly,
          startDate: '2026-10-01',
          currency: FinanceCurrency.usd,
          category: 'HOME',
          fromWallet: true,
          endDate: null,
        ),
      ).called(1);
    },
  );

  test(
    'blocks a duplicate recurring submit while the first request is pending',
    () async {
      final pending = Completer<FinanceRecurringTransactionEntity>();
      when(
        () => repository.createRecurringTransaction(
          type: FinanceRecurringType.income,
          title: 'Allowance',
          amount: 20,
          frequency: FinanceRecurringFrequency.weekly,
          startDate: '2026-10-01',
          currency: FinanceCurrency.usd,
          category: null,
          fromWallet: false,
          endDate: null,
        ),
      ).thenAnswer((_) => pending.future);
      when(
        () => repository.getRecurringTransactions(),
      ).thenAnswer((_) async => [_recurring()]);

      final first = controller.createRecurringTransaction(
        type: FinanceRecurringType.income,
        title: 'Allowance',
        amountText: '20',
        frequency: FinanceRecurringFrequency.weekly,
        startDate: '2026-10-01',
        currency: FinanceCurrency.usd,
      );
      expect(controller.isRecurringSubmitting.value, isTrue);
      final second = await controller.createRecurringTransaction(
        type: FinanceRecurringType.income,
        title: 'Allowance',
        amountText: '20',
        frequency: FinanceRecurringFrequency.weekly,
        startDate: '2026-10-01',
        currency: FinanceCurrency.usd,
      );
      expect(second, isFalse);
      pending.complete(_recurring());
      expect(
        await first,
        isTrue,
        reason: controller.recurringMutationError.value,
      );
      verify(
        () => repository.createRecurringTransaction(
          type: FinanceRecurringType.income,
          title: 'Allowance',
          amount: 20,
          frequency: FinanceRecurringFrequency.weekly,
          startDate: '2026-10-01',
          currency: FinanceCurrency.usd,
          category: null,
          fromWallet: false,
          endDate: null,
        ),
      ).called(1);
    },
  );

  test(
    'loads a matching-currency goal and creates Auto Save in that currency',
    () async {
      when(
        () => repository.getSavingGoals(
          status: 'IN_PROGRESS',
          currency: FinanceCurrency.khr,
        ),
      ).thenAnswer((_) async => [_goal()]);
      when(
        () => repository.createAutoSaveRule(
          savingGoalId: 'goal-1',
          type: FinanceAutoSaveType.percentOfIncome,
          currency: FinanceCurrency.khr,
          percent: 10,
        ),
      ).thenAnswer((_) async => _autoSave());
      when(
        () => repository.getAutoSaveRules(),
      ).thenAnswer((_) async => [_autoSave()]);

      await controller.loadSavingGoals(FinanceCurrency.khr);
      final success = await controller.createAutoSaveRule(
        savingGoalId: 'goal-1',
        type: FinanceAutoSaveType.percentOfIncome,
        percentText: '10.00',
      );

      expect(success, isTrue, reason: controller.autoSaveMutationError.value);
      expect(controller.autoSaveRules.single.currency, FinanceCurrency.khr);
      verify(
        () => repository.createAutoSaveRule(
          savingGoalId: 'goal-1',
          type: FinanceAutoSaveType.percentOfIncome,
          currency: FinanceCurrency.khr,
          percent: 10,
        ),
      ).called(1);
    },
  );

  test('rejects an Auto Save percent above the backend limit', () async {
    when(
      () => repository.getSavingGoals(
        status: 'IN_PROGRESS',
        currency: FinanceCurrency.khr,
      ),
    ).thenAnswer((_) async => [_goal()]);
    await controller.loadSavingGoals(FinanceCurrency.khr);

    final success = await controller.createAutoSaveRule(
      savingGoalId: 'goal-1',
      type: FinanceAutoSaveType.percentOfIncome,
      percentText: '100.01',
    );

    expect(success, isFalse);
    expect(controller.autoSaveMutationError.value, isNotNull);
    verifyNever(
      () => repository.createAutoSaveRule(
        savingGoalId: 'goal-1',
        type: FinanceAutoSaveType.percentOfIncome,
        currency: FinanceCurrency.khr,
        percent: 100.01,
      ),
    );
  });

  test(
    'keeps visible recurring rules and exposes a retryable refresh error',
    () async {
      final existing = _recurring();
      controller.recurringTransactions.add(existing);
      when(() => repository.getRecurringTransactions()).thenThrow(
        const AppError(
          message: 'Recurring unavailable',
          errorCode: 'API_ERROR',
          statusCode: 503,
        ),
      );

      await controller.loadRecurringTransactions();

      expect(controller.recurringTransactions.single, same(existing));
      expect(controller.recurringErrorMessage.value, 'Recurring unavailable');
    },
  );
}
