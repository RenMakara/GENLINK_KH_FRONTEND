import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../screens/create_task_screen.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  ProductivityController? _controller;
  String _search = '';
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    await Get.to(() => const CreateTaskScreen());
    await _controller?.reload();
  }

  Future<void> _toggle(
    ProductivityController controller,
    ProductivityTask task,
  ) async {
    try {
      await controller.toggleTask(task.taskId, completed: !task.completed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _delete(ProductivityController controller, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This task will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await controller.deleteTask(taskId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  List<ProductivityTask> _filtered(List<ProductivityTask> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final query = _search.trim().toLowerCase();

    return tasks
        .where((task) {
          if (query.isNotEmpty &&
              !task.title.toLowerCase().contains(query) &&
              !(task.description ?? '').toLowerCase().contains(query)) {
            return false;
          }

          final due = task.dueDate?.toLocal();
          switch (_filter) {
            case _TaskFilter.all:
              return true;
            case _TaskFilter.today:
              return !task.completed &&
                  due != null &&
                  due.isAfter(today.subtract(const Duration(seconds: 1))) &&
                  due.isBefore(tomorrow);
            case _TaskFilter.upcoming:
              return !task.completed && due != null && !due.isBefore(tomorrow);
            case _TaskFilter.completed:
              return task.completed;
          }
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableTaskView();

    final colors = _TaskColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.tasks.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final tasks = _filtered(controller.tasks.toList(growable: false));
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: const Text('Tasks'),
          actions: [
            IconButton(
              onPressed: _createTask,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create task',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.productivityAccent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _FilterBar(
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My tasks',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                _EmptyTasks(onCreate: _createTask)
              else
                ...tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskTile(
                      task: task,
                      busy: controller.isBusy(task.taskId),
                      onToggle: () => _toggle(controller, task),
                      onDelete: () => _delete(controller, task.taskId),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

enum _TaskFilter { all, today, upcoming, completed }

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      _TaskFilter.all: 'All',
      _TaskFilter.today: 'Today',
      _TaskFilter.upcoming: 'Upcoming',
      _TaskFilter.completed: 'Completed',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _TaskFilter.values
            .map((filter) {
              final isSelected = filter == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(labels[filter]!),
                  selected: isSelected,
                  onSelected: (_) => onChanged(filter),
                  selectedColor: AppColors.productivityAccent,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });

  final ProductivityTask task;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = _TaskColors(context);
    final priorityColor = switch (task.priority) {
      'HIGH' => AppColors.danger,
      'LOW' => AppColors.success,
      _ => AppColors.productivityAccent,
    };
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: task.overdue
              ? AppColors.danger.withValues(alpha: .65)
              : colors.border,
        ),
      ),
      child: ListTile(
        onTap: busy ? null : onToggle,
        leading: IconButton(
          onPressed: busy ? null : onToggle,
          icon: Icon(
            task.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.completed ? AppColors.success : colors.textMuted,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _taskSubtitle(task),
          style: TextStyle(
            color: task.overdue ? AppColors.danger : colors.textMuted,
            fontSize: 11,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.priority != null)
              Text(
                task.priority!,
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = _TaskColors(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded, color: colors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            'No tasks found',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a task and keep your next step visible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onCreate, child: const Text('Create task')),
        ],
      ),
    );
  }
}

class _UnavailableTaskView extends StatelessWidget {
  const _UnavailableTaskView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sign in to manage tasks.')),
    );
  }
}

class _TaskColors {
  _TaskColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}

String _taskSubtitle(ProductivityTask task) {
  final category = task.category;
  final due = task.dueDate;
  if (task.overdue) return '${category ?? 'Task'} · Overdue';
  if (due == null) return category ?? 'No due date';
  final local = due.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${category ?? 'Task'} · ${local.month}/${local.day} $hour:$minute $period';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('AppError(', '').split('):').last.trim();
