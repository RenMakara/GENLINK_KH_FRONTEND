import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/widget/productivity_screen_widget.dart';

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
              ProductivityHeader(title: 'Productivity', profileText: 'R'),

              const SizedBox(height: 18),

              ProductivitySummary(
                date: 'Wednesday, July 2',
                greeting: 'Good morning, Ratha 👋',
                tasks: '3/5',
                focus: '2h 14m',
                streak: '7 days',
              ),

              const SizedBox(height: 16),

              ProductivityCard(
                title: 'Today Plan',
                actionText: 'See All',
                child: ProductivityTaskList(
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

              const ProductivitySectionTitle(title: 'Quick Actions'),

              const SizedBox(height: 12),

              ProductivityQuickActions(
                actions: [
                  ProductivityActionData(
                    icon: Icons.add_task_rounded,
                    title: 'Add Task',
                  ),
                  ProductivityActionData(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Add Habit',
                  ),
                  ProductivityActionData(
                    icon: Icons.timer_outlined,
                    title: 'Focus',
                  ),
                  ProductivityActionData(
                    icon: Icons.flag_outlined,
                    title: 'New Goal',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ProductivityCard(
                title: 'Weekly Focus',
                actionText: 'This week',
                child: ProductivityProgress(
                  valueText: '8h 40m',
                  goalText: '/ 12h goal',
                  percentage: .72,
                  percentageText: '72% complete',
                  remainingText: '3h 20m remaining',
                ),
              ),

              const SizedBox(height: 16),

              ProductivityCard(
                title: 'Goal Progress',
                actionText: 'See All',
                child: ProductivityGoals(
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

              ProductivityInsight(
                title: 'Smart Insight',
                message:
                    'You are most productive between 9 AM and 11 AM. '
                    'Consider scheduling your hardest task during this time.',
              ),

              const SizedBox(height: 16),

              ProductivityCard(
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
