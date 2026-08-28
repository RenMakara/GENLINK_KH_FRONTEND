import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_deteail_widget';
import 'package:get/get.dart';

import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_home_widget.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskData task;

  final String description;

  final String reminderText;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.description =
        'Build the main dashboard component with TypeScript generics, proper type definitions, and all sub-components integrated.',
    this.reminderText = '30 min before',
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  // ============================================================
  // TASK STATE
  // ============================================================

  late bool _completed;

  // ============================================================
  // SUBTASK STATE
  // ============================================================

  final List<TaskDetailSubtaskData> _subtasks = [
    const TaskDetailSubtaskData(
      title: 'Research existing libraries',
      completed: true,
    ),
    const TaskDetailSubtaskData(
      title: 'Write initial component structure',
      completed: true,
    ),
    const TaskDetailSubtaskData(
      title: 'Add TypeScript generics',
      completed: false,
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _completed = widget.task.completed;
  }

  // ============================================================
  // TASK
  // ============================================================

  void _toggleCompleted() {
    setState(() {
      _completed = !_completed;
    });
  }

  // ============================================================
  // SUBTASK
  // ============================================================

  void _addSubtask(String title) {
    final value = title.trim();

    if (value.isEmpty) return;

    setState(() {
      _subtasks.add(TaskDetailSubtaskData(title: value, completed: false));
    });
  }

  void _toggleSubtask(int index) {
    if (index < 0 || index >= _subtasks.length) return;

    setState(() {
      final item = _subtasks[index];

      _subtasks[index] = item.copyWith(completed: !item.completed);
    });
  }

  void _deleteSubtask(int index) {
    if (index < 0 || index >= _subtasks.length) return;

    setState(() {
      _subtasks.removeAt(index);
    });
  }

  // ============================================================
  // EDIT
  // ============================================================

  void _showEditMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'task.detail.edit'.tr,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return TaskDeleteDialog(
          onCancel: () {
            Navigator.pop(dialogContext);
          },
          onDelete: () {
            Navigator.pop(dialogContext);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return TaskDetailLayout(
      task: widget.task,

      title: widget.task.title,

      description: widget.description,

      reminderText: widget.reminderText,

      completed: _completed,

      subtasks: _subtasks,

      onBack: () {
        Navigator.pop(context);
      },

      onEdit: _showEditMessage,

      onDelete: _showDeleteDialog,

      onCompletedChanged: _toggleCompleted,

      onSubtaskAdded: _addSubtask,

      onSubtaskChanged: _toggleSubtask,

      onSubtaskDeleted: _deleteSubtask,
    );
  }
}
