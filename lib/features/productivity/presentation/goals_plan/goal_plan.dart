import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import 'goal_plan_create.dart';
import 'goal_plan_detail.dart';

class PlanGoalScreen extends StatefulWidget {
  const PlanGoalScreen({super.key});

  @override
  State<PlanGoalScreen> createState() => _PlanGoalScreenState();
}

class _PlanGoalScreenState extends State<PlanGoalScreen> {
  ProductivityController? _controller;
  String _category = 'All';

  static const _categories = ['All', 'Personal', 'Career', 'Skill', 'Finance'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  Future<void> _createGoal() async {
    await Get.to(() => const CreateGoalScreen());
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableGoalsView();

    final colors = _GoalColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.goals.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final goals = controller.goals
          .where((goal) {
            if (_category == 'All') return true;
            return goal.goalType?.toUpperCase() == _category.toUpperCase();
          })
          .toList(growable: false);

      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: const Text('Goals Plan'),
          actions: [
            IconButton(
              onPressed: _createGoal,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create goal',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.productivityAccent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _CategoryChips(
                selected: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My goals',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${goals.length}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                _EmptyGoals(onCreate: _createGoal)
              else
                ...goals.map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GoalTile(
                      goal: goal,
                      onTap: () async {
                        await Get.to(() => GoalDetailScreen(goal: goal));
                        await controller.reload();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _PlanGoalScreenState._categories
            .map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected == category,
                  onSelected: (_) => onChanged(category),
                  selectedColor: AppColors.productivityAccent,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onTap});

  final ProductivityGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _GoalColors(context);
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${goal.progressPercentage.round()}%',
                  style: TextStyle(
                    color: AppColors.productivityAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${goal.goalType ?? 'Personal'} · ${_statusLabel(goal.status)}',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(20),
              color: AppColors.productivityAccent,
              backgroundColor: colors.surfaceSecondary,
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 9),
              Text(
                'Due ${_formatDate(goal.deadline!)}',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = _GoalColors(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, color: colors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            'No goals yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a goal and break it into milestones.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onCreate, child: const Text('Create goal')),
        ],
      ),
    );
  }
}

class _UnavailableGoalsView extends StatelessWidget {
  const _UnavailableGoalsView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sign in to manage goals.')),
    );
  }
}

class _GoalColors {
  _GoalColors(BuildContext context)
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

String _statusLabel(String status) => switch (status) {
  'COMPLETED' => 'Completed',
  'IN_PROGRESS' => 'In progress',
  _ => 'Not started',
};

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Kept for compatibility with older callers of the original mock screens.
class GoalModel {
  GoalModel({
    required this.category,
    required this.title,
    required this.progress,
    required this.dueDate,
  });

  final String category;
  final String title;
  final double progress;
  final String dueDate;
}
