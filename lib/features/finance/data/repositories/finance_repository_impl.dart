import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_datasource.dart';
import '../models/finance_models.dart';

/// Finance repository implementation.
///
/// The remote data source already converts Dio failures into the shared
/// [AppError] type through [ApiClient], so this layer remains a typed,
/// UI-independent pass-through and does not swallow backend error codes.
class FinanceRepositoryImpl implements FinanceRepository {
  const FinanceRepositoryImpl(this._remote);

  final FinanceRemoteDatasource _remote;

  @override
  Future<FinanceDashboardEntity> getFinanceDashboard({
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.getFinanceDashboard(currency);

  @override
  Future<FinancePage<FinanceExpenseEntity>> getExpenses({
    String? category,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  }) => _remote.getExpenses(
    category: category,
    month: month,
    year: year,
    currency: currency,
    page: page,
    size: size,
  );

  @override
  Future<FinanceExpenseEntity> getExpense(String expenseId) =>
      _remote.getExpense(expenseId);

  @override
  Future<FinanceExpenseEntity> createExpense({
    required String title,
    required double amount,
    required String expenseDate,
    String? category,
    String? description,
    String? paymentMethod,
    bool? paidFromWallet,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.createExpense(
    FinanceExpenseRequestModel(
      title: title,
      amount: amount,
      category: category,
      description: description,
      expenseDate: expenseDate,
      paymentMethod: paymentMethod,
      paidFromWallet: paidFromWallet,
      currency: currency,
    ),
  );

  @override
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
  }) => _remote.updateExpense(
    expenseId,
    FinanceExpenseRequestModel(
      title: title,
      amount: amount,
      category: category,
      description: description,
      expenseDate: expenseDate,
      paymentMethod: paymentMethod,
      paidFromWallet: paidFromWallet,
      currency: currency,
    ),
  );

  @override
  Future<void> deleteExpense(String expenseId) =>
      _remote.deleteExpense(expenseId);

  @override
  Future<FinanceMonthlySummaryEntity> getExpenseSummary({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  }) => _remote.getExpenseSummary(currency: currency, month: month, year: year);

  @override
  Future<FinancePage<FinanceIncomeEntity>> getIncomes({
    String? source,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  }) => _remote.getIncomes(
    source: source,
    month: month,
    year: year,
    currency: currency,
    page: page,
    size: size,
  );

  @override
  Future<FinanceIncomeEntity> getIncome(String incomeId) =>
      _remote.getIncome(incomeId);

  @override
  Future<FinanceIncomeEntity> createIncome({
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.createIncome(
    FinanceIncomeRequestModel(
      title: title,
      amount: amount,
      source: source,
      description: description,
      incomeDate: incomeDate,
      currency: currency,
    ),
  );

  @override
  Future<FinanceIncomeEntity> updateIncome({
    required String incomeId,
    required String title,
    required double amount,
    required String incomeDate,
    String? source,
    String? description,
    FinanceCurrency? currency,
  }) => _remote.updateIncome(
    incomeId,
    FinanceIncomeRequestModel(
      title: title,
      amount: amount,
      source: source,
      description: description,
      incomeDate: incomeDate,
      currency: currency,
    ),
  );

  @override
  Future<void> deleteIncome(String incomeId) => _remote.deleteIncome(incomeId);

  @override
  Future<FinanceCashFlowEntity> getCashFlow({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  }) => _remote.getCashFlow(currency: currency, month: month, year: year);

  @override
  Future<FinanceWalletEntity> getWallet() => _remote.getWallet();

  @override
  Future<FinanceWalletEntity> topUpWallet({
    required double amount,
    String? note,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.topUpWallet(
    FinanceWalletTopUpRequestModel(
      amount: amount,
      note: note,
      currency: currency,
    ),
  );

  @override
  Future<FinanceWalletEntity> makePayment({
    required double amount,
    String? merchant,
    String? note,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.makePayment(
    FinanceWalletPaymentRequestModel(
      amount: amount,
      merchant: merchant,
      note: note,
      currency: currency,
    ),
  );

  @override
  Future<FinancePage<FinanceWalletTransactionEntity>> getWalletTransactions({
    int? page,
    int? size,
  }) => _remote.getWalletTransactions(page: page, size: size);

  @override
  Future<FinancePage<FinanceBudgetEntity>> getBudgets({int? page, int? size}) =>
      _remote.getBudgets(page: page, size: size);

  @override
  Future<FinanceBudgetEntity> getCurrentBudget({
    FinanceCurrency currency = FinanceCurrency.usd,
    int? month,
    int? year,
  }) => _remote.getCurrentBudget(currency: currency, month: month, year: year);

  @override
  Future<FinanceBudgetEntity> getBudget(String budgetId) =>
      _remote.getBudget(budgetId);

  @override
  Future<FinanceBudgetEntity> createBudget({
    required int month,
    required int year,
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.createBudget(
    FinanceBudgetRequestModel(
      month: month,
      year: year,
      totalBudget: totalBudget,
      categories: _categoryRequests(categories),
      currency: currency,
    ),
  );

  @override
  Future<FinanceBudgetEntity> updateBudget({
    required String budgetId,
    required int month,
    required int year,
    required double totalBudget,
    List<FinanceBudgetAllocation>? categories,
    FinanceCurrency? currency,
  }) => _remote.updateBudget(
    budgetId,
    FinanceBudgetRequestModel(
      month: month,
      year: year,
      totalBudget: totalBudget,
      categories: _categoryRequests(categories),
      currency: currency,
    ),
  );

  @override
  Future<void> deleteBudget(String budgetId) => _remote.deleteBudget(budgetId);

  @override
  Future<List<FinanceSavingGoalEntity>> getSavingGoals({
    String? status,
    FinanceCurrency? currency,
  }) => _remote.getSavingGoals(status: status, currency: currency);

  @override
  Future<FinanceSavingGoalEntity> getSavingGoal(String savingGoalId) =>
      _remote.getSavingGoal(savingGoalId);

  @override
  Future<FinanceSavingGoalEntity> createSavingGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
    FinanceCurrency currency = FinanceCurrency.usd,
  }) => _remote.createSavingGoal(
    FinanceSavingGoalRequestModel(
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      currency: currency,
    ),
  );

  @override
  Future<FinanceSavingGoalEntity> updateSavingGoal({
    required String savingGoalId,
    required String title,
    required double targetAmount,
    String? targetDate,
    FinanceCurrency? currency,
  }) => _remote.updateSavingGoal(
    savingGoalId,
    FinanceSavingGoalRequestModel(
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      currency: currency,
    ),
  );

  @override
  Future<void> deleteSavingGoal(String savingGoalId) =>
      _remote.deleteSavingGoal(savingGoalId);

  @override
  Future<FinanceSavingGoalEntity> depositToSavingGoal({
    required String savingGoalId,
    required double amount,
    String? note,
    String? depositDate,
    bool? fromWallet,
  }) => _remote.depositToSavingGoal(
    savingGoalId,
    FinanceSavingDepositRequestModel(
      amount: amount,
      note: note,
      depositDate: depositDate,
      fromWallet: fromWallet,
    ),
  );

  @override
  Future<List<FinanceSavingDepositEntity>> getSavingDeposits(
    String savingGoalId,
  ) => _remote.getSavingDeposits(savingGoalId);

  @override
  Future<FinanceLearningDashboardEntity> getLearningDashboard() =>
      _remote.getLearningDashboard();

  @override
  Future<List<FinanceLearningLessonSummaryEntity>> getLearningLessons({
    String? topic,
  }) => _remote.getLearningLessons(topic: topic);

  @override
  Future<FinanceLearningLessonDetailEntity> getLearningLesson(
    String lessonId,
  ) => _remote.getLearningLesson(lessonId);

  @override
  Future<FinanceLearningLessonDetailEntity> completeLearningLesson(
    String lessonId,
  ) => _remote.completeLearningLesson(lessonId);

  @override
  Future<List<FinanceLearningQuizQuestionEntity>> getLearningQuiz(
    String lessonId,
  ) => _remote.getLearningQuiz(lessonId);

  @override
  Future<FinanceLearningQuizResultEntity> submitLearningQuiz({
    required String lessonId,
    required List<FinanceLearningQuizAnswerEntity> answers,
  }) => _remote.submitLearningQuiz(
    lessonId: lessonId,
    request: FinanceLearningQuizSubmitRequestModel(
      answers: answers
          .map(
            (answer) => FinanceLearningQuizAnswerRequestModel(
              questionId: answer.questionId,
              selectedOption: answer.selectedOption,
            ),
          )
          .toList(growable: false),
    ),
  );

  static List<FinanceBudgetCategoryRequestModel>? _categoryRequests(
    List<FinanceBudgetAllocation>? categories,
  ) {
    return categories
        ?.map(
          (category) => FinanceBudgetCategoryRequestModel(
            category: category.category,
            allocatedAmount: category.allocatedAmount,
          ),
        )
        .toList(growable: false);
  }
}
