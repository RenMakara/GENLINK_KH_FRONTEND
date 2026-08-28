import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/task_create_screen.dart';
import 'package:get/get.dart';

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

  // FILTER OPTIONS
  // Use getters so translations refresh correctly.
  List<String> get _statusOptions => [
    'tasks.filter.all'.tr,
    'tasks.filter.today'.tr,
    'tasks.filter.upcoming'.tr,
    'tasks.filter.completed'.tr,
  ];

  List<String> get _priorityOptions => [
    'tasks.filter.all'.tr,
    'tasks.filter.high'.tr,
    'tasks.filter.medium'.tr,
    'tasks.filter.low'.tr,
  ];

  // FILTERED TASKS
  List<TaskData> get _filteredTasks {
    var result = List<TaskData>.from(_tasks);

    // SEARCH
    if (_searchText.trim().isNotEmpty) {
      final query = _searchText.trim().toLowerCase();

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
        result = result
            .where((task) => task.priority == TaskPriority.high)
            .toList();
        break;

      case 2:
        result = result
            .where((task) => task.priority == TaskPriority.medium)
            .toList();
        break;

      case 3:
        result = result
            .where((task) => task.priority == TaskPriority.low)
            .toList();
        break;
    }

    return result;
  }

  // ACTIVE FILTER COUNT
  int get _activeFilterCount {
    int count = 0;

    if (_selectedStatus != 0) count++;
    if (_selectedPriority != 0) count++;

    return count;
  }

  // FILTER SHEET
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
              title: 'tasks.filter.title'.tr,
              subtitle: 'tasks.filter.subtitle'.tr,
              statusTitle: 'tasks.filter.status'.tr,
              priorityTitle: 'tasks.filter.priority'.tr,
              resetText: 'tasks.filter.reset'.tr,
              applyText: 'tasks.filter.apply'.tr,
              statusOptions: _statusOptions,
              priorityOptions: _priorityOptions,
              selectedStatus: temporaryStatus,
              selectedPriority: temporaryPriority,
              onStatusChanged: (index) {
                setSheetState(() {
                  temporaryStatus = index;
                });
              },
              onPriorityChanged: (index) {
                setSheetState(() {
                  temporaryPriority = index;
                });
              },
              onReset: () {
                setSheetState(() {
                  temporaryStatus = 0;
                  temporaryPriority = 0;
                });
              },
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateTaskPage()));
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
              TasksTopBar(
                title: 'tasks.title'.tr,
                subtitle: 'tasks.subtitle'.tr,
                onBack: () => Navigator.of(context).pop(),
                onAdd: _createTask,
              ),

              const SizedBox(height: 20),

              TasksSearchField(
                controller: _searchController,
                hintText: 'tasks.searchHint'.tr,
                activeFilterCount: _activeFilterCount,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                onFilter: _openFilterSheet,
              ),

              const SizedBox(height: 22),

              TasksHeader(
                title: 'tasks.myTasks'.tr,
                count: _filteredTasks.length,
                activeFilterCount: _activeFilterCount,
                onFilter: _openFilterSheet,
              ),

              const SizedBox(height: 10),

              TasksList(
                tasks: _filteredTasks,
                emptyTitle: 'tasks.empty.title'.tr,
                emptyMessage: 'tasks.empty.message'.tr,
              ),

              const SizedBox(height: 20),

              TasksBottomTip(text: 'tasks.bottomTip'.tr),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
