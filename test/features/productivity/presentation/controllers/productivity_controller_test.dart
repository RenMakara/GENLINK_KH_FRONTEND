import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/domain/repositories/productivity_repository.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductivityRepository extends Mock
    implements ProductivityRepository {}

const _dashboard = ProductivityDashboard(
  habits: ProductivityHabitsToday(total: 1, checkedInToday: 0),
  tasks: ProductivityTasksSummary(
    total: 1,
    completed: 0,
    dueToday: 1,
    overdue: 0,
  ),
  goals: [],
  focus: ProductivityFocusSummary(
    todaySessions: 0,
    todayMinutes: 0,
    totalXp: 0,
  ),
);

ProductivityTask _task(
  String id, {
  String title = 'Task',
  bool completed = false,
  bool overdue = false,
}) {
  return ProductivityTask(
    taskId: id,
    title: title,
    completed: completed,
    overdue: overdue,
  );
}

ProductivityHabit _habit(
  String id, {
  String title = 'Habit',
  int streakCount = 0,
  bool checkedInToday = false,
}) {
  return ProductivityHabit(
    habitId: id,
    title: title,
    streakCount: streakCount,
    checkedInToday: checkedInToday,
  );
}

ProductivityGoal _goal(
  String id, {
  String status = 'NOT_STARTED',
  double progress = 0,
  List<ProductivityMilestone> milestones = const [],
}) {
  return ProductivityGoal(
    goalId: id,
    title: 'Goal',
    status: status,
    progressPercentage: progress,
    milestones: milestones,
    totalMilestones: milestones.length,
    completedMilestones: milestones.where((item) => item.completed).length,
  );
}

void main() {
  late _MockProductivityRepository repository;
  late ProductivityController controller;

  setUp(() {
    repository = _MockProductivityRepository();
    controller = ProductivityController(repository: repository);
    when(() => repository.getDashboard()).thenAnswer((_) async => _dashboard);
  });

  test(
    'task create, update, complete, and delete keep local state in sync',
    () async {
      final created = _task('task-2', title: 'Write');
      final updated = _task('task-2', title: 'Write now');
      controller.tasks.add(_task('task-1'));

      when(
        () => repository.createTask(
          title: 'Write',
          description: null,
          priority: null,
          category: null,
          dueDate: null,
          reminderTime: null,
        ),
      ).thenAnswer((_) async => created);
      await controller.createTask(title: 'Write');
      expect(controller.tasks.map((item) => item.taskId), ['task-2', 'task-1']);

      when(
        () => repository.updateTask(
          taskId: 'task-2',
          title: 'Write now',
          description: null,
          priority: null,
          category: null,
          dueDate: null,
          reminderTime: null,
        ),
      ).thenAnswer((_) async => updated);
      await controller.updateTask(taskId: 'task-2', title: 'Write now');
      expect(controller.tasks.first.title, 'Write now');

      final completed = _task('task-1', completed: true);
      when(
        () => repository.setTaskCompleted('task-1', true),
      ).thenAnswer((_) async => completed);
      await controller.toggleTask('task-1', completed: true);
      expect(controller.tasks.last.completed, isTrue);

      when(() => repository.deleteTask('task-2')).thenAnswer((_) async {});
      await controller.deleteTask('task-2');
      expect(controller.tasks.map((item) => item.taskId), ['task-1']);
    },
  );

  test(
    'loading a referenced task fetches and updates controller state',
    () async {
      final task = _task('task-from-reminder', title: 'Submit report');
      when(
        () => repository.getTask('task-from-reminder'),
      ).thenAnswer((_) async => task);

      final loaded = await controller.loadTaskById('task-from-reminder');

      expect(loaded.title, 'Submit report');
      expect(controller.tasks.single.taskId, 'task-from-reminder');
    },
  );

  test('focus history loads more pages without duplicate sessions', () async {
    final newest = ProductivityFocusSession(
      sessionId: 'session-newest',
      status: 'COMPLETED',
      startedAt: DateTime(2026, 9, 20),
    );
    final older = ProductivityFocusSession(
      sessionId: 'session-older',
      status: 'COMPLETED',
      startedAt: DateTime(2026, 9, 19),
    );
    when(() => repository.getFocusHistory(page: 0, size: 20)).thenAnswer(
      (_) async => ProductivityPage(
        content: [newest],
        page: 0,
        size: 20,
        totalElements: 3,
        totalPages: 2,
        hasNext: true,
      ),
    );
    when(() => repository.getFocusHistory(page: 1, size: 20)).thenAnswer(
      (_) async => ProductivityPage(
        content: [newest, older],
        page: 1,
        size: 20,
        totalElements: 3,
        totalPages: 2,
        hasNext: false,
      ),
    );

    await controller.loadFocusHistory();
    await controller.loadNextFocusHistoryPage();

    expect(controller.focusHistory.map((session) => session.sessionId), [
      'session-newest',
      'session-older',
    ]);
    expect(controller.focusHistoryHasMore.value, isFalse);
    verify(() => repository.getFocusHistory(page: 0, size: 20)).called(1);
    verify(() => repository.getFocusHistory(page: 1, size: 20)).called(1);
  });

  test('motivation save and unsave follow returned server state', () async {
    const motivation = ProductivityMotivation(
      motivationId: 'motivation-1',
      title: 'Keep going',
      content: 'One step at a time.',
    );
    const saved = ProductivityMotivation(
      motivationId: 'motivation-1',
      title: 'Keep going',
      content: 'One step at a time.',
      saved: true,
    );
    controller.motivations.add(motivation);
    when(
      () => repository.saveMotivation('motivation-1'),
    ).thenAnswer((_) async => saved);
    when(
      () => repository.unsaveMotivation('motivation-1'),
    ).thenAnswer((_) async => motivation);

    await controller.saveMotivation('motivation-1');
    expect(controller.savedMotivations.single.saved, isTrue);
    await controller.unsaveMotivation('motivation-1');
    expect(controller.savedMotivations, isEmpty);
    expect(controller.motivations.single.saved, isFalse);
  });

  test(
    'duplicate task completion is ignored while the first request is pending',
    () async {
      controller.tasks.add(_task('task-1'));
      final response = Completer<ProductivityTask>();
      when(
        () => repository.setTaskCompleted('task-1', true),
      ).thenAnswer((_) => response.future);

      final first = controller.toggleTask('task-1', completed: true);
      await Future<void>.delayed(Duration.zero);
      final second = await controller.toggleTask('task-1', completed: false);

      verify(() => repository.setTaskCompleted('task-1', true)).called(1);
      expect(second.completed, isTrue);
      expect(controller.isBusy('task-1'), isTrue);

      response.complete(_task('task-1', completed: true));
      await first;
      expect(controller.isBusy('task-1'), isFalse);
    },
  );

  test('failed task completion rolls back the optimistic state', () async {
    final initial = _task('task-1', overdue: true);
    controller.tasks.add(initial);
    when(
      () => repository.setTaskCompleted('task-1', true),
    ).thenThrow(StateError('offline'));

    await expectLater(
      controller.toggleTask('task-1', completed: true),
      throwsA(isA<StateError>()),
    );

    expect(controller.tasks.single, initial);
    expect(controller.isBusy('task-1'), isFalse);
  });

  test(
    'habit create, update, and check-in expose the returned streak state',
    () async {
      final created = _habit('habit-1');
      final updated = _habit('habit-1', title: 'Read daily', streakCount: 4);
      final checkedIn = _habit(
        'habit-1',
        title: 'Read daily',
        streakCount: 5,
        checkedInToday: true,
      );

      when(
        () => repository.createHabit(
          title: 'Read',
          category: null,
          frequency: null,
          reminderTime: null,
        ),
      ).thenAnswer((_) async => created);
      await controller.createHabit(title: 'Read');

      when(
        () => repository.updateHabit(
          habitId: 'habit-1',
          title: 'Read daily',
          category: null,
          frequency: null,
          reminderTime: null,
        ),
      ).thenAnswer((_) async => updated);
      await controller.updateHabit(habitId: 'habit-1', title: 'Read daily');

      when(
        () => repository.checkInHabit('habit-1', completed: true),
      ).thenAnswer((_) async => checkedIn);
      await controller.toggleHabit('habit-1', completed: true);

      expect(controller.habits.single.streakCount, 5);
      expect(controller.habits.single.checkedInToday, isTrue);
    },
  );

  test('goal milestone response replaces status and progress', () async {
    final milestone = const ProductivityMilestone(
      milestoneId: 'milestone-1',
      title: 'First step',
      completed: true,
    );
    controller.goals.add(_goal('goal-1'));
    final progressed = _goal(
      'goal-1',
      status: 'IN_PROGRESS',
      progress: 50,
      milestones: [milestone],
    );
    when(
      () => repository.setMilestoneCompleted(
        goalId: 'goal-1',
        milestoneId: 'milestone-1',
        completed: true,
      ),
    ).thenAnswer((_) async => progressed);

    await controller.toggleMilestone(
      goalId: 'goal-1',
      milestoneId: 'milestone-1',
      completed: true,
    );

    expect(controller.goals.single.status, 'IN_PROGRESS');
    expect(controller.goals.single.progressPercentage, 50);
    expect(controller.goals.single.milestones.single.completed, isTrue);
  });

  test('focus completion records XP and refreshes stats', () async {
    final started = const ProductivityFocusSession(
      sessionId: 'session-1',
      mode: 'POMODORO',
      durationMinutes: 25,
    );
    final completed = const ProductivityFocusSession(
      sessionId: 'session-1',
      mode: 'POMODORO',
      durationMinutes: 25,
      completed: true,
      xpEarned: 5,
    );
    const stats = ProductivityFocusStats(
      todaySessions: 1,
      todayMinutes: 25,
      totalSessions: 1,
      totalMinutes: 25,
      totalXp: 5,
    );

    when(
      () => repository.startFocusSession(
        mode: 'POMODORO',
        durationMinutes: 25,
        ambientSound: null,
      ),
    ).thenAnswer((_) async => started);
    when(
      () => repository.completeFocusSession('session-1'),
    ).thenAnswer((_) async => completed);
    when(() => repository.getFocusStats()).thenAnswer((_) async => stats);

    expect(
      await controller.startFocusSession(mode: 'POMODORO', durationMinutes: 25),
      started,
    );
    final result = await controller.completeFocusSession('session-1');

    expect(result.xpEarned, 5);
    expect(controller.focusHistory.single.completed, isTrue);
    expect(controller.focusStats.value?.totalXp, 5);
  });

  test('active focus session is restored into controller state', () async {
    final active = const ProductivityFocusSession(
      sessionId: 'session-active',
      mode: 'POMODORO',
      durationMinutes: 25,
      status: 'ACTIVE',
      focusedSeconds: 120,
      remainingSeconds: 1380,
    );
    when(
      () => repository.getActiveFocusSession(),
    ).thenAnswer((_) async => active);

    final result = await controller.loadActiveFocusSession();

    expect(result, active);
    expect(controller.activeFocusSession.value, active);
  });

  test(
    'focus start is locally idempotent and lifecycle actions sync state',
    () async {
      final started = const ProductivityFocusSession(
        sessionId: 'session-1',
        mode: 'POMODORO',
        durationMinutes: 25,
        status: 'ACTIVE',
      );
      final paused = const ProductivityFocusSession(
        sessionId: 'session-1',
        mode: 'POMODORO',
        durationMinutes: 25,
        status: 'PAUSED',
        focusedSeconds: 60,
        remainingSeconds: 1440,
      );
      final resumed = const ProductivityFocusSession(
        sessionId: 'session-1',
        mode: 'POMODORO',
        durationMinutes: 25,
        status: 'ACTIVE',
        focusedSeconds: 60,
        remainingSeconds: 1440,
      );
      final abandoned = const ProductivityFocusSession(
        sessionId: 'session-1',
        mode: 'POMODORO',
        durationMinutes: 25,
        status: 'ABANDONED',
      );

      when(
        () => repository.startFocusSession(
          mode: 'POMODORO',
          durationMinutes: 25,
          ambientSound: null,
        ),
      ).thenAnswer((_) async => started);
      when(
        () => repository.pauseFocusSession('session-1'),
      ).thenAnswer((_) async => paused);
      when(
        () => repository.resumeFocusSession('session-1'),
      ).thenAnswer((_) async => resumed);
      when(
        () => repository.abandonFocusSession('session-1'),
      ).thenAnswer((_) async => abandoned);

      expect(
        await controller.startFocusSession(
          mode: 'POMODORO',
          durationMinutes: 25,
        ),
        started,
      );
      expect(
        await controller.startFocusSession(
          mode: 'POMODORO',
          durationMinutes: 25,
        ),
        started,
      );
      verify(
        () => repository.startFocusSession(
          mode: 'POMODORO',
          durationMinutes: 25,
          ambientSound: null,
        ),
      ).called(1);

      await controller.pauseFocusSession('session-1');
      expect(controller.activeFocusSession.value?.isPaused, isTrue);
      await controller.resumeFocusSession('session-1');
      expect(controller.activeFocusSession.value?.isActive, isTrue);
      await controller.abandonFocusSession('session-1');
      expect(controller.activeFocusSession.value, isNull);
      expect(controller.focusHistory, isEmpty);
    },
  );
}
