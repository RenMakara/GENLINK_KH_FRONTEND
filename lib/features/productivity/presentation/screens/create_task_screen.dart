import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../levelup/widget/grow_section_widget.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../widgets/creation_form_components.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProductivityController? _controller;
  String _priority = 'MEDIUM';
  String _category = 'STUDY';
  DateTime? _dueDate;
  DateTime? _reminderTime;
  bool _saving = false;

  static const _categories = ['STUDY', 'WORK', 'PERSONAL', 'HEALTH', 'OTHER'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('task.create.validation.titleRequired'.tr);
      return;
    }

    final controller = _controller;
    if (controller == null) {
      Get.back(result: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await controller.createTask(
        title: title,
        description: _optionalText(_descriptionController.text),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        reminderTime: _reminderTime,
      );
      if (mounted) Get.back(result: true);
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _dueDate ?? now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_dueDate!),
    );
    if (time == null) return;
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickReminderTime() async {
    final now = _dueDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _reminderTime ?? now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_reminderTime!),
    );
    if (time == null) return;
    setState(() {
      _reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryLabel(String item) {
    switch (item.toUpperCase()) {
      case 'STUDY':
        return 'task.create.category.study'.tr;
      case 'WORK':
        return 'task.create.category.work'.tr;
      case 'PERSONAL':
        return 'task.create.category.personal'.tr;
      case 'HEALTH':
        return 'task.create.category.health'.tr;
      case 'OTHER':
        return 'task.create.category.other'.tr;
      default:
        return item;
    }
  }

  Widget _categoryIcon(String category, bool isSelected) {
    Color iconColor;
    Color bgColor;
    IconData iconData;

    switch (category.toUpperCase()) {
      case 'STUDY':
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        iconData = Icons.school_rounded;
        break;
      case 'WORK':
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        iconData = Icons.work_rounded;
        break;
      case 'PERSONAL':
        iconColor = const Color(0xFF9333EA);
        bgColor = const Color(0xFFF3E8FF);
        iconData = Icons.person_rounded;
        break;
      case 'HEALTH':
        iconColor = const Color(0xFFE11D48);
        bgColor = const Color(0xFFFFE4E6);
        iconData = Icons.favorite_rounded;
        break;
      case 'OTHER':
      default:
        iconColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        iconData = Icons.category_rounded;
        break;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        color: iconColor,
        size: 19,
      ),
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'LOW':
        return 'task.create.priority.low'.tr;
      case 'HIGH':
        return 'task.create.priority.high'.tr;
      case 'MEDIUM':
      default:
        return 'task.create.priority.medium'.tr;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'LOW':
        return const Color(0xFF22C55E);
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreationFormScaffold(
      header: CreationFormHeader(
        title: 'task.create.title'.tr,
        subtitle: 'task.create.subtitle'.tr,
        onSave: _save,
        isSaving: _saving,
      ),
      bottomBar: CreationPrimaryButton(
        label: 'task.create.saveTask'.tr,
        onPressed: _save,
        isLoading: _saving,
      ),
      children: [
        // Hero Card (Blue gradient with 3D Tasks Icon)
        CreationHeroCard(
          illustration: const Soft3DTasksIcon(size: 46),
          quote: 'task.create.heroQuote'.tr,
          gradientColors: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          quoteColor: const Color(0xFF1D4ED8),
          sparkleColor: const Color(0xFF3B82F6),
        ),

        // Task Title Field
        CreationTextField(
          controller: _titleController,
          label: 'task.create.titleLabel'.tr,
          isRequired: true,
          hintText: 'task.create.taskTitleHint'.tr,
          autofocus: true,
          textInputAction: TextInputAction.next,
          accentColor: const Color(0xFF2563EB),
          leadingIcon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.format_list_bulleted_rounded,
              color: Color(0xFF2563EB),
              size: 19,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Description Field
        CreationTextField(
          controller: _descriptionController,
          label: 'task.create.descriptionOptional'.tr,
          hintText: 'task.create.descriptionHint'.tr,
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          accentColor: const Color(0xFF2563EB),
          leadingIcon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.article_outlined,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Category Dropdown Card
        CreationDropdownCard(
          label: 'task.create.category'.tr,
          sheetTitle: 'task.create.category'.tr,
          value: _category,
          values: _categories,
          accentColor: const Color(0xFF2563EB),
          leadingIcon: _categoryIcon(_category, false),
          itemLabelBuilder: _categoryLabel,
          itemIconBuilder: (item, isSelected) =>
              _categoryIcon(item, isSelected),
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Priority Cards (Low, Medium, High)
        CreationSectionLabel(label: 'task.create.priority'.tr),
        Row(
          children: _priorities.map((priority) {
            final isSelected = _priority == priority;
            final color = _priorityColor(priority);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SelectionOptionCard(
                  label: _priorityLabel(priority),
                  isSelected: isSelected,
                  accentColor: color,
                  indicatorColor: color,
                  onTap: () => setState(() => _priority = priority),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Due Date Picker Card
        CreationPickerCard(
          leadingIcon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2563EB),
              size: 19,
            ),
          ),
          title: 'task.create.dueDateOptional'.tr,
          subtitle: _dueDate == null
              ? 'tasks.noDueDate'.tr
              : _formatDateTime(_dueDate!, context),
          onTap: _pickDueDate,
          showTrailingArrow: true,
          onClear: _dueDate != null
              ? () => setState(() => _dueDate = null)
              : null,
        ),
        const SizedBox(height: AppSpacing.md),

        // Reminder Picker Card
        CreationPickerCard(
          leadingIcon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF9333EA),
              size: 20,
            ),
          ),
          title: 'task.create.reminderOptional'.tr,
          subtitle: _reminderTime == null
              ? 'task.create.noReminder'.tr
              : _formatDateTime(_reminderTime!, context),
          onTap: _pickReminderTime,
          showTrailingArrow: true,
          onClear: _reminderTime != null
              ? () => setState(() => _reminderTime = null)
              : null,
        ),
      ],
    );
  }
}

String? _optionalText(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _formatDateTime(DateTime value, BuildContext context) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
  return '$date ${TimeOfDay.fromDateTime(value).format(context)}';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
