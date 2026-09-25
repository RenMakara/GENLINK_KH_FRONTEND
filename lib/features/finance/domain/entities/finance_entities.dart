enum FinanceCurrency { usd, khr }

extension FinanceCurrencyWire on FinanceCurrency {
  String get apiValue => switch (this) {
    FinanceCurrency.usd => 'USD',
    FinanceCurrency.khr => 'KHR',
  };
}

FinanceCurrency parseFinanceCurrency(Object? raw) {
  if (raw is String) {
    switch (raw.toUpperCase()) {
      case 'USD':
        return FinanceCurrency.usd;
      case 'KHR':
        return FinanceCurrency.khr;
    }
  }
  throw FormatException('Unknown finance currency: $raw');
}

class FinanceDashboardEntity {
  const FinanceDashboardEntity({
    required this.currency,
    required this.month,
    required this.topCategories,
    required this.saving,
    required this.recentExpenses,
    this.wallet,
    this.financialTip,
    this.quickActions = const [],
  });

  final FinanceCurrency currency;
  final FinanceMonthOverview month;
  final List<FinanceCategorySpend> topCategories;
  final FinanceSavingProgress saving;
  final List<FinanceRecentExpense> recentExpenses;
  final FinanceWalletSummary? wallet;
  final String? financialTip;
  final List<String> quickActions;
}

class FinanceMonthOverview {
  const FinanceMonthOverview({
    required this.month,
    required this.year,
    required this.currency,
    required this.spent,
    this.budgetTotal,
    this.budgetRemaining,
    this.budgetStatus,
  });

  final int month;
  final int year;
  final FinanceCurrency currency;
  final double spent;
  final double? budgetTotal;
  final double? budgetRemaining;
  final String? budgetStatus;
}

class FinanceCategorySpend {
  const FinanceCategorySpend({
    required this.category,
    required this.currency,
    required this.amount,
  });

  final String category;
  final FinanceCurrency currency;
  final double amount;
}

class FinanceSavingProgress {
  const FinanceSavingProgress({
    required this.currency,
    required this.totalTarget,
    required this.totalSaved,
    required this.progressPercent,
    required this.activeGoals,
  });

  final FinanceCurrency currency;
  final double totalTarget;
  final double totalSaved;
  final int progressPercent;
  final int activeGoals;
}

class FinanceRecentExpense {
  const FinanceRecentExpense({
    required this.expenseId,
    required this.title,
    this.category,
    required this.currency,
    required this.amount,
    required this.expenseDate,
  });

  final String expenseId;
  final String title;
  final String? category;
  final FinanceCurrency currency;
  final double amount;
  final String expenseDate;
}

class FinanceWalletSummary {
  const FinanceWalletSummary({
    required this.balanceUsd,
    required this.balanceKhr,
  });

  final double balanceUsd;
  final double balanceKhr;
}

class FinancePage<T> {
  const FinancePage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}

class FinanceExpenseEntity {
  const FinanceExpenseEntity({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.currency,
    this.category,
    this.description,
    required this.expenseDate,
    this.paymentMethod,
    required this.paidFromWallet,
    this.createdAt,
  });

  final String expenseId;
  final String title;
  final double amount;
  final FinanceCurrency currency;
  final String? category;
  final String? description;
  final String expenseDate;
  final String? paymentMethod;
  final bool paidFromWallet;
  final String? createdAt;
}

class FinanceIncomeEntity {
  const FinanceIncomeEntity({
    required this.incomeId,
    required this.title,
    required this.amount,
    required this.currency,
    this.source,
    this.description,
    required this.incomeDate,
    this.createdAt,
  });

  final String incomeId;
  final String title;
  final double amount;
  final FinanceCurrency currency;
  final String? source;
  final String? description;
  final String incomeDate;
  final String? createdAt;
}

class FinanceWalletEntity {
  const FinanceWalletEntity({
    required this.walletId,
    required this.balanceUsd,
    required this.balanceKhr,
  });

  final String walletId;
  final double balanceUsd;
  final double balanceKhr;
}

class FinanceWalletTransactionEntity {
  const FinanceWalletTransactionEntity({
    required this.transactionId,
    required this.transactionType,
    required this.direction,
    required this.currency,
    required this.amount,
    this.description,
    required this.status,
    this.createdAt,
    this.provider,
    this.providerRef,
  });

  final String transactionId;
  final String transactionType;
  final String direction;
  final FinanceCurrency currency;
  final double amount;
  final String? description;
  final String status;
  final String? createdAt;
  final String? provider;
  final String? providerRef;
}

class FinanceBudgetEntity {
  const FinanceBudgetEntity({
    required this.budgetId,
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.status,
    required this.currency,
    this.categories = const [],
  });

  final String budgetId;
  final int month;
  final int year;
  final double totalBudget;
  final double spentAmount;
  final double remainingAmount;
  final String status;
  final FinanceCurrency currency;
  final List<FinanceCategoryBudget> categories;
}

class FinanceBudgetAllocation {
  const FinanceBudgetAllocation({
    required this.category,
    required this.allocatedAmount,
  });

  final String category;
  final double allocatedAmount;
}

class FinanceCategoryBudget {
  const FinanceCategoryBudget({
    required this.category,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.remainingAmount,
  });

  final String category;
  final double allocatedAmount;
  final double spentAmount;
  final double remainingAmount;
}

class FinanceSavingGoalEntity {
  const FinanceSavingGoalEntity({
    required this.savingGoalId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.progressPercent,
    this.targetDate,
    required this.status,
    required this.currency,
  });

  final String savingGoalId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final int progressPercent;
  final String? targetDate;
  final String status;
  final FinanceCurrency currency;
}

class FinanceSavingDepositEntity {
  const FinanceSavingDepositEntity({
    required this.depositId,
    required this.amount,
    this.note,
    required this.depositDate,
  });

  final String depositId;
  final double amount;
  final String? note;
  final String depositDate;
}

class FinanceLearningDashboardEntity {
  const FinanceLearningDashboardEntity({
    required this.totalLessons,
    required this.completedLessons,
    required this.literacyXp,
    required this.topics,
  });

  final int totalLessons;
  final int completedLessons;
  final int literacyXp;
  final List<FinanceLearningTopicProgressEntity> topics;
}

class FinanceLearningTopicProgressEntity {
  const FinanceLearningTopicProgressEntity({
    required this.topic,
    required this.lessonCount,
    required this.completedCount,
  });

  final String topic;
  final int lessonCount;
  final int completedCount;
}

class FinanceLearningLessonSummaryEntity {
  const FinanceLearningLessonSummaryEntity({
    required this.lessonId,
    required this.title,
    required this.topic,
    required this.contentType,
    this.estimatedTime,
    required this.xpReward,
    required this.completed,
    required this.quizPassed,
  });

  final String lessonId;
  final String title;
  final String topic;
  final String contentType;
  final int? estimatedTime;
  final int xpReward;
  final bool completed;
  final bool quizPassed;
}

class FinanceLearningLessonDetailEntity {
  const FinanceLearningLessonDetailEntity({
    required this.lessonId,
    required this.title,
    required this.content,
    required this.topic,
    required this.contentType,
    this.mediaUrl,
    this.estimatedTime,
    required this.xpReward,
    required this.completed,
    required this.quizPassed,
    required this.questionCount,
  });

  final String lessonId;
  final String title;
  final String content;
  final String topic;
  final String contentType;
  final String? mediaUrl;
  final int? estimatedTime;
  final int xpReward;
  final bool completed;
  final bool quizPassed;
  final int questionCount;
}

class FinanceLearningQuizQuestionEntity {
  const FinanceLearningQuizQuestionEntity({
    required this.questionId,
    required this.questionText,
    required this.options,
  });

  final String questionId;
  final String questionText;
  final List<FinanceLearningQuizOptionEntity> options;
}

class FinanceLearningQuizOptionEntity {
  const FinanceLearningQuizOptionEntity({
    required this.key,
    required this.text,
  });

  final String key;
  final String text;
}

class FinanceLearningQuizAnswerEntity {
  const FinanceLearningQuizAnswerEntity({
    required this.questionId,
    required this.selectedOption,
  });

  final String questionId;
  final String selectedOption;
}

class FinanceLearningQuizResultEntity {
  const FinanceLearningQuizResultEntity({
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.passed,
    required this.xpEarned,
    required this.learningBudgetCredited,
    required this.results,
  });

  final int score;
  final int correctCount;
  final int totalQuestions;
  final bool passed;
  final int xpEarned;
  final double learningBudgetCredited;
  final List<FinanceLearningQuizQuestionResultEntity> results;
}

class FinanceLearningQuizQuestionResultEntity {
  const FinanceLearningQuizQuestionResultEntity({
    required this.questionId,
    this.selectedOption,
    this.correctOption,
    required this.correct,
    required this.explanation,
  });

  final String questionId;
  final String? selectedOption;
  final String? correctOption;
  final bool correct;
  final String explanation;
}

class FinanceMonthlySummaryEntity {
  const FinanceMonthlySummaryEntity({
    required this.month,
    required this.year,
    required this.currency,
    required this.total,
    this.byCategory = const [],
  });

  final int month;
  final int year;
  final FinanceCurrency currency;
  final double total;
  final List<FinanceCategoryTotal> byCategory;
}

class FinanceCategoryTotal {
  const FinanceCategoryTotal({required this.category, required this.total});

  final String category;
  final double total;
}

class FinanceCashFlowEntity {
  const FinanceCashFlowEntity({
    required this.currency,
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.savingsRatePercent,
  });

  final FinanceCurrency currency;
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final double savingsRatePercent;
}
