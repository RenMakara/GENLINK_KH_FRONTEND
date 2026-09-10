import '../../domain/entities/finance_entities.dart';

abstract final class FinanceMapper {
  static FinanceDashboardEntity dashboard(Map<String, dynamic> json) {
    return FinanceDashboardEntity(
      currency: parseFinanceCurrency(json['currency']),
      month: monthOverview(_map(json['month'])),
      topCategories: _list(json['topCategories'], categorySpend),
      saving: savingProgress(_map(json['saving'])),
      recentExpenses: _list(json['recentExpenses'], recentExpense),
      wallet: json['wallet'] == null
          ? null
          : walletSummary(_map(json['wallet'])),
      financialTip: json['financialTip'] as String?,
      quickActions: _strings(json['quickActions']),
    );
  }

  static FinanceMonthOverview monthOverview(Map<String, dynamic> json) {
    return FinanceMonthOverview(
      month: _requiredInt(json, 'month'),
      year: _requiredInt(json, 'year'),
      currency: parseFinanceCurrency(json['currency']),
      spent: _requiredDouble(json, 'spent'),
      budgetTotal: _double(json['budgetTotal']),
      budgetRemaining: _double(json['budgetRemaining']),
      budgetStatus: json['budgetStatus'] as String?,
    );
  }

  static FinanceCategorySpend categorySpend(Map<String, dynamic> json) {
    return FinanceCategorySpend(
      category: _requiredString(json, 'category'),
      currency: parseFinanceCurrency(json['currency']),
      amount: _requiredDouble(json, 'amount'),
    );
  }

  static FinanceSavingProgress savingProgress(Map<String, dynamic> json) {
    return FinanceSavingProgress(
      currency: parseFinanceCurrency(json['currency']),
      totalTarget: _requiredDouble(json, 'totalTarget'),
      totalSaved: _requiredDouble(json, 'totalSaved'),
      progressPercent: _requiredInt(json, 'progressPercent'),
      activeGoals: _requiredInt(json, 'activeGoals'),
    );
  }

  static FinanceRecentExpense recentExpense(Map<String, dynamic> json) {
    return FinanceRecentExpense(
      expenseId: _requiredString(json, 'expenseId'),
      title: _requiredString(json, 'title'),
      category: json['category'] as String?,
      currency: parseFinanceCurrency(json['currency']),
      amount: _requiredDouble(json, 'amount'),
      expenseDate: _requiredString(json, 'expenseDate'),
    );
  }

  static FinanceWalletSummary walletSummary(Map<String, dynamic> json) {
    return FinanceWalletSummary(
      balanceUsd: _requiredDouble(json, 'balanceUsd'),
      balanceKhr: _requiredDouble(json, 'balanceKhr'),
    );
  }

  static FinancePage<FinanceExpenseEntity> expensesPage(
    Map<String, dynamic> json,
  ) {
    return page(json, expense);
  }

  static FinancePage<FinanceIncomeEntity> incomesPage(
    Map<String, dynamic> json,
  ) {
    return page(json, income);
  }

  static FinancePage<FinanceBudgetEntity> budgetsPage(
    Map<String, dynamic> json,
  ) {
    return page(json, budget);
  }

  static FinancePage<T> page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    return FinancePage<T>(
      content: _list(json['content'], item),
      page: _requiredInt(json, 'page'),
      size: _requiredInt(json, 'size'),
      totalElements: _requiredInt(json, 'totalElements'),
      totalPages: _requiredInt(json, 'totalPages'),
      hasNext: _requiredBool(json, 'hasNext'),
    );
  }

  static FinanceExpenseEntity expense(Map<String, dynamic> json) {
    return FinanceExpenseEntity(
      expenseId: _requiredString(json, 'expenseId'),
      title: _requiredString(json, 'title'),
      amount: _requiredDouble(json, 'amount'),
      currency: parseFinanceCurrency(json['currency']),
      category: json['category'] as String?,
      description: json['description'] as String?,
      expenseDate: _requiredString(json, 'expenseDate'),
      paymentMethod: json['paymentMethod'] as String?,
      paidFromWallet: _requiredBool(json, 'paidFromWallet'),
      createdAt: json['createdAt'] as String?,
    );
  }

  static FinanceIncomeEntity income(Map<String, dynamic> json) {
    return FinanceIncomeEntity(
      incomeId: _requiredString(json, 'incomeId'),
      title: _requiredString(json, 'title'),
      amount: _requiredDouble(json, 'amount'),
      currency: parseFinanceCurrency(json['currency']),
      source: json['source'] as String?,
      description: json['description'] as String?,
      incomeDate: _requiredString(json, 'incomeDate'),
      createdAt: json['createdAt'] as String?,
    );
  }

  static FinanceWalletEntity wallet(Map<String, dynamic> json) {
    return FinanceWalletEntity(
      walletId: _requiredString(json, 'walletId'),
      balanceUsd: _requiredDouble(json, 'balanceUsd'),
      balanceKhr: _requiredDouble(json, 'balanceKhr'),
    );
  }

  static FinanceWalletTransactionEntity walletTransaction(
    Map<String, dynamic> json,
  ) {
    return FinanceWalletTransactionEntity(
      transactionId: _requiredString(json, 'transactionId'),
      transactionType: _requiredString(json, 'transactionType'),
      direction: _requiredString(json, 'direction'),
      currency: parseFinanceCurrency(json['currency']),
      amount: _requiredDouble(json, 'amount'),
      description: json['description'] as String?,
      status: _requiredString(json, 'status'),
      createdAt: json['createdAt'] as String?,
      provider: json['provider'] as String?,
      providerRef: json['providerRef'] as String?,
    );
  }

  static FinanceBudgetEntity budget(Map<String, dynamic> json) {
    return FinanceBudgetEntity(
      budgetId: _requiredString(json, 'budgetId'),
      month: _requiredInt(json, 'month'),
      year: _requiredInt(json, 'year'),
      totalBudget: _requiredDouble(json, 'totalBudget'),
      spentAmount: _requiredDouble(json, 'spentAmount'),
      remainingAmount: _requiredDouble(json, 'remainingAmount'),
      status: _requiredString(json, 'status'),
      currency: parseFinanceCurrency(json['currency']),
      categories: _list(json['categories'], categoryBudget),
    );
  }

  static FinanceCategoryBudget categoryBudget(Map<String, dynamic> json) {
    return FinanceCategoryBudget(
      category: _requiredString(json, 'category'),
      allocatedAmount: _requiredDouble(json, 'allocatedAmount'),
      spentAmount: _requiredDouble(json, 'spentAmount'),
      remainingAmount: _requiredDouble(json, 'remainingAmount'),
    );
  }

  static FinanceSavingGoalEntity savingGoal(Map<String, dynamic> json) {
    return FinanceSavingGoalEntity(
      savingGoalId: _requiredString(json, 'savingGoalId'),
      title: _requiredString(json, 'title'),
      targetAmount: _requiredDouble(json, 'targetAmount'),
      currentAmount: _requiredDouble(json, 'currentAmount'),
      remainingAmount: _requiredDouble(json, 'remainingAmount'),
      progressPercent: _requiredInt(json, 'progressPercent'),
      targetDate: json['targetDate'] as String?,
      status: _requiredString(json, 'status'),
      currency: parseFinanceCurrency(json['currency']),
    );
  }

  static FinanceSavingDepositEntity savingDeposit(Map<String, dynamic> json) {
    return FinanceSavingDepositEntity(
      depositId: _requiredString(json, 'depositId'),
      amount: _requiredDouble(json, 'amount'),
      note: json['note'] as String?,
      depositDate: _requiredString(json, 'depositDate'),
    );
  }

  static FinanceLearningDashboardEntity learningDashboard(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningDashboardEntity(
      totalLessons: _requiredInt(json, 'totalLessons'),
      completedLessons: _requiredInt(json, 'completedLessons'),
      literacyXp: _requiredInt(json, 'literacyXp'),
      topics: _list(json['topics'], learningTopicProgress),
    );
  }

  static FinanceLearningTopicProgressEntity learningTopicProgress(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningTopicProgressEntity(
      topic: _requiredString(json, 'topic'),
      lessonCount: _requiredInt(json, 'lessonCount'),
      completedCount: _requiredInt(json, 'completedCount'),
    );
  }

  static FinanceLearningLessonSummaryEntity learningLessonSummary(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningLessonSummaryEntity(
      lessonId: _requiredString(json, 'lessonId'),
      title: _requiredString(json, 'title'),
      topic: _requiredString(json, 'topic'),
      contentType: _requiredString(json, 'contentType'),
      estimatedTime: _nullableInt(json['estimatedTime']),
      xpReward: _requiredInt(json, 'xpReward'),
      completed: _requiredBool(json, 'completed'),
      quizPassed: _requiredBool(json, 'quizPassed'),
    );
  }

  static FinanceLearningLessonDetailEntity learningLessonDetail(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningLessonDetailEntity(
      lessonId: _requiredString(json, 'lessonId'),
      title: _requiredString(json, 'title'),
      content: _requiredString(json, 'content'),
      topic: _requiredString(json, 'topic'),
      contentType: _requiredString(json, 'contentType'),
      mediaUrl: json['mediaUrl'] as String?,
      estimatedTime: _nullableInt(json['estimatedTime']),
      xpReward: _requiredInt(json, 'xpReward'),
      completed: _requiredBool(json, 'completed'),
      quizPassed: _requiredBool(json, 'quizPassed'),
      questionCount: _requiredInt(json, 'questionCount'),
    );
  }

  static FinanceLearningQuizQuestionEntity learningQuizQuestion(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningQuizQuestionEntity(
      questionId: _requiredString(json, 'questionId'),
      questionText: _requiredString(json, 'questionText'),
      options: _list(json['options'], learningQuizOption),
    );
  }

  static FinanceLearningQuizOptionEntity learningQuizOption(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningQuizOptionEntity(
      key: _requiredString(json, 'key'),
      text: _requiredString(json, 'text'),
    );
  }

  static FinanceLearningQuizResultEntity learningQuizResult(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningQuizResultEntity(
      score: _requiredInt(json, 'score'),
      correctCount: _requiredInt(json, 'correctCount'),
      totalQuestions: _requiredInt(json, 'totalQuestions'),
      passed: _requiredBool(json, 'passed'),
      xpEarned: _requiredInt(json, 'xpEarned'),
      learningBudgetCredited: _requiredDouble(json, 'learningBudgetCredited'),
      results: _list(json['results'], learningQuizQuestionResult),
    );
  }

  static FinanceLearningQuizQuestionResultEntity learningQuizQuestionResult(
    Map<String, dynamic> json,
  ) {
    return FinanceLearningQuizQuestionResultEntity(
      questionId: _requiredString(json, 'questionId'),
      selectedOption: json['selectedOption'] as String?,
      correctOption: json['correctOption'] as String?,
      correct: _requiredBool(json, 'correct'),
      explanation: _requiredString(json, 'explanation'),
    );
  }

  static FinanceMonthlySummaryEntity monthlySummary(Map<String, dynamic> json) {
    return FinanceMonthlySummaryEntity(
      month: _requiredInt(json, 'month'),
      year: _requiredInt(json, 'year'),
      currency: parseFinanceCurrency(json['currency']),
      total: _requiredDouble(json, 'total'),
      byCategory: _list(json['byCategory'], categoryTotal),
    );
  }

  static FinanceCategoryTotal categoryTotal(Map<String, dynamic> json) {
    return FinanceCategoryTotal(
      category: _requiredString(json, 'category'),
      total: _requiredDouble(json, 'total'),
    );
  }

  static FinanceCashFlowEntity cashFlow(Map<String, dynamic> json) {
    return FinanceCashFlowEntity(
      currency: parseFinanceCurrency(json['currency']),
      month: _requiredInt(json, 'month'),
      year: _requiredInt(json, 'year'),
      totalIncome: _requiredDouble(json, 'totalIncome'),
      totalExpense: _requiredDouble(json, 'totalExpense'),
      net: _requiredDouble(json, 'net'),
      savingsRatePercent: _requiredDouble(json, 'savingsRatePercent'),
    );
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) item) {
    final list = raw as List? ?? const [];
    return list
        .map((value) => item((value as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  static List<String> _strings(dynamic raw) {
    final list = raw as List? ?? const [];
    return list.whereType<String>().toList(growable: false);
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      (raw as Map?)?.cast<String, dynamic>() ?? const {};

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Missing Finance field: $key');
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    throw FormatException('Missing Finance field: $key');
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Missing Finance field: $key');
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = _double(json[key]);
    if (value != null) return value;
    throw FormatException('Missing Finance field: $key');
  }

  static double? _double(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static int? _nullableInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    throw FormatException('Invalid Finance integer: $raw');
  }
}

class FinanceExpenseRequestModel {
  const FinanceExpenseRequestModel({
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.category,
    this.description,
    this.paymentMethod,
    this.paidFromWallet,
    this.currency,
  });

  final String title;
  final double amount;
  final String expenseDate;
  final String? category;
  final String? description;
  final String? paymentMethod;
  final bool? paidFromWallet;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'title': title,
    'amount': amount,
    'category': category,
    'description': description,
    'expenseDate': expenseDate,
    'paymentMethod': paymentMethod,
    'paidFromWallet': paidFromWallet,
    'currency': currency?.apiValue,
  });
}

class FinanceIncomeRequestModel {
  const FinanceIncomeRequestModel({
    required this.title,
    required this.amount,
    required this.incomeDate,
    this.source,
    this.description,
    this.currency,
  });

  final String title;
  final double amount;
  final String incomeDate;
  final String? source;
  final String? description;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'title': title,
    'amount': amount,
    'source': source,
    'description': description,
    'incomeDate': incomeDate,
    'currency': currency?.apiValue,
  });
}

class FinanceBudgetCategoryRequestModel {
  const FinanceBudgetCategoryRequestModel({
    required this.category,
    required this.allocatedAmount,
  });

  final String category;
  final double allocatedAmount;

  Map<String, dynamic> toJson() => {
    'category': category,
    'allocatedAmount': allocatedAmount,
  };
}

class FinanceBudgetRequestModel {
  const FinanceBudgetRequestModel({
    required this.month,
    required this.year,
    required this.totalBudget,
    this.categories,
    this.currency,
  });

  final int month;
  final int year;
  final double totalBudget;
  final List<FinanceBudgetCategoryRequestModel>? categories;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'month': month,
    'year': year,
    'totalBudget': totalBudget,
    'categories': categories?.map((category) => category.toJson()).toList(),
    'currency': currency?.apiValue,
  });
}

class FinanceSavingGoalRequestModel {
  const FinanceSavingGoalRequestModel({
    required this.title,
    required this.targetAmount,
    this.targetDate,
    this.currency,
  });

  final String title;
  final double targetAmount;
  final String? targetDate;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'title': title,
    'targetAmount': targetAmount,
    'targetDate': targetDate,
    'currency': currency?.apiValue,
  });
}

class FinanceSavingDepositRequestModel {
  const FinanceSavingDepositRequestModel({
    required this.amount,
    this.note,
    this.depositDate,
    this.fromWallet,
  });

  final double amount;
  final String? note;
  final String? depositDate;
  final bool? fromWallet;

  Map<String, dynamic> toJson() => _withoutNulls({
    'amount': amount,
    'note': note,
    'depositDate': depositDate,
    'fromWallet': fromWallet,
  });
}

class FinanceLearningQuizAnswerRequestModel {
  const FinanceLearningQuizAnswerRequestModel({
    required this.questionId,
    required this.selectedOption,
  });

  final String questionId;
  final String selectedOption;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedOption': selectedOption,
  };
}

class FinanceLearningQuizSubmitRequestModel {
  const FinanceLearningQuizSubmitRequestModel({required this.answers});

  final List<FinanceLearningQuizAnswerRequestModel> answers;

  Map<String, dynamic> toJson() => {
    'answers': answers.map((answer) => answer.toJson()).toList(growable: false),
  };
}

class FinanceWalletTopUpRequestModel {
  const FinanceWalletTopUpRequestModel({
    required this.amount,
    this.note,
    this.currency,
  });

  final double amount;
  final String? note;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'amount': amount,
    'note': note,
    'currency': currency?.apiValue,
  });
}

class FinanceWalletPaymentRequestModel {
  const FinanceWalletPaymentRequestModel({
    required this.amount,
    this.merchant,
    this.note,
    this.currency,
  });

  final double amount;
  final String? merchant;
  final String? note;
  final FinanceCurrency? currency;

  Map<String, dynamic> toJson() => _withoutNulls({
    'amount': amount,
    'merchant': merchant,
    'note': note,
    'currency': currency?.apiValue,
  });
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> body) {
  body.removeWhere((_, value) => value == null);
  return body;
}
