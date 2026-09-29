import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/productivity_entities.dart';
import '../../domain/repositories/productivity_repository.dart';

class ProductivityController extends GetxController {
  ProductivityController({required this.repository});

  final ProductivityRepository repository;

  final dashboard = Rxn<ProductivityDashboard>();
  final habits = <ProductivityHabit>[].obs;
  final tasks = <ProductivityTask>[].obs;
  final goals = <ProductivityGoal>[].obs;
  final focusStats = Rxn<ProductivityFocusStats>();
  final focusHistory = <ProductivityFocusSession>[].obs;
  final focusHistoryPage = (-1).obs;
  final focusHistoryHasMore = false.obs;
  final activeFocusSession = Rxn<ProductivityFocusSession>();
  final isFocusActionLoading = false.obs;
  final motivations = <ProductivityMotivation>[].obs;
  final savedMotivations = <ProductivityMotivation>[].obs;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isFocusHistoryLoading = false.obs;
  final errorMessage = RxnString();
  final busyIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _loadData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() async {
    if (isRefreshing.value || isLoading.value) return;
    isRefreshing.value = true;
    try {
      await _loadData();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _loadData() async {
    Object? firstError;

    Future<T?> read<T>(Future<T> Function() request) async {
      try {
        return await request();
      } catch (error) {
        firstError ??= error;
        return null;
      }
    }

    final results = await Future.wait<dynamic>([
      read(repository.getDashboard),
      read(repository.getHabits),
      read(repository.getTasks),
      read(repository.getGoals),
      read(repository.getFocusStats),
    ]);

    final loadedDashboard = results[0] as ProductivityDashboard?;
    final loadedHabits = results[1] as List<ProductivityHabit>?;
    final loadedTasks = results[2] as List<ProductivityTask>?;
    final loadedGoals = results[3] as List<ProductivityGoal>?;
    final loadedStats = results[4] as ProductivityFocusStats?;

    if (loadedDashboard != null) dashboard.value = loadedDashboard;
    if (loadedHabits != null) habits.assignAll(loadedHabits);
    if (loadedTasks != null) tasks.assignAll(loadedTasks);
    if (loadedGoals != null) goals.assignAll(loadedGoals);
    if (loadedStats != null) focusStats.value = loadedStats;

    if (loadedDashboard == null &&
        loadedHabits == null &&
        loadedTasks == null &&
        loadedGoals == null &&
        loadedStats == null) {
      errorMessage.value = _messageFor(firstError);
    } else {
      errorMessage.value = null;
    }
  }

  Future<ProductivityFocusStats?> refreshFocusStats() async {
    try {
      final stats = await repository.getFocusStats();
      focusStats.value = stats;
      _refreshDashboardSilently();
      return stats;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadFocusHistory({bool refresh = true}) async {
    if (isFocusHistoryLoading.value) return;
    if (!refresh && !focusHistoryHasMore.value) return;
    isFocusHistoryLoading.value = true;
    try {
      final nextPage = refresh ? 0 : focusHistoryPage.value + 1;
      final page = await repository.getFocusHistory(page: nextPage, size: 20);
      final completed = page.content.where((session) => session.isCompleted);
      final sessions = refresh
          ? <ProductivityFocusSession>[]
          : [...focusHistory];
      for (final session in completed) {
        final existingIndex = sessions.indexWhere(
          (item) => item.sessionId == session.sessionId,
        );
        if (existingIndex == -1) {
          sessions.add(session);
        } else {
          sessions[existingIndex] = session;
        }
      }
      sessions.sort(
        (a, b) =>
            (b.startedAt ?? DateTime(0)).compareTo(a.startedAt ?? DateTime(0)),
      );
      focusHistory.assignAll(sessions);
      focusHistoryPage.value = page.page;
      focusHistoryHasMore.value = page.hasNext;
    } finally {
      isFocusHistoryLoading.value = false;
    }
  }

  Future<void> loadNextFocusHistoryPage() => loadFocusHistory(refresh: false);

  Future<ProductivityFocusSession?> loadActiveFocusSession() async {
    final session = await repository.getActiveFocusSession();
    if (session == null || session.isCompleted || session.isAbandoned) {
      activeFocusSession.value = null;
      if (session?.isCompleted == true) _upsertFocusHistory(session!);
      return session;
    }
    activeFocusSession.value = session;
    return session;
  }

  Future<void> loadMotivation({String? category}) async {
    final items = await repository.getMotivation(category: category);
    motivations.assignAll(items);
  }

  Future<void> loadSavedMotivation() async {
    final items = await repository.getSavedMotivation();
    savedMotivations.assignAll(items);
  }

  Future<ProductivityHabit> createHabit({
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) async {
    final habit = await repository.createHabit(
      title: title,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
    );
    habits.insert(0, habit);
    await _refreshDashboardSilently();
    return habit;
  }

  Future<ProductivityHabit> updateHabit({
    required String habitId,
    required String title,
    String? category,
    String? frequency,
    String? reminderTime,
  }) async {
    final habit = await repository.updateHabit(
      habitId: habitId,
      title: title,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
    );
    _replaceHabit(habit);
    await _refreshDashboardSilently();
    return habit;
  }

  Future<void> deleteHabit(String habitId) async {
    await repository.deleteHabit(habitId);
    habits.removeWhere((habit) => habit.habitId == habitId);
    await _refreshDashboardSilently();
  }

  Future<ProductivityHabit> toggleHabit(
    String habitId, {
    required bool completed,
  }) async {
    if (!_beginBusy(habitId)) {
      return habits.firstWhere((habit) => habit.habitId == habitId);
    }

    final index = habits.indexWhere((habit) => habit.habitId == habitId);
    final previous = index == -1 ? null : habits[index];
    if (previous != null) {
      habits[index] = previous.copyWith(checkedInToday: completed);
    }

    try {
      final updated = await repository.checkInHabit(
        habitId,
        completed: completed,
      );
      _replaceHabit(updated);
      await _refreshDashboardSilently();
      return updated;
    } catch (_) {
      if (previous != null && index != -1) habits[index] = previous;
      rethrow;
    } finally {
      _endBusy(habitId);
    }
  }

  Future<ProductivityTask> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) async {
    final task = await repository.createTask(
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      reminderTime: reminderTime,
    );
    tasks.insert(0, task);
    await _refreshDashboardSilently();
    return task;
  }

  Future<ProductivityTask> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) async {
    final task = await repository.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      reminderTime: reminderTime,
    );
    _replaceTask(task);
    await _refreshDashboardSilently();
    return task;
  }

  Future<void> deleteTask(String taskId) async {
    await repository.deleteTask(taskId);
    tasks.removeWhere((task) => task.taskId == taskId);
    await _refreshDashboardSilently();
  }

  Future<ProductivityTask> loadTaskById(String taskId) async {
    final task = await repository.getTask(taskId);
    final index = tasks.indexWhere((item) => item.taskId == task.taskId);
    if (index == -1) {
      tasks.insert(0, task);
    } else {
      tasks[index] = task;
    }
    return task;
  }

  Future<ProductivityTask> toggleTask(
    String taskId, {
    required bool completed,
  }) async {
    if (!_beginBusy(taskId)) {
      return tasks.firstWhere((task) => task.taskId == taskId);
    }

    final index = tasks.indexWhere((task) => task.taskId == taskId);
    final previous = index == -1 ? null : tasks[index];
    if (previous != null) {
      tasks[index] = previous.copyWith(completed: completed, overdue: false);
    }

    try {
      final updated = await repository.setTaskCompleted(taskId, completed);
      _replaceTask(updated);
      await _refreshDashboardSilently();
      return updated;
    } catch (_) {
      if (previous != null && index != -1) tasks[index] = previous;
      rethrow;
    } finally {
      _endBusy(taskId);
    }
  }

  Future<ProductivityGoal> refreshGoal(String goalId) async {
    final goal = await repository.getGoal(goalId);
    _replaceGoal(goal);
    return goal;
  }

  Future<ProductivityGoal> createGoal({
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) async {
    final goal = await repository.createGoal(
      title: title,
      description: description,
      goalType: goalType,
      deadline: deadline,
    );
    goals.insert(0, goal);
    await _refreshDashboardSilently();
    return goal;
  }

  Future<ProductivityGoal> updateGoal({
    required String goalId,
    required String title,
    String? description,
    String? goalType,
    DateTime? deadline,
  }) async {
    final goal = await repository.updateGoal(
      goalId: goalId,
      title: title,
      description: description,
      goalType: goalType,
      deadline: deadline,
    );
    _replaceGoal(goal);
    await _refreshDashboardSilently();
    return goal;
  }

  Future<void> deleteGoal(String goalId) async {
    await repository.deleteGoal(goalId);
    goals.removeWhere((goal) => goal.goalId == goalId);
    await _refreshDashboardSilently();
  }

  Future<ProductivityGoal> addMilestone({
    required String goalId,
    required String title,
  }) async {
    final goal = await repository.addMilestone(goalId: goalId, title: title);
    _replaceGoal(goal);
    await _refreshDashboardSilently();
    return goal;
  }

  Future<ProductivityGoal> toggleMilestone({
    required String goalId,
    required String milestoneId,
    required bool completed,
  }) async {
    final goal = await repository.setMilestoneCompleted(
      goalId: goalId,
      milestoneId: milestoneId,
      completed: completed,
    );
    _replaceGoal(goal);
    await _refreshDashboardSilently();
    return goal;
  }

  Future<ProductivityGoal> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    final goal = await repository.deleteMilestone(
      goalId: goalId,
      milestoneId: milestoneId,
    );
    _replaceGoal(goal);
    await _refreshDashboardSilently();
    return goal;
  }

  Future<ProductivityFocusSession> startFocusSession({
    required String mode,
    required int durationMinutes,
    String? ambientSound,
  }) async {
    final existing = activeFocusSession.value;
    if (existing != null) return existing;
    const busyId = 'focus:start';
    if (!_beginBusy(busyId)) {
      throw StateError('A focus session is already starting.');
    }
    isFocusActionLoading.value = true;
    try {
      final session = await repository.startFocusSession(
        mode: mode,
        durationMinutes: durationMinutes,
        ambientSound: ambientSound,
      );
      if (session.isCompleted) {
        activeFocusSession.value = null;
        _upsertFocusHistory(session);
      } else {
        activeFocusSession.value = session;
      }
      return session;
    } finally {
      isFocusActionLoading.value = false;
      _endBusy(busyId);
    }
  }

  Future<ProductivityFocusSession> pauseFocusSession(String sessionId) async {
    final session = await _runFocusAction(
      'focus:pause:$sessionId',
      () => repository.pauseFocusSession(sessionId),
    );
    activeFocusSession.value = session;
    return session;
  }

  Future<ProductivityFocusSession> resumeFocusSession(String sessionId) async {
    final session = await _runFocusAction(
      'focus:resume:$sessionId',
      () => repository.resumeFocusSession(sessionId),
    );
    activeFocusSession.value = session;
    return session;
  }

  Future<ProductivityFocusSession> completeFocusSession(
    String sessionId,
  ) async {
    final session = await _runFocusAction(
      'focus:complete:$sessionId',
      () => repository.completeFocusSession(sessionId),
    );
    activeFocusSession.value = null;
    _upsertFocusHistory(session);
    await refreshFocusStats();
    return session;
  }

  Future<ProductivityFocusSession> abandonFocusSession(String sessionId) async {
    final session = await _runFocusAction(
      'focus:leave:$sessionId',
      () => repository.abandonFocusSession(sessionId),
    );
    activeFocusSession.value = null;
    if (session.isCompleted) _upsertFocusHistory(session);
    return session;
  }

  Future<ProductivityMotivation> saveMotivation(String motivationId) async {
    final motivation = await repository.saveMotivation(motivationId);
    _replaceMotivation(motivation);
    return motivation;
  }

  Future<ProductivityMotivation> unsaveMotivation(String motivationId) async {
    final motivation = await repository.unsaveMotivation(motivationId);
    _replaceMotivation(motivation);
    return motivation;
  }

  void clear() {
    dashboard.value = null;
    habits.clear();
    tasks.clear();
    goals.clear();
    focusStats.value = null;
    focusHistory.clear();
    focusHistoryPage.value = -1;
    focusHistoryHasMore.value = false;
    activeFocusSession.value = null;
    isFocusActionLoading.value = false;
    motivations.clear();
    savedMotivations.clear();
    errorMessage.value = null;
  }

  bool isBusy(String id) => busyIds.contains(id);

  bool _beginBusy(String id) {
    if (busyIds.contains(id)) return false;
    busyIds.add(id);
    return true;
  }

  void _endBusy(String id) {
    busyIds.remove(id);
  }

  Future<ProductivityFocusSession> _runFocusAction(
    String busyId,
    Future<ProductivityFocusSession> Function() action,
  ) async {
    if (!_beginBusy(busyId)) {
      throw StateError('This focus action is already in progress.');
    }
    isFocusActionLoading.value = true;
    try {
      return await action();
    } finally {
      isFocusActionLoading.value = false;
      _endBusy(busyId);
    }
  }

  void _upsertFocusHistory(ProductivityFocusSession session) {
    if (!session.isCompleted) return;
    final index = focusHistory.indexWhere(
      (item) => item.sessionId == session.sessionId,
    );
    if (index == -1) {
      focusHistory.insert(0, session);
    } else {
      focusHistory[index] = session;
    }
  }

  void _replaceHabit(ProductivityHabit habit) {
    final index = habits.indexWhere((item) => item.habitId == habit.habitId);
    if (index == -1) {
      habits.insert(0, habit);
    } else {
      habits[index] = habit;
    }
  }

  void _replaceTask(ProductivityTask task) {
    final index = tasks.indexWhere((item) => item.taskId == task.taskId);
    if (index == -1) {
      tasks.insert(0, task);
    } else {
      tasks[index] = task;
    }
  }

  void _replaceGoal(ProductivityGoal goal) {
    final index = goals.indexWhere((item) => item.goalId == goal.goalId);
    if (index == -1) {
      goals.insert(0, goal);
    } else {
      goals[index] = goal;
    }
  }

  void _replaceMotivation(ProductivityMotivation motivation) {
    final index = motivations.indexWhere(
      (item) => item.motivationId == motivation.motivationId,
    );
    if (index != -1) motivations[index] = motivation;

    final savedIndex = savedMotivations.indexWhere(
      (item) => item.motivationId == motivation.motivationId,
    );
    if (motivation.saved && savedIndex == -1) {
      savedMotivations.insert(0, motivation);
    } else if (!motivation.saved && savedIndex != -1) {
      savedMotivations.removeAt(savedIndex);
    } else if (savedIndex != -1) {
      savedMotivations[savedIndex] = motivation;
    }
  }

  Future<void> _refreshDashboardSilently() async {
    try {
      dashboard.value = await repository.getDashboard();
    } catch (_) {
      // The write already succeeded; a dashboard refresh is best effort.
    }
  }

  String _messageFor(Object? error) {
    if (error is AppError && error.message.isNotEmpty) return error.message;
    return 'Unable to load productivity data. Check your connection and try again.';
  }
}
