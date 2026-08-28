import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_create_widget.dart';
import 'package:get/get.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  // CONTROLLERS
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // STATE
  TaskPriorityOption _priority = TaskPriorityOption.high;
  TaskCategoryOption _category = TaskCategoryOption.study;

  DateTime? _dueDate;
  TimeOfDay? _reminderTime;

  List<CreateSubtaskData> _subtasks = [];

  // DATE
  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
    });
  }

  // REMINDER
  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      _reminderTime = picked;
    });
  }

  // ADD SUBTASK
  void _addSubtask(String title) {
    final value = title.trim();

    if (value.isEmpty) return;

    setState(() {
      _subtasks = [..._subtasks, CreateSubtaskData(title: value)];
    });
  }

  // TOGGLE SUBTASK
  void _toggleSubtask(int index, bool completed) {
    setState(() {
      _subtasks[index] = _subtasks[index].copyWith(completed: completed);
    });
  }

  // DELETE SUBTASK
  void _deleteSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  // SAVE
  void _saveTask() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      Get.snackbar(
        'task.create.title'.tr,
        'task.create.validation.titleRequired'.tr,
      );

      return;
    }

    debugPrint('Title: $title');
    debugPrint('Description: ${_descriptionController.text.trim()}');
    debugPrint('Priority: $_priority');
    debugPrint('Category: $_category');
    debugPrint('Due Date: $_dueDate');
    debugPrint('Reminder: $_reminderTime');
    debugPrint('Subtasks: ${_subtasks.length}');

    Navigator.of(context).pop();
  }

  // DISPOSE
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return CreateTaskLayout(
      titleController: _titleController,
      descriptionController: _descriptionController,
      priority: _priority,
      category: _category,
      dueDate: _dueDate,
      reminderTime: _reminderTime,
      subtasks: _subtasks,
      onBack: () {
        Navigator.of(context).pop();
      },
      onPriorityChanged: (value) {
        setState(() {
          _priority = value;
        });
      },
      onCategoryChanged: (value) {
        setState(() {
          _category = value;
        });
      },
      onDueDateTap: _pickDueDate,
      onReminderTap: _pickReminder,
      onSubtaskAdded: _addSubtask,
      onSubtaskChanged: _toggleSubtask,
      onSubtaskDeleted: _deleteSubtask,
      onSave: _saveTask,
    );
  }
}
