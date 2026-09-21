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
    final controller = TextEditingController(text: _targetController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = FormThemeColors(ctx);
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
            controller: controller,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'common.cancel'.tr,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
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
      },
    );

    if (result != null) {
      setState(() => _targetController.text = result);
    }
  }

  Future<void> _showAddMilestoneDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = FormThemeColors(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'goals.create.milestoneDialogTitle'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'goals.create.milestoneNotice'.tr,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'goals.create.milestoneDialogHint'.tr,
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
                      color: Color(0xFF9333EA),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'common.cancel'.tr,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('common.add'.tr),
            ),
          ],
        );
      },
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
