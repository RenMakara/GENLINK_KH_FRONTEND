import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _titleController = TextEditingController();
  ProductivityController? _controller;
  String _category = 'PERSONAL';
  String _frequency = 'DAILY';
  TimeOfDay? _reminderTime;
  bool _saving = false;

  static const _categories = [
    'PERSONAL',
    'HEALTH',
    'LEARNING',
    'WORK',
    'OTHER',
  ];
  static const _frequencies = ['DAILY', 'WEEKLY', 'CUSTOM'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Please enter a habit title.');
      return;
    }

    final controller = _controller;
    if (controller == null) {
      Get.back(result: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await controller.createHabit(
        title: title,
        category: _category,
        frequency: _frequency,
        reminderTime: _formatTime(_reminderTime),
      );
      if (mounted) Get.back(result: true);
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _HabitFormColors(context);
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
        title: const Text('New Habit'),
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
              textInputAction: TextInputAction.done,
              style: TextStyle(color: colors.textPrimary),
              decoration: _decoration(
                colors,
                hintText: 'What habit do you want to build?',
              ),
              onSubmitted: (_) => _saving ? null : _save(),
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
            _FieldLabel(label: 'Frequency', color: colors.textPrimary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _frequencies
                  .map((value) {
                    final selected = _frequency == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: selected,
                      onSelected: (_) => setState(() => _frequency = value),
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
            _FieldLabel(label: 'Reminder', color: colors.textPrimary),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              tileColor: colors.surfaceSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: colors.border),
              ),
              leading: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.productivityAccent,
              ),
              title: Text(
                _reminderTime == null
                    ? 'No reminder set'
                    : _reminderTime!.format(context),
                style: TextStyle(color: colors.textPrimary),
              ),
              trailing: _reminderTime == null
                  ? const Icon(Icons.chevron_right_rounded)
                  : IconButton(
                      onPressed: () => setState(() => _reminderTime = null),
                      icon: const Icon(Icons.clear_rounded),
                    ),
              onTap: _pickReminderTime,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
    _HabitFormColors colors, {
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
  final _HabitFormColors colors;
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

class _HabitFormColors {
  _HabitFormColors(BuildContext context)
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

String? _formatTime(TimeOfDay? time) {
  if (time == null) return null;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
