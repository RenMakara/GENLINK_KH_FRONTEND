import '../entities/finance_entities.dart';

abstract class FinanceRepository {
  Future<FinanceDashboardEntity> getFinanceDashboard({
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinancePage<FinanceExpenseEntity>> getExpenses({
    String? category,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  });

  Future<FinanceExpenseEntity> getExpense(String expenseId);

  Future<FinanceExpenseEntity> createExpense({
    required String title,
    required double amount,
    required String expenseDate,
    String? category,
    String? description,
    String? paymentMethod,
    bool? paidFromWallet,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinanceExpenseEntity> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required String expenseDate,
    String? category,
    String? description,
    String? paymentMethod,
    bool? paidFromWallet,
    FinanceCurrency? currency,
  });

  Future<void> deleteExpense(String expenseId);

  Future<FinanceMonthlySummaryEntity> getExpenseSummary({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  });

  Future<FinancePage<FinanceIncomeEntity>> getIncomes({
    String? source,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  });

  Future<FinanceIncomeEntity> getIncome(String incomeId);

  Future<FinanceIncomeEntity> createIncome({
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinanceIncomeEntity> updateIncome({
    required String incomeId,
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
    FinanceCurrency? currency,
  });

  Future<void> deleteIncome(String incomeId);

  Future<FinanceCashFlowEntity> getCashFlow({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  });

  Future<FinanceInsightsEntity> getFinanceInsights({
    required FinanceCurrency currency,
    required int month,
    required int year,
  });

  Future<List<FinanceRecurringTransactionEntity>> getRecurringTransactions();

  Future<FinanceRecurringTransactionEntity> createRecurringTransaction({
    required FinanceRecurringType type,
    required String title,
    required double amount,
    required FinanceRecurringFrequency frequency,
    required String startDate,
    required FinanceCurrency currency,
    String? category,
    bool fromWallet = false,
    String? endDate,
  });

  Future<void> deleteRecurringTransaction(String recurringId);

  Future<List<FinanceAutoSaveRuleEntity>> getAutoSaveRules();

  Future<FinanceAutoSaveRuleEntity> createAutoSaveRule({
    required String savingGoalId,
    required FinanceAutoSaveType type,
    required FinanceCurrency currency,
    double? percent,
  });

  Future<void> deleteAutoSaveRule(String ruleId);

  Future<FinanceWalletEntity> getWallet();

  Future<FinanceWalletEntity> topUpWallet({
    required double amount,
    String? note,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinanceWalletEntity> makePayment({
    required double amount,
    String? merchant,
    String? note,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinancePage<FinanceWalletTransactionEntity>> getWalletTransactions({
    int? page,
    int? size,
  });

  Future<FinancePage<FinanceBudgetEntity>> getBudgets({int? page, int? size});

  Future<FinanceBudgetEntity> getCurrentBudget({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  });

  Future<FinanceBudgetEntity> getBudget(String budgetId);

  Future<FinanceBudgetEntity> createBudget({
    required int month,
    required int year,
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinanceBudgetEntity> updateBudget({
    required String budgetId,
    required int month,
    required int year,
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
    FinanceCurrency? currency,
  });

  Future<void> deleteBudget(String budgetId);

  Future<List<FinanceSavingGoalEntity>> getSavingGoals({
    String? status,
    FinanceCurrency? currency,
  });

  Future<FinanceSavingGoalEntity> getSavingGoal(String savingGoalId);

  Future<FinanceSavingGoalEntity> createSavingGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
    FinanceCurrency currency = FinanceCurrency.usd,
  });

  Future<FinanceSavingGoalEntity> updateSavingGoal({
    required String savingGoalId,
    required String title,
    required double targetAmount,
    String? targetDate,
    FinanceCurrency? currency,
  });

  Future<void> deleteSavingGoal(String savingGoalId);

  Future<FinanceSavingGoalEntity> depositToSavingGoal({
    required String savingGoalId,
    required double amount,
    String? note,
    String? depositDate,
    bool? fromWallet,
  });

  Future<List<FinanceSavingDepositEntity>> getSavingDeposits(
    String savingGoalId,
  );

  Future<FinanceLearningDashboardEntity> getLearningDashboard();

  Future<List<FinanceLearningLessonSummaryEntity>> getLearningLessons({
    String? topic,
  });

  Future<FinanceLearningLessonDetailEntity> getLearningLesson(String lessonId);

  Future<FinanceLearningLessonDetailEntity> completeLearningLesson(
    String lessonId,
  );

  Future<List<FinanceLearningQuizQuestionEntity>> getLearningQuiz(
    String lessonId,
  );

  Future<FinanceLearningQuizResultEntity> submitLearningQuiz({
    required String lessonId,
    required List<FinanceLearningQuizAnswerEntity> answers,
  });
}
