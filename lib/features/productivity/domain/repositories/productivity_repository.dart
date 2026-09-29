import '../entities/productivity_entities.dart';

abstract class ProductivityRepository {
  Future<ProductivityDashboard> getDashboard();

  Future<List<ProductivityHabit>> getHabits();
  Future<ProductivityHabit> createHabit({
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  });
  Future<ProductivityHabit> updateHabit({
    required String habitId,
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  });
  Future<void> deleteHabit(String habitId);
  Future<ProductivityHabit> checkInHabit(
    String habitId, {
    required bool completed,
    DateTime? date,
  });

  Future<List<ProductivityTask>> getTasks({
    String? category,
    String? priority,
    bool? completed,
    String? scope,
  });
  Future<ProductivityTask> getTask(String taskId);
  Future<ProductivityTask> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  });
  Future<ProductivityTask> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  });
  Future<void> deleteTask(String taskId);
  Future<ProductivityTask> setTaskCompleted(String taskId, bool completed);

  Future<List<ProductivityGoal>> getGoals();
  Future<ProductivityGoal> getGoal(String goalId);
  Future<ProductivityGoal> createGoal({
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  });
  Future<ProductivityGoal> updateGoal({
    required String goalId,
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  });
  Future<void> deleteGoal(String goalId);
  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
  });
  Future<ProductivityGoal> setMilestoneCompleted({
    required String goalId,
    required String milestoneId,
    required bool completed,
  });
  Future<ProductivityGoal> deleteMilestone({
    required String goalId,
    required String milestoneId,
  });

  Future<ProductivityFocusSession> startFocusSession({
    required String mode,
    required int durationMinutes,
    String? ambientSound,
  });
  Future<ProductivityFocusSession?> getActiveFocusSession();
  Future<ProductivityFocusSession> pauseFocusSession(String sessionId);
  Future<ProductivityFocusSession> resumeFocusSession(String sessionId);
  Future<ProductivityFocusSession> completeFocusSession(String sessionId);
  Future<ProductivityFocusSession> abandonFocusSession(String sessionId);
  Future<ProductivityPage<ProductivityFocusSession>> getFocusHistory({
    int page = 0,
    int size = 20,
  });
  Future<ProductivityFocusStats> getFocusStats();

  Future<List<ProductivityMotivation>> getMotivation({String? category});
  Future<List<ProductivityMotivation>> getSavedMotivation();
  Future<ProductivityMotivation> saveMotivation(String motivationId);
  Future<ProductivityMotivation> unsaveMotivation(String motivationId);
}
