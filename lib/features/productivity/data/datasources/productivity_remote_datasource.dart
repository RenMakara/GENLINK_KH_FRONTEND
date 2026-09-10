import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/productivity_entities.dart';
import '../models/productivity_models.dart';

class ProductivityRemoteDatasource {
  const ProductivityRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ProductivityDashboard> getDashboard() {
    return _client.get(
      ApiEndpoints.mobileProductivityDashboard,
      parse: (data) => ProductivityMapper.dashboard(ApiClient.asMap(data)),
    );
  }

  Future<List<ProductivityHabit>> getHabits() {
    return _client.get(
      ApiEndpoints.habits,
      parse: (data) => ApiClient.asList(data, ProductivityMapper.habit),
    );
  }

  Future<ProductivityHabit> createHabit({
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) {
    return _client.post(
      ApiEndpoints.habits,
      body: _withoutNulls({
        'title': title,
        'category': category,
        'frequency': frequency,
        'reminderTime': reminderTime,
      }),
      parse: (data) => ProductivityMapper.habit(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityHabit> updateHabit({
    required String habitId,
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) {
    return _client.put(
      ApiEndpoints.habit(habitId),
      body: _withoutNulls({
        'title': title,
        'category': category,
        'frequency': frequency,
        'reminderTime': reminderTime,
      }),
      parse: (data) => ProductivityMapper.habit(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteHabit(String habitId) =>
      _client.delete(ApiEndpoints.habit(habitId));

  Future<ProductivityHabit> checkInHabit(
    String habitId, {
    required bool completed,
    DateTime? date,
  }) {
    return _client.post(
      ApiEndpoints.habitCheckIn(habitId),
      body: _withoutNulls({
        'date': date?.toIso8601String().split('T').first,
        'completed': completed,
      }),
      parse: (data) => ProductivityMapper.habit(ApiClient.asMap(data)),
    );
  }

  Future<List<ProductivityTask>> getTasks({
    String? category,
    String? priority,
    bool? completed,
    String? scope,
  }) {
    return _client.get(
      ApiEndpoints.tasks,
      query: _withoutNulls({
        'category': category,
        'priority': priority,
        'completed': completed,
        'scope': scope,
      }),
      parse: (data) => ApiClient.asList(data, ProductivityMapper.task),
    );
  }

  Future<ProductivityTask> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) {
    return _client.post(
      ApiEndpoints.tasks,
      body: _withoutNulls({
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'reminderTime': reminderTime?.toIso8601String(),
      }),
      parse: (data) => ProductivityMapper.task(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityTask> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) {
    return _client.put(
      ApiEndpoints.task(taskId),
      body: _withoutNulls({
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'reminderTime': reminderTime?.toIso8601String(),
      }),
      parse: (data) => ProductivityMapper.task(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteTask(String taskId) =>
      _client.delete(ApiEndpoints.task(taskId));

  Future<ProductivityTask> setTaskCompleted(String taskId, bool completed) {
    return _client.post(
      ApiEndpoints.taskComplete(taskId),
      query: {'completed': completed},
      parse: (data) => ProductivityMapper.task(ApiClient.asMap(data)),
    );
  }

  Future<List<ProductivityGoal>> getGoals() {
    return _client.get(
      ApiEndpoints.goals,
      parse: (data) => ApiClient.asList(data, ProductivityMapper.goal),
    );
  }

  Future<ProductivityGoal> getGoal(String goalId) {
    return _client.get(
      ApiEndpoints.goal(goalId),
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityGoal> createGoal({
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) {
    return _client.post(
      ApiEndpoints.goals,
      body: _withoutNulls({
        'title': title,
        'description': description,
        'goalType': goalType,
        'deadline': deadline?.toIso8601String().split('T').first,
      }),
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityGoal> updateGoal({
    required String goalId,
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) {
    return _client.put(
      ApiEndpoints.goal(goalId),
      body: _withoutNulls({
        'title': title,
        'description': description,
        'goalType': goalType,
        'deadline': deadline?.toIso8601String().split('T').first,
      }),
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteGoal(String goalId) =>
      _client.delete(ApiEndpoints.goal(goalId));

  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
  }) {
    return _client.post(
      ApiEndpoints.goalMilestones(goalId),
      body: {'title': title},
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityGoal> setMilestoneCompleted({
    required String goalId,
    required String milestoneId,
    required bool completed,
  }) {
    return _client.post(
      ApiEndpoints.goalMilestoneComplete(goalId, milestoneId),
      query: {'completed': completed},
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityGoal> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) {
    return _client.deleteWithResult(
      ApiEndpoints.goalMilestone(goalId, milestoneId),
      parse: (data) => ProductivityMapper.goal(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityFocusSession> startFocusSession({
    required String mode,
    required int durationMinutes,
    String? ambientSound,
  }) {
    return _client.post(
      ApiEndpoints.focusSessionStart,
      body: _withoutNulls({
        'mode': mode,
        'durationMinutes': durationMinutes,
        'ambientSound': ambientSound,
      }),
      parse: (data) => ProductivityMapper.focusSession(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityFocusSession> completeFocusSession(String sessionId) {
    return _client.post(
      ApiEndpoints.focusSessionComplete(sessionId),
      parse: (data) => ProductivityMapper.focusSession(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityPage<ProductivityFocusSession>> getFocusHistory({
    int page = 0,
    int size = 20,
  }) {
    return _client.get(
      ApiEndpoints.focusSessions,
      query: {'page': page, 'size': size},
      parse: (data) => ProductivityMapper.page(
        ApiClient.asMap(data),
        ProductivityMapper.focusSession,
      ),
    );
  }

  Future<ProductivityFocusStats> getFocusStats() {
    return _client.get(
      ApiEndpoints.focusSessionStats,
      parse: (data) => ProductivityMapper.focusStats(ApiClient.asMap(data)),
    );
  }

  Future<List<ProductivityMotivation>> getMotivation({String? category}) {
    return _client.get(
      ApiEndpoints.motivation,
      query: _withoutNulls({'category': category}),
      parse: (data) => ApiClient.asList(data, ProductivityMapper.motivation),
    );
  }

  Future<List<ProductivityMotivation>> getSavedMotivation() {
    return _client.get(
      ApiEndpoints.savedMotivation,
      parse: (data) => ApiClient.asList(data, ProductivityMapper.motivation),
    );
  }

  Future<ProductivityMotivation> saveMotivation(String motivationId) {
    return _client.post(
      ApiEndpoints.motivationSave(motivationId),
      parse: (data) => ProductivityMapper.motivation(ApiClient.asMap(data)),
    );
  }

  Future<ProductivityMotivation> unsaveMotivation(String motivationId) {
    return _client.deleteWithResult(
      ApiEndpoints.motivationSave(motivationId),
      parse: (data) => ProductivityMapper.motivation(ApiClient.asMap(data)),
    );
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
    values.removeWhere((_, value) => value == null);
    return values;
  }
}
