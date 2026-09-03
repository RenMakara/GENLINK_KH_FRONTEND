import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/finance_entities.dart';
import '../models/finance_models.dart';

/// Remote Finance data source.
///
/// This is the only Finance layer that knows endpoint paths, query parameters,
/// request JSON, and the ApiResponse envelope.  [ApiClient] handles the
/// authenticated Dio stack and unwraps the envelope before mapping.
class FinanceRemoteDatasource {
  const FinanceRemoteDatasource(this._client);

  final ApiClient _client;

  // ── Dashboard ────────────────────────────────────────────────────────

  Future<FinanceDashboardEntity> getFinanceDashboard(FinanceCurrency currency) {
    return _client.get(
      ApiEndpoints.mobileFinanceDashboard,
      query: {'currency': currency.apiValue},
      parse: (data) => FinanceMapper.dashboard(ApiClient.asMap(data)),
    );
  }

  // ── Expenses ─────────────────────────────────────────────────────────

  Future<FinancePage<FinanceExpenseEntity>> getExpenses({
    String? category,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  }) {
    return _client.get(
      ApiEndpoints.financeExpenses,
      query: _query({
        'category': category,
        'month': month,
        'year': year,
        'currency': currency?.apiValue,
        'page': page,
        'size': size,
      }),
      parse: (data) => FinanceMapper.expensesPage(ApiClient.asMap(data)),
    );
  }

  Future<FinanceExpenseEntity> getExpense(String expenseId) {
    return _client.get(
      ApiEndpoints.financeExpense(expenseId),
      parse: (data) => FinanceMapper.expense(ApiClient.asMap(data)),
    );
  }

  Future<FinanceExpenseEntity> createExpense(
    FinanceExpenseRequestModel request,
  ) {
    return _client.post(
      ApiEndpoints.financeExpenses,
      body: request.toJson(),
      parse: (data) => FinanceMapper.expense(ApiClient.asMap(data)),
    );
  }

  Future<FinanceExpenseEntity> updateExpense(
    String expenseId,
    FinanceExpenseRequestModel request,
  ) {
    return _client.put(
      ApiEndpoints.financeExpense(expenseId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.expense(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteExpense(String expenseId) {
    return _client.delete(ApiEndpoints.financeExpense(expenseId));
  }

  Future<FinanceMonthlySummaryEntity> getExpenseSummary({
    required FinanceCurrency currency,
    int? month,
    int? year,
  }) {
    return _client.get(
      ApiEndpoints.financeExpenseSummary,
      query: _query({
        'month': month,
        'year': year,
        'currency': currency.apiValue,
      }),
      parse: (data) => FinanceMapper.monthlySummary(ApiClient.asMap(data)),
    );
  }

  // ── Income ───────────────────────────────────────────────────────────

  Future<FinancePage<FinanceIncomeEntity>> getIncomes({
    String? source,
    int? month,
    int? year,
    FinanceCurrency? currency,
    int? page,
    int? size,
  }) {
    return _client.get(
      ApiEndpoints.financeIncomes,
      query: _query({
        'source': source,
        'month': month,
        'year': year,
        'currency': currency?.apiValue,
        'page': page,
        'size': size,
      }),
      parse: (data) => FinanceMapper.incomesPage(ApiClient.asMap(data)),
    );
  }

  Future<FinanceIncomeEntity> getIncome(String incomeId) {
    return _client.get(
      ApiEndpoints.financeIncome(incomeId),
      parse: (data) => FinanceMapper.income(ApiClient.asMap(data)),
    );
  }

  Future<FinanceIncomeEntity> createIncome(FinanceIncomeRequestModel request) {
    return _client.post(
      ApiEndpoints.financeIncomes,
      body: request.toJson(),
      parse: (data) => FinanceMapper.income(ApiClient.asMap(data)),
    );
  }

  Future<FinanceIncomeEntity> updateIncome(
    String incomeId,
    FinanceIncomeRequestModel request,
  ) {
    return _client.put(
      ApiEndpoints.financeIncome(incomeId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.income(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteIncome(String incomeId) {
    return _client.delete(ApiEndpoints.financeIncome(incomeId));
  }

  Future<FinanceCashFlowEntity> getCashFlow({
    required FinanceCurrency currency,
    int? month,
    int? year,
  }) {
    return _client.get(
      ApiEndpoints.financeCashFlow,
      query: _query({
        'currency': currency.apiValue,
        'month': month,
        'year': year,
      }),
      parse: (data) => FinanceMapper.cashFlow(ApiClient.asMap(data)),
    );
  }

  // ── Wallet ───────────────────────────────────────────────────────────

  Future<FinanceWalletEntity> getWallet() {
    return _client.get(
      ApiEndpoints.financeWallet,
      parse: (data) => FinanceMapper.wallet(ApiClient.asMap(data)),
    );
  }

  Future<FinanceWalletEntity> topUpWallet(
    FinanceWalletTopUpRequestModel request,
  ) {
    return _client.post(
      ApiEndpoints.financeWalletTopUp,
      body: request.toJson(),
      parse: (data) => FinanceMapper.wallet(ApiClient.asMap(data)),
    );
  }

  Future<FinanceWalletEntity> makePayment(
    FinanceWalletPaymentRequestModel request,
  ) {
    return _client.post(
      ApiEndpoints.financeWalletPay,
      body: request.toJson(),
      parse: (data) => FinanceMapper.wallet(ApiClient.asMap(data)),
    );
  }

  Future<FinancePage<FinanceWalletTransactionEntity>> getWalletTransactions({
    int? page,
    int? size,
  }) {
    return _client.get(
      ApiEndpoints.financeWalletTransactions,
      query: _query({'page': page, 'size': size}),
      parse: (data) => FinanceMapper.page(
        ApiClient.asMap(data),
        FinanceMapper.walletTransaction,
      ),
    );
  }

  // ── Budgets ──────────────────────────────────────────────────────────

  Future<FinancePage<FinanceBudgetEntity>> getBudgets({int? page, int? size}) {
    return _client.get(
      ApiEndpoints.financeBudgets,
      query: _query({'page': page, 'size': size}),
      parse: (data) => FinanceMapper.budgetsPage(ApiClient.asMap(data)),
    );
  }

  Future<FinanceBudgetEntity> getCurrentBudget({
    required FinanceCurrency currency,
    int? month,
    int? year,
  }) {
    return _client.get(
      ApiEndpoints.financeBudgetCurrent,
      query: _query({
        'month': month,
        'year': year,
        'currency': currency.apiValue,
      }),
      parse: (data) => FinanceMapper.budget(ApiClient.asMap(data)),
    );
  }

  Future<FinanceBudgetEntity> getBudget(String budgetId) {
    return _client.get(
      ApiEndpoints.financeBudget(budgetId),
      parse: (data) => FinanceMapper.budget(ApiClient.asMap(data)),
    );
  }

  Future<FinanceBudgetEntity> createBudget(FinanceBudgetRequestModel request) {
    return _client.post(
      ApiEndpoints.financeBudgets,
      body: request.toJson(),
      parse: (data) => FinanceMapper.budget(ApiClient.asMap(data)),
    );
  }

  Future<FinanceBudgetEntity> updateBudget(
    String budgetId,
    FinanceBudgetRequestModel request,
  ) {
    return _client.put(
      ApiEndpoints.financeBudget(budgetId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.budget(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteBudget(String budgetId) {
    return _client.delete(ApiEndpoints.financeBudget(budgetId));
  }

  // ── Saving goals ─────────────────────────────────────────────────────

  Future<List<FinanceSavingGoalEntity>> getSavingGoals({
    String? status,
    FinanceCurrency? currency,
  }) {
    return _client.get(
      ApiEndpoints.financeSavings,
      query: _query({'status': status, 'currency': currency?.apiValue}),
      parse: (data) => ApiClient.asList(data, FinanceMapper.savingGoal),
    );
  }

  Future<FinanceSavingGoalEntity> getSavingGoal(String savingGoalId) {
    return _client.get(
      ApiEndpoints.financeSaving(savingGoalId),
      parse: (data) => FinanceMapper.savingGoal(ApiClient.asMap(data)),
    );
  }

  Future<FinanceSavingGoalEntity> createSavingGoal(
    FinanceSavingGoalRequestModel request,
  ) {
    return _client.post(
      ApiEndpoints.financeSavings,
      body: request.toJson(),
      parse: (data) => FinanceMapper.savingGoal(ApiClient.asMap(data)),
    );
  }

  Future<FinanceSavingGoalEntity> updateSavingGoal(
    String savingGoalId,
    FinanceSavingGoalRequestModel request,
  ) {
    return _client.put(
      ApiEndpoints.financeSaving(savingGoalId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.savingGoal(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteSavingGoal(String savingGoalId) {
    return _client.delete(ApiEndpoints.financeSaving(savingGoalId));
  }

  Future<FinanceSavingGoalEntity> depositToSavingGoal(
    String savingGoalId,
    FinanceSavingDepositRequestModel request,
  ) {
    return _client.post(
      ApiEndpoints.financeSavingDeposits(savingGoalId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.savingGoal(ApiClient.asMap(data)),
    );
  }

  Future<List<FinanceSavingDepositEntity>> getSavingDeposits(
    String savingGoalId,
  ) {
    return _client.get(
      ApiEndpoints.financeSavingDeposits(savingGoalId),
      parse: (data) => ApiClient.asList(data, FinanceMapper.savingDeposit),
    );
  }

  // ── Financial literacy ──────────────────────────────────────────────

  Future<FinanceLearningDashboardEntity> getLearningDashboard() {
    return _client.get(
      ApiEndpoints.financeLearningDashboard,
      parse: (data) => FinanceMapper.learningDashboard(ApiClient.asMap(data)),
    );
  }

  Future<List<FinanceLearningLessonSummaryEntity>> getLearningLessons({
    String? topic,
  }) {
    return _client.get(
      ApiEndpoints.financeLearningLessons,
      query: _query({'topic': topic}),
      parse: (data) =>
          ApiClient.asList(data, FinanceMapper.learningLessonSummary),
    );
  }

  Future<FinanceLearningLessonDetailEntity> getLearningLesson(String lessonId) {
    return _client.get(
      ApiEndpoints.financeLearningLesson(lessonId),
      parse: (data) =>
          FinanceMapper.learningLessonDetail(ApiClient.asMap(data)),
    );
  }

  Future<FinanceLearningLessonDetailEntity> completeLearningLesson(
    String lessonId,
  ) {
    return _client.post(
      ApiEndpoints.financeLearningComplete(lessonId),
      parse: (data) =>
          FinanceMapper.learningLessonDetail(ApiClient.asMap(data)),
    );
  }

  Future<List<FinanceLearningQuizQuestionEntity>> getLearningQuiz(
    String lessonId,
  ) {
    return _client.get(
      ApiEndpoints.financeLearningQuiz(lessonId),
      parse: (data) =>
          ApiClient.asList(data, FinanceMapper.learningQuizQuestion),
    );
  }

  Future<FinanceLearningQuizResultEntity> submitLearningQuiz({
    required String lessonId,
    required FinanceLearningQuizSubmitRequestModel request,
  }) {
    return _client.post(
      ApiEndpoints.financeLearningQuizSubmit(lessonId),
      body: request.toJson(),
      parse: (data) => FinanceMapper.learningQuizResult(ApiClient.asMap(data)),
    );
  }

  static Map<String, dynamic> _query(Map<String, dynamic> values) {
    values.removeWhere((_, value) => value == null);
    return values;
  }
}
