import '../../domain/entities/productivity_entities.dart';

/// JSON mappers for the Productivity REST and BFF contracts.
///
/// The backend uses Java time values and BigDecimal values. Keeping the
/// coercion here means screens never need to know whether a number arrived as
/// an int, a double, or a JSON string.
abstract final class ProductivityMapper {
  const ProductivityMapper._();

  static ProductivityDashboard dashboard(Map<String, dynamic> json) {
    return ProductivityDashboard(
      habits: habitsToday(_map(json['habits'])),
      tasks: tasksSummary(_map(json['tasks'])),
      goals: _list(json['goals'], goalProgress),
      focus: focusSummary(_map(json['focus'])),
      motivation: json['motivation'] == null
          ? null
          : motivationCard(_map(json['motivation'])),
    );
  }

  static ProductivityHabitsToday habitsToday(Map<String, dynamic> json) {
    return ProductivityHabitsToday(
      total: _int(json['total']),
      checkedInToday: _int(json['checkedInToday']),
      items: _list(json['items'], habitItem),
    );
  }

  static ProductivityHabitItem habitItem(Map<String, dynamic> json) {
    return ProductivityHabitItem(
      habitId: _string(json['habitId'] ?? json['id']),
      title: _string(json['title']),
      checkedInToday: _bool(json['checkedInToday']),
    );
  }

  static ProductivityTasksSummary tasksSummary(Map<String, dynamic> json) {
    return ProductivityTasksSummary(
      total: _int(json['total']),
      completed: _int(json['completed']),
      dueToday: _int(json['dueToday']),
      overdue: _int(json['overdue']),
    );
  }

  static ProductivityGoalProgress goalProgress(Map<String, dynamic> json) {
    return ProductivityGoalProgress(
      goalId: _string(json['goalId'] ?? json['id']),
      title: _string(json['title']),
      progressPercentage: _double(json['progressPercentage']),
      status: _string(json['status'], fallback: 'NOT_STARTED'),
    );
  }

  static ProductivityFocusSummary focusSummary(Map<String, dynamic> json) {
    return ProductivityFocusSummary(
      todaySessions: _int(json['todaySessions']),
      todayMinutes: _int(json['todayMinutes']),
      totalXp: _int(json['totalXp']),
    );
  }

  static ProductivityMotivationCard motivationCard(Map<String, dynamic> json) {
    return ProductivityMotivationCard(
      motivationId: _string(json['motivationId'] ?? json['id']),
      title: _string(json['title']),
      content: _string(json['content']),
    );
  }

  static ProductivityHabit habit(Map<String, dynamic> json) {
    return ProductivityHabit(
      habitId: _string(json['habitId'] ?? json['id']),
      title: _string(json['title']),
      category: _nullableString(json['category']),
      frequency: _nullableString(json['frequency']),
      reminderTime: _nullableString(json['reminderTime']),
      streakCount: _int(json['streakCount']),
      completionRate: _double(json['completionRate']),
      checkedInToday: _bool(json['checkedInToday']),
    );
  }

  static ProductivityTask task(Map<String, dynamic> json) {
    return ProductivityTask(
      taskId: _string(json['taskId'] ?? json['id']),
      title: _string(json['title']),
      description: _nullableString(json['description']),
      priority: _nullableString(json['priority']),
      category: _nullableString(json['category']),
      dueDate: _date(json['dueDate']),
      reminderTime: _date(json['reminderTime']),
      completed: _bool(json['completed']),
      overdue: _bool(json['overdue']),
    );
  }

  static ProductivityGoal goal(Map<String, dynamic> json) {
    return ProductivityGoal(
      goalId: _string(json['goalId'] ?? json['id']),
      title: _string(json['title']),
      description: _nullableString(json['description']),
      goalType: _nullableString(json['goalType']),
      deadline: _date(json['deadline']),
      progressPercentage: _double(json['progressPercentage']),
      status: _string(json['status'], fallback: 'NOT_STARTED'),
      totalMilestones: _int(json['totalMilestones']),
      completedMilestones: _int(json['completedMilestones']),
      milestones: _list(json['milestones'], milestone),
    );
  }

  static ProductivityMilestone milestone(Map<String, dynamic> json) {
    return ProductivityMilestone(
      milestoneId: _string(json['milestoneId'] ?? json['id']),
      title: _string(json['title']),
      completed: _bool(json['completed']),
      completedAt: _date(json['completedAt']),
    );
  }

  static ProductivityFocusSession focusSession(Map<String, dynamic> json) {
    return ProductivityFocusSession(
      sessionId: _string(json['sessionId'] ?? json['id']),
      mode: _nullableString(json['mode']),
      durationMinutes: _int(json['durationMinutes']),
      ambientSound: _nullableString(json['ambientSound']),
      status: _string(
        json['status'],
        fallback: json['completed'] == true ? 'COMPLETED' : 'ACTIVE',
      ),
      completed: _bool(json['completed']),
      xpEarned: _int(json['xpEarned']),
      focusedSeconds: _int(json['focusedSeconds']),
      remainingSeconds: _int(json['remainingSeconds']),
      startedAt: _date(json['startedAt']),
      activeStartedAt: _date(json['activeStartedAt']),
      pausedAt: _date(json['pausedAt']),
      endedAt: _date(json['endedAt']),
    );
  }

  static ProductivityFocusStats focusStats(Map<String, dynamic> json) {
    return ProductivityFocusStats(
      todaySessions: _int(json['todaySessions']),
      todayMinutes: _int(json['todayMinutes']),
      totalSessions: _int(json['totalSessions']),
      totalMinutes: _int(json['totalMinutes']),
      totalXp: _int(json['totalXp']),
    );
  }

  static ProductivityMotivation motivation(Map<String, dynamic> json) {
    return ProductivityMotivation(
      motivationId: _string(json['motivationId'] ?? json['id']),
      title: _string(json['title']),
      content: _string(json['content']),
      category: _nullableString(json['category']),
      savedCount: _int(json['savedCount']),
      saved: _bool(json['saved']),
    );
  }

  static ProductivityPage<T> page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    return ProductivityPage<T>(
      content: _list(json['content'], item),
      page: _int(json['page']),
      size: _int(json['size']),
      totalElements: _int(json['totalElements']),
      totalPages: _int(json['totalPages']),
      hasNext: _bool(json['hasNext']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      (value as Map?)?.cast<String, dynamic>() ?? const {};

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final values = value is List ? value : const <dynamic>[];
    return values
        .whereType<Map>()
        .map((item) => mapper(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value is String ? value : value?.toString() ?? fallback;

  static String? _nullableString(dynamic value) {
    final result = value?.toString();
    return result == null || result.isEmpty ? null : result;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
