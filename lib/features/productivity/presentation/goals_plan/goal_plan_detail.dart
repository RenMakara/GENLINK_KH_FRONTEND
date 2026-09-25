import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final ProductivityGoal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  ProductivityController? _controller;
  late ProductivityGoal _goal = widget.goal;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final goal = await controller.refreshGoal(widget.goal.goalId);
      if (mounted) setState(() => _goal = goal);
    } catch (_) {
      // The list payload remains usable if the detail request is unavailable.
    }
  }

  Future<void> _toggleMilestone(ProductivityMilestone milestone) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final goal = await controller.toggleMilestone(
        goalId: _goal.goalId,
        milestoneId: milestone.milestoneId,
        completed: !milestone.completed,
      );
      if (mounted) setState(() => _goal = goal);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addMilestone() async {
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddMilestoneDialog(),
    );
    if (title == null || title.trim().isEmpty) return;

    final controller = _controller;
    if (controller == null) return;
    try {
      final goal = await controller.addMilestone(
        goalId: _goal.goalId,
        title: title.trim(),
      );
      if (mounted) setState(() => _goal = goal);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteMilestone(ProductivityMilestone milestone) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'goals.detail.deleteMilestoneTitle'.tr,
      message: 'goals.detail.deleteMilestoneMessage'
          .trParams({'title': milestone.title}),
      confirmLabel: 'common.delete'.tr,
      cancelLabel: 'common.cancel'.tr,
    );
    if (!confirmed || _controller == null) return;
    try {
      final goal = await _controller!.deleteMilestone(
        goalId: _goal.goalId,
        milestoneId: milestone.milestoneId,
      );
      if (mounted) setState(() => _goal = goal);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'goals.detail.deleteGoalTitle'.tr,
      message: 'goals.detail.deleteGoalMessage'.tr,
      confirmLabel: 'common.delete'.tr,
      cancelLabel: 'common.cancel'.tr,
    );
    if (!confirmed || _controller == null) return;
    try {
      await _controller!.deleteGoal(_goal.goalId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorText(error))));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _GoalDetailColors(context);
    final progress = (_goal.progressPercentage / 100).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text('goals.detail.title'.tr),
        actions: [
          IconButton(
            onPressed: _deleteGoal,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'goals.detail.deleteGoal'.tr,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        color: AppColors.productivityAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _goal.goalType ?? 'Personal',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '${_goal.progressPercentage.round()}%',
                        style: const TextStyle(
                          color: AppColors.productivityAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _goal.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_goal.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 7),
                    Text(
                      _goal.description!,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                  if (_goal.deadline != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'goals.detail.deadline'
                          .trParams({'date': _formatDate(_goal.deadline!)}),
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.productivityAccent,
                    backgroundColor: colors.surfaceSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? const Color(0xFF7E22CE).withValues(alpha: 0.35)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFF9333EA),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'goals.detail.milestones'.tr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? const Color(0xFF7E22CE).withValues(alpha: 0.25)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.isDark
                          ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                          : const Color(0xFFD8B4FE),
                    ),
                  ),
                  child: Text(
                    '${_goal.completedMilestones}/${_goal.totalMilestones}',
                    style: const TextStyle(
                      color: Color(0xFF9333EA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _addMilestone,
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'goals.detail.addMilestone'.tr,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_goal.milestones.isEmpty)
              _EmptyMilestones(
                colors: colors,
                onAddMilestone: _addMilestone,
              )
            else
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      if (_goal.totalMilestones > 0) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_goal.completedMilestones} of ${_goal.totalMilestones} completed',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${((_goal.completedMilestones / _goal.totalMilestones) * 100).round()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF9333EA),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_goal.completedMilestones /
                                          _goal.totalMilestones)
                                      .clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: colors.surfaceSecondary,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF9333EA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                      ],
                      for (
                        int index = 0;
                        index < _goal.milestones.length;
                        index++
                      ) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          onTap: () =>
                              _toggleMilestone(_goal.milestones[index]),
                          leading: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _goal.milestones[index].completed
                                  ? AppColors.success
                                  : colors.surfaceSecondary,
                              border: Border.all(
                                color: _goal.milestones[index].completed
                                    ? AppColors.success
                                    : colors.border,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _goal.milestones[index].completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          title: Text(
                            _goal.milestones[index].title,
                            style: TextStyle(
                              color: _goal.milestones[index].completed
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              decoration: _goal.milestones[index].completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                _deleteMilestone(_goal.milestones[index]),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        if (index < _goal.milestones.length - 1)
                          Divider(height: 1, color: colors.border),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMilestones extends StatelessWidget {
  const _EmptyMilestones({
    required this.colors,
    this.onAddMilestone,
  });

  final _GoalDetailColors colors;
  final VoidCallback? onAddMilestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.isDark
                  ? const Color(0xFF7E22CE).withValues(alpha: 0.25)
                  : const Color(0xFFF3E8FF),
              border: Border.all(
                color: colors.isDark
                    ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                    : const Color(0xFFD8B4FE),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flag_rounded,
              color: Color(0xFF9333EA),
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'goals.detail.noMilestones'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'goals.detail.milestonesEmptyDesc'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (onAddMilestone != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddMilestone,
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: Color(0xFF9333EA),
              ),
              label: Text(
                'goals.detail.addFirstMilestone'.tr,
                style: const TextStyle(
                  color: Color(0xFF9333EA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colors.isDark
                      ? const Color(0xFFA855F7).withValues(alpha: 0.5)
                      : const Color(0xFFD8B4FE),
                ),
                backgroundColor: colors.isDark
                    ? const Color(0xFF7E22CE).withValues(alpha: 0.2)
                    : const Color(0xFFFAF5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalDetailColors {
  _GoalDetailColors(BuildContext context)
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
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _errorText(Object error) =>
    error.toString().replaceFirst('AppError(', '').split('):').last.trim();


class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog();

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  late final TextEditingController _controller;

  static const List<String> _suggestions = [
    'Research & Plan',
    'Draft Outline',
    'Core Prototype',
    'Review & Testing',
    'Final Launch',
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
    final colors = _GoalDetailColors(context);
    final isDark = colors.isDark;

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
                  'goals.detail.addMilestone'.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'goals.detail.milestoneDialogSubtitle'.tr,
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
                    ? AppColors.darkSurfaceSecondary
                    : const Color(0xFFFAF5FF).withValues(alpha: 0.6),
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF9333EA),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        color: colors.textMuted,
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                hintText: 'goals.detail.milestoneHint'.tr,
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
