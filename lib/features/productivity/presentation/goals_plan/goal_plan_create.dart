import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../widgets/creation_form_components.dart';
import '../widgets/productivity_illustrations.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  ProductivityController? _controller;
  String _goalType = 'PERSONAL';
  DateTime? _deadline;
  bool _saving = false;
  final List<String> _pendingMilestones = [];

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
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('goals.create.validationTitle'.tr);
      return;
    }

    final controller = _controller;
    if (controller == null) {
      Get.back(result: true);
      return;
    }

    setState(() => _saving = true);
    try {
      String? description = _optionalText(_descriptionController.text);
      final target = _optionalText(_targetController.text);
      if (target != null) {
        description = description == null
            ? 'Target: $target'
            : '$description\nTarget: $target';
      }

      final goal = await controller.createGoal(
        title: title,
        description: description,
        goalType: _goalType,
        deadline: _deadline,
      );

      for (final milestone in _pendingMilestones) {
        try {
          await controller.addMilestone(
            goalId: goal.goalId,
            title: milestone,
          );
        } catch (_) {
          // Continue adding remaining milestones if one fails
        }
      }

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

  Future<void> _pickTarget() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _TargetInputDialog(initialValue: _targetController.text),
    );

    if (result != null) {
      setState(() => _targetController.text = result);
    }
  }

  Future<void> _showAddMilestoneDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _CreateMilestoneDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _pendingMilestones.add(result));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _goalTypeLabel(String type) {
    switch (type) {
      case 'PERSONAL':
        return 'goals.type.personal'.tr;
      case 'CAREER':
        return 'goals.type.career'.tr;
      case 'SKILL':
        return 'goals.type.skill'.tr;
      case 'FINANCE':
        return 'goals.type.finance'.tr;
      default:
        return type;
    }
  }

  Widget _goalTypeIcon(String type, bool isSelected) {
    switch (type) {
      case 'PERSONAL':
        return Icon(
          Icons.person_rounded,
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF10B981),
          size: 26,
        );
      case 'CAREER':
        return Icon(
          Icons.work_rounded,
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF3B82F6),
          size: 26,
        );
      case 'SKILL':
        return Icon(
          Icons.insights_rounded,
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF8B5CF6),
          size: 26,
        );
      case 'FINANCE':
        return Icon(
          Icons.monetization_on_rounded,
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
          size: 26,
        );
      default:
        return const Icon(Icons.star_rounded, size: 26);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreationFormScaffold(
      header: CreationFormHeader(
        title: 'goals.create.title'.tr,
        subtitle: 'goals.create.subtitle'.tr,
        onSave: _save,
        isSaving: _saving,
      ),
      bottomBar: CreationPrimaryButton(
        label: 'goals.create.saveGoal'.tr,
        onPressed: _save,
        isLoading: _saving,
      ),
      children: [
        // Hero Card (Mint/Green gradient with 3D Goal Mound)
        CreationHeroCard(
          illustration: const Soft3DGoalMoundWidget(width: 76, height: 56),
          quote: 'goals.create.heroQuote'.tr,
          gradientColors: const [Color(0xFFE6FBF0), Color(0xFFCCFBE0)],
          quoteColor: const Color(0xFF047857),
          sparkleColor: const Color(0xFF10B981),
        ),

        // Goal Title Field
        CreationTextField(
          controller: _titleController,
          label: 'goals.create.goalTitle'.tr,
          isRequired: true,
          hintText: 'goals.create.titleHint'.tr,
          autofocus: true,
          textInputAction: TextInputAction.next,
          accentColor: const Color(0xFF22C55E),
          leadingIcon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Description Field
        CreationTextField(
          controller: _descriptionController,
          label: 'goals.create.descriptionOptional'.tr,
          hintText: 'goals.create.descriptionHint'.tr,
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          accentColor: const Color(0xFF22C55E),
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

        // Goal Type Selector (4 Card options in a row)
        CreationSectionLabel(label: 'goals.create.type'.tr),
        Row(
          children: _goalTypes.map((type) {
            final isSelected = _goalType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SelectionOptionCard(
                  label: _goalTypeLabel(type),
                  isSelected: isSelected,
                  accentColor: const Color(0xFF22C55E),
                  icon: _goalTypeIcon(type, isSelected),
                  onTap: () => setState(() => _goalType = type),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Target & Deadline (Dual compact cards)
        CreationSectionLabel(label: 'goals.create.targetAndDeadline'.tr),
        Row(
          children: [
            // Target Card
            Expanded(
              child: CreationPickerCard(
                leadingIcon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.adjust_rounded,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                ),
                title: 'goals.create.target'.tr,
                subtitle: _targetController.text.trim().isEmpty
                    ? 'goals.create.targetHint'.tr
                    : _targetController.text.trim(),
                onTap: _pickTarget,
                showTrailingArrow: false,
                onClear: _targetController.text.trim().isNotEmpty
                    ? () => setState(() => _targetController.clear())
                    : null,
              ),
            ),
            const SizedBox(width: 10),

            // Deadline Card
            Expanded(
              child: CreationPickerCard(
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
                title: 'goals.create.deadline'.tr,
                subtitle: _deadline == null
                    ? 'goals.create.noDeadline'.tr
                    : _formatDate(_deadline!),
                onTap: _pickDeadline,
                showTrailingArrow: false,
                onClear: _deadline != null
                    ? () => setState(() => _deadline = null)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Milestones Card
        CreationMilestonesCard(
          milestones: _pendingMilestones,
          onAddMilestone: _showAddMilestoneDialog,
          onQuickAdd: (title) => setState(() => _pendingMilestones.add(title)),
          onRemoveMilestone: (index) =>
              setState(() => _pendingMilestones.removeAt(index)),
        ),
        const SizedBox(height: AppSpacing.md),

        // Motivation Card
        CreationMotivationCard(
          title: 'goals.create.motivationTitle'.tr,
          subtitle: 'goals.create.motivationSubtitle'.tr,
          isGreen: true,
        ),
      ],
    );
  }
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


class _TargetInputDialog extends StatefulWidget {
  const _TargetInputDialog({this.initialValue});

  final String? initialValue;

  @override
  State<_TargetInputDialog> createState() => _TargetInputDialogState();
}

class _TargetInputDialogState extends State<_TargetInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'goals.create.target'.tr,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'goals.create.targetHint'.tr,
          hintStyle: TextStyle(color: colors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF22C55E),
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'common.cancel'.tr,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.ctaBackground,
            foregroundColor: colors.ctaForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text('common.save'.tr),
        ),
      ],
    );
  }
}

class _CreateMilestoneDialog extends StatefulWidget {
  const _CreateMilestoneDialog();

  @override
  State<_CreateMilestoneDialog> createState() => _CreateMilestoneDialogState();
}

class _CreateMilestoneDialogState extends State<_CreateMilestoneDialog> {
  late final TextEditingController _controller;

  static const List<String> _suggestions = [
    'Research & Scope',
    'Draft Outline',
    'Core Prototype',
    'Review & Polish',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  void _applySuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'goals.create.milestoneDialogTitle'.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'goals.create.milestonesSubtitle'.tr,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Suggestion Chips
            Text(
              'goals.create.quickSuggestions'.tr,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _applySuggestion(suggestion),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF7E22CE).withValues(alpha: 0.2)
                              : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                                : const Color(0xFFD8B4FE),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 12,
                              color: Color(0xFF9333EA),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              suggestion,
                              style: const TextStyle(
                                color: Color(0xFF9333EA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 160,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? colors.surfaceSecondary
                    : const Color(0xFFFAF5FF).withValues(alpha: 0.6),
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF9333EA),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                        ),
                        color: colors.textMuted,
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                hintText: 'goals.create.milestoneDialogHint'.tr,
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                ),
                counterStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF9333EA),
                    width: 1.8,
                  ),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'common.cancel'.tr,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF9333EA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text('common.add'.tr),
        ),
      ],
    );
  }
}
