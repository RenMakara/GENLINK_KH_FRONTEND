import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/focus_home_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/habit_home_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/task_home_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/widget/productivity_widget.dart';

class ProductivityPage extends StatelessWidget {
  const ProductivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              ProductivityHeader(
                title: 'Productivity',
                profileText: 'R',
                onNotificationTap: () {
                  debugPrint('Notification tapped');
                },
                onProfileTap: () {
                  debugPrint('Profile tapped');
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // DAILY SUMMARY
              // ==================================================
              const ProductivitySummary(
                date: 'Wednesday, July 2',
                greeting: 'Good morning, Ratha 👋',
                tasks: '3/5',
                focus: '2h 14m',
                streak: '7 days',
              ),

              const SizedBox(height: 16),

              // ==================================================
              // TODAY PLAN
              // ==================================================
              ProductivityCard(
                title: 'Today Plan',
                actionText: 'See All',

                onAction: () async {
                  debugPrint('See All Tasks');

                  // Navigate to task page here.
                  await Future.delayed(const Duration(milliseconds: 500));
                },

                child: const ProductivityTaskList(
                  tasks: [
                    ProductivityTaskData(
                      title: 'Review weekly goals',
                      subtitle: 'Completed · 9:00 AM',
                      completed: true,
                    ),
                    ProductivityTaskData(
                      title: 'Deep work block – React',
                      subtitle: 'Due · 2:00 PM',
                    ),
                    ProductivityTaskData(
                      title: 'Send client report',
                      subtitle: 'Due · 5:00 PM',
                    ),
                  ],
                  progress: .40,
                  progressText: '40%',
                  footerText: '2 of 5 tasks completed',
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // QUICK ACTIONS
              // ==================================================
              const ProductivitySectionTitle(title: 'Quick Actions'),

              const SizedBox(height: 12),

              ProductivityQuickActions(
                actions: [
                  ProductivityActionData(
                    icon: Icons.add_task_rounded,
                    title: 'Add Task',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TasksPage()),
                      );
                    },
                  ),

                  ProductivityActionData(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Add Habit',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HabitHomeScreen(),
                        ),
                      );
                    },
                  ),

                  ProductivityActionData(
                    icon: Icons.timer_outlined,
                    title: 'Focus',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FocusPage()),
                      );
                    },
                  ),

                  ProductivityActionData(
                    icon: Icons.flag_outlined,
                    title: 'New Goal',
                    onTap: () async {
                      debugPrint('New Goal');

                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // WEEKLY FOCUS
              // ==================================================
              ProductivityCard(
                title: 'Weekly Focus',
                actionText: 'This week',

                onAction: () async {
                  debugPrint('Weekly Focus');

                  await Future.delayed(const Duration(milliseconds: 400));
                },

                child: const ProductivityProgress(
                  valueText: '8h 40m',
                  goalText: '/ 12h goal',
                  percentage: .72,
                  percentageText: '72% complete',
                  remainingText: '3h 20m remaining',
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // GOAL PROGRESS
              // ==================================================
              ProductivityCard(
                title: 'Goal Progress',
                actionText: 'See All',

                onAction: () async {
                  debugPrint('See All Goals');

                  await Future.delayed(const Duration(milliseconds: 400));
                },

                child: const ProductivityGoals(
                  goals: [
                    ProductivityGoalData(
                      category: 'Skill',
                      title: 'Master TypeScript',
                      percentage: .62,
                      value: '62%',
                    ),
                    ProductivityGoalData(
                      category: 'Health',
                      title: 'Daily Exercise',
                      percentage: .38,
                      value: '38%',
                    ),
                    ProductivityGoalData(
                      category: 'Productivity',
                      title: 'Read 12 books',
                      percentage: .75,
                      value: '75%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SMART INSIGHT
              // ==================================================
              const ProductivityInsight(
                title: 'Smart Insight',
                message:
                    'You are most productive between 9 AM and 11 AM. '
                    'Consider scheduling your hardest task during this time.',
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RECENT ACTIVITY
              // ==================================================
              const ProductivityCard(
                title: 'Recent Activity',
                child: ProductivityActivities(
                  activities: [
                    ProductivityActivityData(
                      icon: Icons.timer_outlined,
                      title: 'Completed Pomodoro session',
                      time: '2h ago',
                    ),
                    ProductivityActivityData(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Task: Weekly review done',
                      time: '3h ago',
                    ),
                    ProductivityActivityData(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Habit streak +1 — Reading',
                      time: '6h ago',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
