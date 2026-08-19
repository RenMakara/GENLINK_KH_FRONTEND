import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/widget/habit_home_widget.dart';

class HabitHomeScreen extends StatelessWidget {
  const HabitHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HabitHomeWidget(
      title: 'Habits',

      streak: HabitStreakData(days: 7, bestDays: 14, weeklyCompletion: 66),

      todayTitle: "Today's Habits",
      manageText: 'Manage',

      habits: [
        HabitData(
          title: 'Morning meditation',
          streak: 12,
          completed: true,
          completedDays: 4,
        ),
        HabitData(
          title: '30-min exercise',
          streak: 5,
          completed: true,
          completedDays: 4,
        ),
        HabitData(
          title: 'Read 30 minutes',
          streak: 7,
          completed: false,
          completedDays: 3,
        ),
        HabitData(
          title: 'Evening journaling',
          streak: 4,
          completed: false,
          completedDays: 3,
        ),
      ],

      weeklyTitle: 'Weekly Overview',

      weeklyData: [
        [0, 1, 1, 2, 3, 3, 0],
        [0, 1, 2, 2, 3, 0, 0],
        [1, 2, 2, 3, 0, 0, 1],
        [2, 3, 3, 0, 0, 1, 2],
      ],
    );
  }
}
