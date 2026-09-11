import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/productivity/data/models/productivity_models.dart';

void main() {
  test('maps the mobile productivity dashboard contract', () {
    final dashboard = ProductivityMapper.dashboard({
      'habits': {
        'total': 2,
        'checkedInToday': 1,
        'items': [
          {'habitId': 'habit-1', 'title': 'Read', 'checkedInToday': true},
        ],
      },
      'tasks': {'total': 3, 'completed': 2, 'dueToday': 1, 'overdue': 0},
      'goals': [
        {
          'goalId': 'goal-1',
          'title': 'Ship app',
          'progressPercentage': '42.5',
          'status': 'IN_PROGRESS',
        },
      ],
      'focus': {'todaySessions': 2, 'todayMinutes': 50, 'totalXp': 100},
      'motivation': {
        'motivationId': 'motivation-1',
        'title': 'Keep going',
        'content': 'Small steps count.',
      },
    });

    expect(dashboard.habits.total, 2);
    expect(dashboard.habits.items.single.title, 'Read');
    expect(dashboard.tasks.completed, 2);
    expect(dashboard.goals.single.progressPercentage, 42.5);
    expect(dashboard.focus.todayMinutes, 50);
    expect(dashboard.motivation?.content, 'Small steps count.');
  });

  test('maps goal milestones and paginated focus history', () {
    final goal = ProductivityMapper.goal({
      'goalId': 'goal-1',
      'title': 'Ship app',
      'deadline': '2026-10-01',
      'progressPercentage': 50,
      'completedMilestones': 1,
      'totalMilestones': 2,
      'milestones': [
        {
          'milestoneId': 'milestone-1',
          'title': 'First build',
          'completed': true,
          'completedAt': '2026-09-10T10:00:00Z',
        },
      ],
    });
    final page = ProductivityMapper.page({
      'content': [
        {
          'sessionId': 'session-1',
          'mode': 'POMODORO',
          'durationMinutes': '25',
          'completed': true,
        },
      ],
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
      'hasNext': false,
    }, ProductivityMapper.focusSession);

    expect(goal.deadline, DateTime(2026, 10, 1));
    expect(goal.milestones.single.completed, isTrue);
    expect(page.content.single.durationMinutes, 25);
    expect(page.content.single.completed, isTrue);
  });
}
