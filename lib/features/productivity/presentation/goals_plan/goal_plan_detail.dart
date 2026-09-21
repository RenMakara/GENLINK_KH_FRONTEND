import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
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
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('goals.detail.addMilestone'.tr),
        content: TextField(
          controller: titleController,
          autofocus: true,
          maxLength: 160,
          decoration: InputDecoration(hintText: 'goals.detail.milestoneHint'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, titleController.text),
            child: Text('productivity.addTask'.tr.split(' ').first),
          ),
        ],
      ),
    );
    titleController.dispose();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('goals.detail.deleteMilestoneTitle'.tr),
        content: Text('goals.detail.deleteMilestoneMessage'
            .trParams({'title': milestone.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('common.delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || _controller == null) return;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('goals.detail.deleteGoalTitle'.tr),
        content: Text('goals.detail.deleteGoalMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('common.delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || _controller == null) return;
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
            const SizedBox(height: 20),
            Row(
              children: [
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
                Text(
                  '${_goal.completedMilestones}/${_goal.totalMilestones}',
                  style: TextStyle(color: colors.textMuted),
                ),
                IconButton(
                  onPressed: _addMilestone,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'goals.detail.addMilestone'.tr,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_goal.milestones.isEmpty)
              _EmptyMilestones(colors: colors)
            else
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    for (
                      int index = 0;
                      index < _goal.milestones.length;
                      index++
                    ) ...[
                      ListTile(
                        onTap: () => _toggleMilestone(_goal.milestones[index]),
                        leading: Icon(
                          _goal.milestones[index].completed
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _goal.milestones[index].completed
                              ? AppColors.success
                              : colors.textMuted,
                        ),
                        title: Text(
                          _goal.milestones[index].title,
                          style: TextStyle(
                            color: colors.textPrimary,
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
          ],
        ),
      ),
    );
  }
}

class _EmptyMilestones extends StatelessWidget {
  const _EmptyMilestones({required this.colors});

  final _GoalDetailColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'goals.detail.noMilestones'.tr,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textSecondary),
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
