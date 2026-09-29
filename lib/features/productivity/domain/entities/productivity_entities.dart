class ProductivityDashboard {
  const ProductivityDashboard({
    required this.habits,
    required this.tasks,
    required this.goals,
    required this.focus,
    this.motivation,
  });

  final ProductivityHabitsToday habits;
  final ProductivityTasksSummary tasks;
  final List<ProductivityGoalProgress> goals;
  final ProductivityFocusSummary focus;
  final ProductivityMotivationCard? motivation;
}

class ProductivityHabitsToday {
  const ProductivityHabitsToday({
    required this.total,
    required this.checkedInToday,
    this.items = const [],
  });

  final int total;
  final int checkedInToday;
  final List<ProductivityHabitItem> items;

  double get progress =>
      total <= 0 ? 0 : (checkedInToday / total).clamp(0.0, 1.0);
}

class ProductivityHabitItem {
  const ProductivityHabitItem({
    required this.habitId,
    required this.title,
    required this.checkedInToday,
  });

  final String habitId;
  final String title;
  final bool checkedInToday;
}

class ProductivityTasksSummary {
  const ProductivityTasksSummary({
    required this.total,
    required this.completed,
    required this.dueToday,
    required this.overdue,
  });

  final int total;
  final int completed;
  final int dueToday;
  final int overdue;

  double get progress => total <= 0 ? 0 : (completed / total).clamp(0.0, 1.0);
}

class ProductivityGoalProgress {
  const ProductivityGoalProgress({
    required this.goalId,
    required this.title,
    required this.progressPercentage,
    required this.status,
  });

  final String goalId;
  final String title;
  final double progressPercentage;
  final String status;
}

class ProductivityFocusSummary {
  const ProductivityFocusSummary({
    required this.todaySessions,
    required this.todayMinutes,
    required this.totalXp,
  });

  final int todaySessions;
  final int todayMinutes;
  final int totalXp;
}

class ProductivityMotivationCard {
  const ProductivityMotivationCard({
    required this.motivationId,
    required this.title,
    required this.content,
  });

  final String motivationId;
  final String title;
  final String content;
}

class ProductivityHabit {
  const ProductivityHabit({
    required this.habitId,
    required this.title,
    this.category,
    this.frequency,
    this.reminderTime,
    this.streakCount = 0,
    this.completionRate = 0,
    this.checkedInToday = false,
    this.checkedInThisWeek = false,
    this.xpEarned = 0,
  });

  final String habitId;
  final String title;
  final String? category;
  final String? frequency;
  final String? reminderTime;
  final int streakCount;
  final double completionRate;
  final bool checkedInToday;
  final bool checkedInThisWeek;
  final int xpEarned;

  ProductivityHabit copyWith({
    String? title,
    String? category,
    String? frequency,
    String? reminderTime,
    int? streakCount,
    double? completionRate,
    bool? checkedInToday,
    bool? checkedInThisWeek,
    int? xpEarned,
  }) {
    return ProductivityHabit(
      habitId: habitId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      streakCount: streakCount ?? this.streakCount,
      completionRate: completionRate ?? this.completionRate,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      checkedInThisWeek: checkedInThisWeek ?? this.checkedInThisWeek,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

class ProductivityTask {
  const ProductivityTask({
    required this.taskId,
    required this.title,
    this.description,
    this.priority,
    this.category,
    this.dueDate,
    this.reminderTime,
    this.completed = false,
    this.overdue = false,
    this.xpEarned = 0,
  });

  final String taskId;
  final String title;
  final String? description;
  final String? priority;
  final String? category;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final bool completed;
  final bool overdue;
  final int xpEarned;

  ProductivityTask copyWith({
    String? title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
    bool? completed,
    bool? overdue,
    int? xpEarned,
  }) {
    return ProductivityTask(
      taskId: taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      completed: completed ?? this.completed,
      overdue: overdue ?? this.overdue,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

class ProductivityGoal {
  const ProductivityGoal({
    required this.goalId,
    required this.title,
    this.description,
    this.goalType,
    this.deadline,
    this.progressPercentage = 0,
    this.status = 'NOT_STARTED',
    this.totalMilestones = 0,
    this.completedMilestones = 0,
    this.milestones = const [],
  });

  final String goalId;
  final String title;
  final String? description;
  final String? goalType;
  final DateTime? deadline;
  final double progressPercentage;
  final String status;
  final int totalMilestones;
  final int completedMilestones;
  final List<ProductivityMilestone> milestones;

  ProductivityGoal copyWith({
    String? title,
    String? description,
    String? goalType,
    DateTime? deadline,
    double? progressPercentage,
    String? status,
    int? totalMilestones,
    int? completedMilestones,
    List<ProductivityMilestone>? milestones,
  }) {
    return ProductivityGoal(
      goalId: goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      deadline: deadline ?? this.deadline,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      totalMilestones: totalMilestones ?? this.totalMilestones,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      milestones: milestones ?? this.milestones,
    );
  }
}

class ProductivityMilestone {
  const ProductivityMilestone({
    required this.milestoneId,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  final String milestoneId;
  final String title;
  final bool completed;
  final DateTime? completedAt;

  ProductivityMilestone copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
  }) {
    return ProductivityMilestone(
      milestoneId: milestoneId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ProductivityFocusSession {
  const ProductivityFocusSession({
    required this.sessionId,
    this.mode,
    this.durationMinutes = 0,
    this.ambientSound,
    this.status = 'ACTIVE',
    this.completed = false,
    this.xpEarned = 0,
    this.focusedSeconds = 0,
    this.remainingSeconds = 0,
    this.startedAt,
    this.activeStartedAt,
    this.pausedAt,
    this.endedAt,
  });

  final String sessionId;
  final String? mode;
  final int durationMinutes;
  final String? ambientSound;
  final String status;
  final bool completed;
  final int xpEarned;
  final int focusedSeconds;
  final int remainingSeconds;
  final DateTime? startedAt;
  final DateTime? activeStartedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;

  bool get isActive => status == 'ACTIVE';
  bool get isPaused => status == 'PAUSED';
  bool get isCompleted => status == 'COMPLETED' || completed;
  bool get isAbandoned => status == 'ABANDONED';
}

class ProductivityFocusStats {
  const ProductivityFocusStats({
    required this.todaySessions,
    required this.todayMinutes,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalXp,
  });

  final int todaySessions;
  final int todayMinutes;
  final int totalSessions;
  final int totalMinutes;
  final int totalXp;
}

class ProductivityMotivation {
  const ProductivityMotivation({
    required this.motivationId,
    required this.title,
    required this.content,
    this.category,
    this.savedCount = 0,
    this.saved = false,
  });

  final String motivationId;
  final String title;
  final String content;
  final String? category;
  final int savedCount;
  final bool saved;

  ProductivityMotivation copyWith({
    String? title,
    String? content,
    String? category,
    int? savedCount,
    bool? saved,
  }) {
    return ProductivityMotivation(
      motivationId: motivationId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      savedCount: savedCount ?? this.savedCount,
      saved: saved ?? this.saved,
    );
  }
}

class ProductivityPage<T> {
  const ProductivityPage({
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
