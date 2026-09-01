import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceSavingGoalEntity _goal({
  String id = 'goal-1',
  FinanceCurrency currency = FinanceCurrency.usd,
  String status = 'IN_PROGRESS',
  double current = 100,
  double target = 500,
  int progress = 20,
}) {
  return FinanceSavingGoalEntity(
    savingGoalId: id,
    title: 'Emergency fund',
    targetAmount: target,
    currentAmount: current,
    remainingAmount: target - current,
    progressPercent: progress,
    targetDate: '2026-12-31',
    status: status,
    currency: currency,
  );
}

FinanceSavingDepositEntity _deposit({String id = 'deposit-1'}) {
  return FinanceSavingDepositEntity(
    depositId: id,
    amount: 50,
    note: 'Monthly saving',
    depositDate: '2026-08-01',
  );
}

FinanceDashboardEntity _dashboard(FinanceCurrency currency) {
  return FinanceDashboardEntity(
    currency: currency,
    month: FinanceMonthOverview(
      month: 8,
      year: 2026,
      currency: currency,
      spent: 0,
    ),
    topCategories: const [],
    saving: FinanceSavingProgress(
      currency: currency,
      totalTarget: 0,
      totalSaved: 0,
      progressPercent: 0,
      activeGoals: 0,
    ),
    recentExpenses: const [],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceController financeController;
  late SavingGoalController controller;
  late int walletRefreshes;

  setUpAll(() {
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    repository = _MockFinanceRepository();
    financeController = FinanceController(repository: repository);
    walletRefreshes = 0;
    controller = SavingGoalController(
      repository: repository,
      financeController: financeController,
      refreshWalletState: () async => walletRefreshes++,
    );
    when(
      () => repository.getFinanceDashboard(currency: any(named: 'currency')),
    ).thenAnswer((invocation) async {
      return _dashboard(
        invocation.namedArguments[#currency] as FinanceCurrency,
      );
    });
    when(
      () => repository.getSavingGoals(
        status: any<String?>(named: 'status'),
        currency: any<FinanceCurrency?>(named: 'currency'),
      ),
    ).thenAnswer((_) async => const []);
  });

  tearDown(Get.reset);

  test('loads goals with explicit selected USD currency', () async {
    final value = _goal();
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async => [value]);

    await controller.loadGoals();

    expect(controller.goals.single, same(value));
    verify(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test('passes exact status and KHR filters before rendering rows', () async {
    final value = _goal(currency: FinanceCurrency.khr, status: 'COMPLETED');
    when(
      () => repository.getSavingGoals(
        status: 'COMPLETED',
        currency: FinanceCurrency.khr,
      ),
    ).thenAnswer((_) async => [value]);

    controller.selectedCurrency.value = FinanceCurrency.khr;
    await controller.selectStatus('completed');

    expect(controller.selectedStatus.value, 'COMPLETED');
    expect(controller.goals.single.currency, FinanceCurrency.khr);
  });

  test('rejects a response containing a different currency', () async {
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async => [_goal(currency: FinanceCurrency.khr)]);

    await controller.loadGoals();

    expect(controller.goals, isEmpty);
    expect(controller.listErrorMessage.value, contains('currency'));
  });

  test('a late USD list response cannot overwrite a newer KHR scope', () async {
    final usdCompleter = Completer<List<FinanceSavingGoalEntity>>();
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => usdCompleter.future);
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.khr,
      ),
    ).thenAnswer((_) async => [_goal(currency: FinanceCurrency.khr)]);

    final usdRequest = controller.loadGoals();
    await controller.selectCurrency(FinanceCurrency.khr);
    usdCompleter.complete([_goal(currency: FinanceCurrency.usd)]);
    await usdRequest;

    expect(controller.selectedCurrency.value, FinanceCurrency.khr);
    expect(controller.goals.single.currency, FinanceCurrency.khr);
  });

  test('refresh preserves existing goals when the server fails', () async {
    final value = _goal();
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) async => [value]);
    await controller.loadGoals();
    when(
      () => repository.getSavingGoals(
        status: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenThrow(const AppError(message: 'Offline', errorCode: 'NETWORK_ERROR'));

    await controller.refresh();

    expect(controller.goals.single, same(value));
    expect(controller.listErrorMessage.value, 'Offline');
  });

  test(
    'loads goal detail and deposit history from documented endpoints',
    () async {
      final value = _goal();
      when(
        () => repository.getSavingGoal('goal-1'),
      ).thenAnswer((_) async => value);
      when(
        () => repository.getSavingDeposits('goal-1'),
      ).thenAnswer((_) async => [_deposit()]);

      await controller.loadGoal('goal-1');
      await controller.loadDeposits('goal-1');

      expect(controller.selectedGoal.value, same(value));
      expect(controller.deposits.single.depositId, 'deposit-1');
    },
  );

  test(
    'create sends selected currency and refreshes goals/dashboard',
    () async {
      when(
        () => repository.createSavingGoal(
          title: 'Travel',
          targetAmount: 1000,
          targetDate: '2027-01-01',
          currency: FinanceCurrency.usd,
        ),
      ).thenAnswer((_) async => _goal());

      final success = await controller.createGoal(
        title: 'Travel',
        targetAmount: 1000,
        targetDate: '2027-01-01',
      );

      expect(success, isTrue);
      verify(
        () => repository.getSavingGoals(
          status: null,
          currency: FinanceCurrency.usd,
        ),
      ).called(1);
      verify(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).called(1);
    },
  );

  test('invalid create amount is blocked without a request', () async {
    final success = await controller.createGoal(title: 'Goal', targetAmount: 0);
    expect(success, isFalse);
    verifyNever(
      () => repository.createSavingGoal(
        title: any(named: 'title'),
        targetAmount: any(named: 'targetAmount'),
        targetDate: any(named: 'targetDate'),
        currency: any(named: 'currency'),
      ),
    );
  });

  test('duplicate create taps produce one backend mutation', () async {
    final completer = Completer<FinanceSavingGoalEntity>();
    when(
      () => repository.createSavingGoal(
        title: 'Goal',
        targetAmount: 100,
        targetDate: null,
        currency: FinanceCurrency.usd,
      ),
    ).thenAnswer((_) => completer.future);
    final first = controller.createGoal(title: 'Goal', targetAmount: 100);
    final second = controller.createGoal(title: 'Goal', targetAmount: 100);
    expect(await second, isFalse);
    completer.complete(_goal());
    expect(await first, isTrue);
    verify(
      () => repository.createSavingGoal(
        title: 'Goal',
        targetAmount: 100,
        targetDate: null,
        currency: FinanceCurrency.usd,
      ),
    ).called(1);
  });

  test(
    'update preserves the goal currency and applies the server response',
    () async {
      final existing = _goal(currency: FinanceCurrency.khr);
      final updated = _goal(
        currency: FinanceCurrency.khr,
        target: 700,
        current: 100,
      );
      when(
        () => repository.updateSavingGoal(
          savingGoalId: 'goal-1',
          title: 'Emergency fund',
          targetAmount: 700,
          targetDate: '2026-12-31',
          currency: FinanceCurrency.khr,
        ),
      ).thenAnswer((_) async => updated);
      controller.selectedCurrency.value = FinanceCurrency.khr;

      expect(
        await controller.updateGoal(
          existing: existing,
          title: existing.title,
          targetAmount: 700,
          targetDate: existing.targetDate,
        ),
        isTrue,
      );
      expect(controller.selectedGoal.value, same(updated));
    },
  );

  test('failed delete does not remove the goal', () async {
    final existing = _goal();
    controller.goals.assign(existing);
    when(() => repository.deleteSavingGoal('goal-1')).thenThrow(
      const AppError(message: 'Cannot delete', errorCode: 'API_ERROR'),
    );

    expect(await controller.deleteGoal('goal-1'), isFalse);
    expect(controller.goals.single, same(existing));
  });

  test(
    'wallet-funded contribution sends fromWallet true and refreshes all scopes',
    () async {
      final goal = _goal();
      final updated = _goal(current: 150, progress: 30);
      when(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 50,
          note: 'Monthly',
          depositDate: null,
          fromWallet: true,
        ),
      ).thenAnswer((_) async => updated);
      when(
        () => repository.getSavingGoal('goal-1'),
      ).thenAnswer((_) async => updated);
      when(
        () => repository.getSavingDeposits('goal-1'),
      ).thenAnswer((_) async => const []);

      expect(
        await controller.contribute(
          goal: goal,
          amount: 50,
          note: 'Monthly',
          fromWallet: true,
        ),
        isTrue,
      );
      verify(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 50,
          note: 'Monthly',
          depositDate: null,
          fromWallet: true,
        ),
      ).called(1);
      expect(controller.selectedGoal.value, same(updated));
      expect(walletRefreshes, 1);
      verify(
        () => repository.getFinanceDashboard(currency: FinanceCurrency.usd),
      ).called(1);
    },
  );

  test(
    'cash contribution sends false without inventing wallet behavior',
    () async {
      final goal = _goal();
      when(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 20,
          note: null,
          depositDate: null,
          fromWallet: false,
        ),
      ).thenAnswer((_) async => _goal(current: 120, progress: 24));
      when(
        () => repository.getSavingDeposits('goal-1'),
      ).thenAnswer((_) async => const []);

      expect(
        await controller.contribute(goal: goal, amount: 20, fromWallet: false),
        isTrue,
      );
      verify(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 20,
          note: null,
          depositDate: null,
          fromWallet: false,
        ),
      ).called(1);
      expect(walletRefreshes, 1);
    },
  );

  test(
    'insufficient wallet balance leaves the selected goal unchanged',
    () async {
      final goal = _goal();
      when(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 1000,
          note: null,
          depositDate: null,
          fromWallet: true,
        ),
      ).thenThrow(
        const AppError(
          message: 'Insufficient balance',
          errorCode: 'DEMO_WALLET_INSUFFICIENT_BALANCE',
        ),
      );

      expect(
        await controller.contribute(goal: goal, amount: 1000, fromWallet: true),
        isFalse,
      );
      expect(controller.selectedGoal.value, isNull);
      expect(controller.mutationErrorMessage.value, 'Insufficient balance');
      expect(walletRefreshes, 0);
    },
  );

  test(
    'currency mismatch blocks contribution before the backend call',
    () async {
      final goal = _goal(currency: FinanceCurrency.khr);
      expect(
        await controller.contribute(goal: goal, amount: 10, fromWallet: false),
        isFalse,
      );
      verifyNever(
        () => repository.depositToSavingGoal(
          savingGoalId: any(named: 'savingGoalId'),
          amount: any(named: 'amount'),
          note: any(named: 'note'),
          depositDate: any(named: 'depositDate'),
          fromWallet: any(named: 'fromWallet'),
        ),
      );
    },
  );

  test('duplicate contribution taps produce one mutation request', () async {
    final goal = _goal();
    final completer = Completer<FinanceSavingGoalEntity>();
    when(
      () => repository.depositToSavingGoal(
        savingGoalId: 'goal-1',
        amount: 10,
        note: null,
        depositDate: null,
        fromWallet: false,
      ),
    ).thenAnswer((_) => completer.future);
    when(
      () => repository.getSavingDeposits('goal-1'),
    ).thenAnswer((_) async => const []);
    final first = controller.contribute(
      goal: goal,
      amount: 10,
      fromWallet: false,
    );
    final second = controller.contribute(
      goal: goal,
      amount: 10,
      fromWallet: false,
    );
    expect(await second, isFalse);
    completer.complete(_goal(current: 110, progress: 22));
    expect(await first, isTrue);
    verify(
      () => repository.depositToSavingGoal(
        savingGoalId: 'goal-1',
        amount: 10,
        note: null,
        depositDate: null,
        fromWallet: false,
      ),
    ).called(1);
  });

  test(
    'server completed response is rendered without local over-target math',
    () async {
      final goal = _goal(target: 500);
      final completed = _goal(
        current: 500,
        target: 500,
        progress: 100,
        status: 'COMPLETED',
      );
      when(
        () => repository.depositToSavingGoal(
          savingGoalId: 'goal-1',
          amount: 400,
          note: null,
          depositDate: null,
          fromWallet: false,
        ),
      ).thenAnswer((_) async => completed);
      when(
        () => repository.getSavingDeposits('goal-1'),
      ).thenAnswer((_) async => const []);

      expect(
        await controller.contribute(goal: goal, amount: 400, fromWallet: false),
        isTrue,
      );
      expect(controller.selectedGoal.value?.status, 'COMPLETED');
      expect(controller.selectedGoal.value?.progressPercent, 100);
    },
  );

  test(
    'refresh during initial load clears the stale loading indicator',
    () async {
      final initial = Completer<List<FinanceSavingGoalEntity>>();
      final refreshed = Completer<List<FinanceSavingGoalEntity>>();
      var calls = 0;
      when(
        () => repository.getSavingGoals(
          status: any<String?>(named: 'status'),
          currency: any<FinanceCurrency?>(named: 'currency'),
        ),
      ).thenAnswer((_) {
        calls++;
        return calls == 1 ? initial.future : refreshed.future;
      });

      final loading = controller.loadGoals();
      expect(controller.isInitialLoading.value, isTrue);
      final refreshing = controller.refresh();
      expect(controller.isInitialLoading.value, isFalse);
      expect(controller.isRefreshing.value, isTrue);

      refreshed.complete([_goal(id: 'refreshed')]);
      await refreshing;
      initial.complete([_goal(id: 'stale')]);
      await loading;

      expect(controller.isInitialLoading.value, isFalse);
      expect(controller.isRefreshing.value, isFalse);
      expect(controller.goals.single.savingGoalId, 'refreshed');
    },
  );
}
