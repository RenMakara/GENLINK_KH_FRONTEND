import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProductivityController? _controller;
  String _goalType = 'PERSONAL';
  DateTime? _deadline;
  bool _saving = false;

  static const _goalTypes = ['PERSONAL', 'CAREER', 'SKILL', 'FINANCE'];

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
      _showMessage('Please enter a goal title.');
      return;
    }

    final controller = _controller;
    if (controller == null) {
      Get.back(result: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await controller.createGoal(
        title: title,
        description: _optionalText(_descriptionController.text),
        goalType: _goalType,
        deadline: _deadline,
      );
      if (mounted) Get.back(result: true);
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: _deadline ?? now,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _GoalFormColors(context);
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
        title: const Text('New Goal'),
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
                hintText: 'What do you want to achieve?',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: colors.textPrimary),
              decoration: _decoration(
                colors,
                hintText: 'Describe the outcome (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Goal type',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalTypes
                  .map((value) {
                    final selected = _goalType == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: selected,
                      onSelected: (_) => setState(() => _goalType = value),
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
                Icons.event_available_rounded,
                color: AppColors.productivityAccent,
              ),
              title: Text(
                _deadline == null ? 'No deadline' : _formatDate(_deadline!),
                style: TextStyle(color: colors.textPrimary),
              ),
              trailing: _deadline == null
                  ? const Icon(Icons.chevron_right_rounded)
                  : IconButton(
                      onPressed: () => setState(() => _deadline = null),
                      icon: const Icon(Icons.clear_rounded),
                    ),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Milestones can be added after the goal is created.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
    _GoalFormColors colors, {
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

class _GoalFormColors {
  _GoalFormColors(BuildContext context)
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

String _formatDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
