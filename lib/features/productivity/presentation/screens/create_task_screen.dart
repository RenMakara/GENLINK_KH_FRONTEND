import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';

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
      _showMessage('Please enter a task title.');
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _TaskFormColors(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('New Task'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.textPrimary,
                foregroundColor: colors.inverseText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.squircle),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: colors.textPrimary),
              decoration: _decoration(
                colors,
                hintText: 'What needs to be done?',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: colors.textPrimary),
              decoration: _decoration(
                colors,
                hintText: 'Add details or notes (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FieldLabel(label: 'Category', color: colors.textPrimary),
            const SizedBox(height: 8),
            _DropdownField(
              value: _category,
              values: _categories,
              colors: colors,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FieldLabel(label: 'Priority', color: colors.textPrimary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _priorities
                  .map((value) {
                    final selected = _priority == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: selected,
                      onSelected: (_) => setState(() => _priority = value),
                      selectedColor: AppColors.productivityAccent,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              tileColor: colors.surfaceSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: colors.border),
              ),
              leading: const Icon(
                Icons.event_outlined,
                color: AppColors.productivityAccent,
              ),
              title: Text(
                _dueDate == null
                    ? 'No due date'
                    : _formatDateTime(_dueDate!, context),
                style: TextStyle(color: colors.textPrimary),
              ),
              trailing: _dueDate == null
                  ? const Icon(Icons.chevron_right_rounded)
                  : IconButton(
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear_rounded),
                    ),
              onTap: _pickDueDate,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
    _TaskFormColors colors, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colors.textMuted),
      filled: true,
      fillColor: colors.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: colors.border),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.values,
    required this.colors,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final _TaskFormColors colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: values
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(growable: false),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      dropdownColor: colors.surface,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(color: color, fontWeight: FontWeight.w700),
  );
}

class _TaskFormColors {
  _TaskFormColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get inverseText =>
      isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
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
