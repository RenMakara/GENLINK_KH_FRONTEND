import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_home_widget.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP ROW
              // ==================================================
              TasksTopBar(
                title: 'Tasks',
                onBack: () {
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SEARCH
              // ==================================================
              const TasksSearchField(hintText: 'Search tasks...'),

              const SizedBox(height: 12),

              // ==================================================
              // STATUS
              // ==================================================
              const TasksStatusFilters(
                filters: ['Today', 'Upcoming', 'Completed'],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // PRIORITY
              // ==================================================
              const TasksPriorityFilters(
                filters: ['All', 'High', 'Medium', 'Low'],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // TASK LIST
              // ==================================================
              TasksList(
                tasks: [
                  TaskData(
                    title: 'Deep work — React TypeScript',
                    dueText: 'Due 2:00 PM',
                    priority: TaskPriority.high,
                  ),

                  TaskData(
                    title: 'Review weekly goals',
                    dueText: 'Completed · 9:00 AM',
                    priority: TaskPriority.high,
                    completed: true,
                  ),

                  TaskData(
                    title: 'Update portfolio design',
                    dueText: 'Due 4:00 PM',
                    priority: TaskPriority.medium,
                  ),

                  TaskData(
                    title: 'Send client proposal',
                    dueText: 'Due 5:00 PM',
                    priority: TaskPriority.low,
                  ),

                  TaskData(
                    title: 'Read design patterns book',
                    dueText: 'Completed',
                    priority: TaskPriority.high,
                    completed: true,
                  ),

                  TaskData(
                    title: 'Prepare presentation',
                    dueText: 'Due Tomorrow · 10:00 AM',
                    priority: TaskPriority.medium,
                  ),

                  TaskData(
                    title: 'Check project GitHub issues',
                    dueText: 'Due Tomorrow · 3:00 PM',
                    priority: TaskPriority.low,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // BOTTOM INFO
              // ==================================================
              Center(
                child: Text(
                  'Tap a task to mark it complete',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.black38,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
