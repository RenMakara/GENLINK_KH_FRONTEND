import '../../domain/entities/productivity_entities.dart';
import '../../domain/repositories/productivity_repository.dart';
import '../datasources/productivity_remote_datasource.dart';

class ProductivityRepositoryImpl implements ProductivityRepository {
  const ProductivityRepositoryImpl(this._remote);

  final ProductivityRemoteDatasource _remote;

  @override
  Future<ProductivityDashboard> getDashboard() => _remote.getDashboard();

  @override
  Future<List<ProductivityHabit>> getHabits() => _remote.getHabits();

  @override
  Future<ProductivityHabit> createHabit({
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) => _remote.createHabit(
    title: title,
    category: category,
    frequency: frequency,
    reminderTime: reminderTime,
  );

  @override
  Future<ProductivityHabit> updateHabit({
    required String habitId,
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) => _remote.updateHabit(
    habitId: habitId,
    title: title,
    category: category,
    frequency: frequency,
    reminderTime: reminderTime,
  );

  @override
  Future<void> deleteHabit(String habitId) => _remote.deleteHabit(habitId);

  @override
  Future<ProductivityHabit> checkInHabit(
    String habitId, {
    required bool completed,
    DateTime? date,
  }) => _remote.checkInHabit(habitId, completed: completed, date: date);

  @override
  Future<List<ProductivityTask>> getTasks({
    String? category,
    String? priority,
    bool? completed,
    String? scope,
  }) => _remote.getTasks(
    category: category,
    priority: priority,
    completed: completed,
    scope: scope,
  );

  @override
  Future<ProductivityTask> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) => _remote.createTask(
    title: title,
    description: description,
    priority: priority,
    category: category,
    dueDate: dueDate,
    reminderTime: reminderTime,
  );

  @override
  Future<ProductivityTask> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) => _remote.updateTask(
    taskId: taskId,
    title: title,
    description: description,
    priority: priority,
    category: category,
    dueDate: dueDate,
    reminderTime: reminderTime,
  );

  @override
  Future<void> deleteTask(String taskId) => _remote.deleteTask(taskId);

  @override
  Future<ProductivityTask> setTaskCompleted(String taskId, bool completed) =>
      _remote.setTaskCompleted(taskId, completed);

  @override
  Future<List<ProductivityGoal>> getGoals() => _remote.getGoals();

  @override
  Future<ProductivityGoal> getGoal(String goalId) => _remote.getGoal(goalId);

  @override
  Future<ProductivityGoal> createGoal({
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) => _remote.createGoal(
    title: title,
    description: description,
    goalType: goalType,
    deadline: deadline,
  );

  @override
  Future<ProductivityGoal> updateGoal({
    required String goalId,
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) => _remote.updateGoal(
    goalId: goalId,
    title: title,
    description: description,
    goalType: goalType,
    deadline: deadline,
  );

  @override
  Future<void> deleteGoal(String goalId) => _remote.deleteGoal(goalId);

  @override
  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
  }) => _remote.addMilestone(goalId: goalId, title: title);

  @override
  Future<ProductivityGoal> setMilestoneCompleted({
    required String goalId,
    required String milestoneId,
    required bool completed,
  }) => _remote.setMilestoneCompleted(
    goalId: goalId,
    milestoneId: milestoneId,
    completed: completed,
  );

  @override
  Future<ProductivityGoal> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) => _remote.deleteMilestone(goalId: goalId, milestoneId: milestoneId);

  @override
  Future<ProductivityFocusSession> startFocusSession({
    required String mode,
    required int durationMinutes,
    String? ambientSound,
  }) => _remote.startFocusSession(
    mode: mode,
    durationMinutes: durationMinutes,
    ambientSound: ambientSound,
  );

  @override
  Future<ProductivityFocusSession?> getActiveFocusSession() =>
      _remote.getActiveFocusSession();

  @override
  Future<ProductivityFocusSession> pauseFocusSession(String sessionId) =>
      _remote.pauseFocusSession(sessionId);

  @override
  Future<ProductivityFocusSession> resumeFocusSession(String sessionId) =>
      _remote.resumeFocusSession(sessionId);

  @override
  Future<ProductivityFocusSession> completeFocusSession(String sessionId) =>
      _remote.completeFocusSession(sessionId);

  @override
  Future<ProductivityFocusSession> abandonFocusSession(String sessionId) =>
      _remote.abandonFocusSession(sessionId);

  @override
  Future<ProductivityPage<ProductivityFocusSession>> getFocusHistory({
    int page = 0,
    int size = 20,
  }) => _remote.getFocusHistory(page: page, size: size);

  @override
  Future<ProductivityFocusStats> getFocusStats() => _remote.getFocusStats();

  @override
  Future<List<ProductivityMotivation>> getMotivation({String? category}) =>
      _remote.getMotivation(category: category);

  @override
  Future<List<ProductivityMotivation>> getSavedMotivation() =>
      _remote.getSavedMotivation();

  @override
  Future<ProductivityMotivation> saveMotivation(String motivationId) =>
      _remote.saveMotivation(motivationId);

  @override
  Future<ProductivityMotivation> unsaveMotivation(String motivationId) =>
      _remote.unsaveMotivation(motivationId);
}
