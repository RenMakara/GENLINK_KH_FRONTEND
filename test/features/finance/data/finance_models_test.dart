import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/finance/data/models/finance_models.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';

void main() {
  group('Finance currency', () {
    test('serializes only the backend enum values', () {
      expect(FinanceCurrency.usd.apiValue, 'USD');
      expect(FinanceCurrency.khr.apiValue, 'KHR');
      expect(parseFinanceCurrency('USD'), FinanceCurrency.usd);
      expect(parseFinanceCurrency('KHR'), FinanceCurrency.khr);
    });

    test('does not silently treat unknown values as USD', () {
      expect(
        () => parseFinanceCurrency('EUR'),
        throwsA(isA<FormatException>()),
      );
      expect(() => parseFinanceCurrency(null), throwsA(isA<FormatException>()));
    });
  });

  test('maps a currency-scoped dashboard without mixing wallet balances', () {
    final dashboard = FinanceMapper.dashboard({
      'currency': 'KHR',
      'month': {
        'month': 8,
        'year': 2026,
        'currency': 'KHR',
        'spent': 120000,
        'budgetTotal': 500000,
        'budgetRemaining': 380000,
        'budgetStatus': 'SAFE',
      },
      'topCategories': [
        {'category': 'FOOD', 'currency': 'KHR', 'amount': 120000},
      ],
      'saving': {
        'currency': 'KHR',
        'totalTarget': 1000000,
        'totalSaved': 250000,
        'progressPercent': 25,
        'activeGoals': 1,
      },
      'recentExpenses': [
        {
          'expenseId': 'expense-1',
          'title': 'Lunch',
          'category': 'FOOD',
          'currency': 'KHR',
          'amount': 120000,
          'expenseDate': '2026-08-20',
        },
      ],
      'wallet': {'balanceUsd': 20.5, 'balanceKhr': 800000},
      'financialTip': 'Track every expense.',
      'quickActions': ['ADD_EXPENSE'],
    });

    expect(dashboard.currency, FinanceCurrency.khr);
    expect(dashboard.month.currency, FinanceCurrency.khr);
    expect(dashboard.topCategories.single.currency, FinanceCurrency.khr);
    expect(dashboard.saving.currency, FinanceCurrency.khr);
    expect(dashboard.recentExpenses.single.currency, FinanceCurrency.khr);
    expect(dashboard.wallet?.balanceUsd, 20.5);
    expect(dashboard.wallet?.balanceKhr, 800000);
  });

  test('maps PageResponse metadata before client pagination', () {
    final page = FinanceMapper.expensesPage({
      'content': [
        {
          'expenseId': 'expense-1',
          'title': 'Lunch',
          'amount': 5.25,
          'currency': 'USD',
          'category': 'FOOD',
          'description': null,
          'expenseDate': '2026-08-20',
          'paymentMethod': 'CASH',
          'paidFromWallet': false,
          'createdAt': '2026-08-20T10:00:00Z',
        },
      ],
      'page': 1,
      'size': 20,
      'totalElements': 41,
      'totalPages': 3,
      'hasNext': true,
    });

    expect(page.page, 1);
    expect(page.size, 20);
    expect(page.totalElements, 41);
    expect(page.totalPages, 3);
    expect(page.hasNext, isTrue);
    expect(page.content.single.currency, FinanceCurrency.usd);
    expect(page.content.single.paidFromWallet, isFalse);
  });

  test('request models serialize currency and omit optional null fields', () {
    final request = FinanceExpenseRequestModel(
      title: 'Lunch',
      amount: 5.25,
      expenseDate: '2026-08-20',
      paidFromWallet: true,
      currency: FinanceCurrency.khr,
    );

    expect(request.toJson(), {
      'title': 'Lunch',
      'amount': 5.25,
      'expenseDate': '2026-08-20',
      'paidFromWallet': true,
      'currency': 'KHR',
    });
  });

  test(
    'wallet operation request models match the documented wire contract',
    () {
      expect(
        FinanceWalletTopUpRequestModel(
          amount: 100,
          note: 'allowance',
          currency: FinanceCurrency.usd,
        ).toJson(),
        {'amount': 100, 'note': 'allowance', 'currency': 'USD'},
      );
      expect(
        FinanceWalletPaymentRequestModel(
          amount: 15,
          merchant: 'Brown Coffee',
          note: 'latte',
          currency: FinanceCurrency.khr,
        ).toJson(),
        {
          'amount': 15,
          'merchant': 'Brown Coffee',
          'note': 'latte',
          'currency': 'KHR',
        },
      );
    },
  );

  test('malformed currency-scoped payload is rejected', () {
    expect(
      () => FinanceMapper.monthlySummary({
        'month': 8,
        'year': 2026,
        'currency': 'EUR',
        'total': 1,
        'byCategory': [],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('maps the existing insights response contract', () {
    final result = FinanceMapper.insights({
      'currency': 'USD',
      'month': 9,
      'year': 2026,
      'income': 120.00,
      'expense': 60.00,
      'net': 60.00,
      'savingsRatePercent': 50.0,
      'insights': [
        {
          'type': 'SPENDING_TREND',
          'severity': 'INFO',
          'title': 'Spending trend',
          'message': 'Expense is higher than last month.',
          'category': null,
          'amount': 60.0,
          'lesson': {
            'lessonId': 'lesson-1',
            'title': 'Budgeting',
            'topic': 'BUDGETING',
          },
        },
      ],
    });

    expect(result.currency, FinanceCurrency.usd);
    expect(result.month, 9);
    expect(result.insights.single.type, 'SPENDING_TREND');
    expect(result.insights.single.lessonId, 'lesson-1');
  });

  test(
    'recurring and Auto Save requests serialize only supported API fields',
    () {
      expect(
        const FinanceRecurringTransactionRequestModel(
          type: FinanceRecurringType.expense,
          title: ' Rent ',
          amount: 12.3,
          frequency: FinanceRecurringFrequency.monthly,
          startDate: '2026-10-01',
          currency: FinanceCurrency.usd,
          category: ' HOME ',
          fromWallet: true,
        ).toJson(),
        {
          'type': 'EXPENSE',
          'title': 'Rent',
          'amount': 12.3,
          'currency': 'USD',
          'category': 'HOME',
          'frequency': 'MONTHLY',
          'fromWallet': true,
          'startDate': '2026-10-01',
        },
      );
      expect(
        const FinanceAutoSaveRuleRequestModel(
          savingGoalId: 'goal-1',
          type: FinanceAutoSaveType.roundUp,
          currency: FinanceCurrency.khr,
        ).toJson(),
        {'savingGoalId': 'goal-1', 'type': 'ROUND_UP', 'currency': 'KHR'},
      );
    },
  );
}
