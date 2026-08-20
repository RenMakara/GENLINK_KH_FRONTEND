import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_home_widget.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // CONTROLLERS
  final TextEditingController _searchController = TextEditingController();

  // STATE
  String _searchText = '';

  int _selectedStatus = 0;
  int _selectedPriority = 0;

  // TASK DATA
  final List<TaskData> _tasks = const [
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
  ];

  // FILTERED TASKS
  List<TaskData> get _filteredTasks {
    List<TaskData> result = List<TaskData>.from(_tasks);

    // SEARCH
    if (_searchText.trim().isNotEmpty) {
      final query = _searchText.toLowerCase().trim();

      result = result.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.dueText.toLowerCase().contains(query);
      }).toList();
    }

    // STATUS

    switch (_selectedStatus) {
      case 1:
        // TODAY

        result = result.where((task) {
          final due = task.dueText.toLowerCase();

          return !task.completed &&
              (due.contains('am') || due.contains('pm')) &&
              !due.contains('tomorrow');
        }).toList();

        break;

      case 2:
        // UPCOMING

        result = result.where((task) {
          return !task.completed &&
              task.dueText.toLowerCase().contains('tomorrow');
        }).toList();

        break;

      case 3:
        // COMPLETED

        result = result.where((task) {
          return task.completed;
        }).toList();

        break;
    }

    // PRIORITY
    switch (_selectedPriority) {
      case 1:
        result = result.where((task) {
          return task.priority == TaskPriority.high;
        }).toList();

        break;

      case 2:
        result = result.where((task) {
          return task.priority == TaskPriority.medium;
        }).toList();

        break;

      case 3:
        result = result.where((task) {
          return task.priority == TaskPriority.low;
        }).toList();

        break;
    }

    return result;
  }

  // ACTIVE FILTER COUNT
  int get _activeFilterCount {
    int count = 0;

    if (_selectedStatus != 0) {
      count++;
    }

    if (_selectedPriority != 0) {
      count++;
    }

    return count;
  }

  // OPEN FILTER
  void _openFilterSheet() {
    int temporaryStatus = _selectedStatus;
    int temporaryPriority = _selectedPriority;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return TasksFilterSheet(
              selectedStatus: temporaryStatus,
              selectedPriority: temporaryPriority,

              // STATUS
              onStatusChanged: (index) {
                setSheetState(() {
                  temporaryStatus = index;
                });
              },

              // PRIORITY
              onPriorityChanged: (index) {
                setSheetState(() {
                  temporaryPriority = index;
                });
              },

              // RESET
              onReset: () {
                setSheetState(() {
                  temporaryStatus = 0;
                  temporaryPriority = 0;
                });
              },

              // APPLY
              onApply: () {
                setState(() {
                  _selectedStatus = temporaryStatus;
                  _selectedPriority = temporaryPriority;
                });

                Navigator.of(sheetContext).pop();
              },
            );
          },
        );
      },
    );
  }

  // CREATE TASK
  void _createTask() {
    debugPrint('Create task');
  }

  // DISPOSE
  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Scaffold(
      backgroundColor: colors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP BAR
              TasksTopBar(
                title: 'Tasks',

                onBack: () {
                  Navigator.of(context).pop();
                },

                onAdd: _createTask,
              ),

              const SizedBox(height: 20),

              // SEARCH
              TasksSearchField(
                controller: _searchController,

                hintText: 'Search your tasks...',

                activeFilterCount: _activeFilterCount,

                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },

                onFilter: _openFilterSheet,
              ),

              const SizedBox(height: 22),

              // TASK HEADER
              TasksHeader(
                count: _filteredTasks.length,

                activeFilterCount: _activeFilterCount,

                onFilter: _openFilterSheet,
              ),

              const SizedBox(height: 10),

              // TASK LIST
              TasksList(tasks: _filteredTasks),

              const SizedBox(height: 20),

              // BOTTOM TIP
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 12,
                      color: colors.textMuted,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Tap a task to mark it complete',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
