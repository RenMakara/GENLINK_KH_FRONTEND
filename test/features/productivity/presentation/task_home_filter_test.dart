import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/task_home_screen.dart';

void main() {
  final now = DateTime(2026, 9, 19, 10);
  final tasks = [
    ProductivityTask(
      taskId: 'today',
      title: 'Today task',
      dueDate: DateTime(2026, 9, 19, 18),
    ),
    ProductivityTask(
      taskId: 'upcoming',
      title: 'Upcoming task',
      dueDate: DateTime(2026, 9, 20, 9),
    ),
    ProductivityTask(
      taskId: 'overdue',
      title: 'Overdue task',
      dueDate: DateTime(2026, 9, 18),
      overdue: true,
    ),
    const ProductivityTask(
      taskId: 'completed',
      title: 'Completed task',
      completed: true,
    ),
  ];

  test(
    'task filters expose today, upcoming, overdue, and completed states',
    () {
      expect(
        filterProductivityTasks(
          tasks,
          filter: ProductivityTaskFilter.today,
          now: now,
        ).single.taskId,
        'today',
      );
      expect(
        filterProductivityTasks(
          tasks,
          filter: ProductivityTaskFilter.upcoming,
          now: now,
        ).single.taskId,
        'upcoming',
      );
      expect(
        filterProductivityTasks(
          tasks,
          filter: ProductivityTaskFilter.overdue,
          now: now,
        ).single.taskId,
        'overdue',
      );
      expect(
        filterProductivityTasks(
          tasks,
          filter: ProductivityTaskFilter.completed,
          now: now,
        ).single.taskId,
        'completed',
      );
    },
  );

  test(
    'task filter applies title and description search without changing state',
    () {
      final result = filterProductivityTasks(
        tasks,
        filter: ProductivityTaskFilter.all,
        search: 'UPCOMING',
        now: now,
      );

      expect(result.single.taskId, 'upcoming');
    },
  );
}
