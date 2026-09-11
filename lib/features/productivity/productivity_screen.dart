import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../design_system/colors/app_colors.dart';
import 'domain/entities/productivity_entities.dart';
import 'presentation/controllers/productivity_controller.dart';
import 'presentation/focus_feature/focus_home_screen.dart';
import 'presentation/goals_plan/goal_plan.dart';
import 'presentation/goals_plan/goal_plan_create.dart';
import 'presentation/productivity_scope.dart';
import 'presentation/screens/create_habit_screen.dart';
import 'presentation/screens/create_task_screen.dart';
import 'presentation/task_feature/task_home_screen.dart';

class ProductivityPage extends StatefulWidget {
  const ProductivityPage({super.key});

  @override
  State<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends State<ProductivityPage> {
  ProductivityController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableView();

    return Obx(() {
      final dashboard = controller.dashboard.value;
      if (controller.isLoading.value && dashboard == null) {
        return const _LoadingView();
      }
      if (dashboard == null) {
        return _ErrorView(
          message:
              controller.errorMessage.value ??
              'Unable to load productivity data.',
          onRetry: controller.load,
        );
      }
      return _DashboardView(controller: controller, dashboard: dashboard);
    });
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.controller, required this.dashboard});

  final ProductivityController controller;
  final ProductivityDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    final completedToday =
        dashboard.tasks.completed + dashboard.habits.checkedInToday;
    final totalToday = dashboard.tasks.total + dashboard.habits.total;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.productivityAccent,
          backgroundColor: colors.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            children: [
              _Header(
                onNotifications: () => Get.toNamed(AppRoutes.notifications),
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                completedToday: completedToday,
                totalToday: totalToday,
                focusMinutes: dashboard.focus.todayMinutes,
                habitStreak: controller.habits.isEmpty
                    ? null
                    : controller.habits
                          .map((habit) => habit.streakCount)
                          .reduce((a, b) => a > b ? a : b),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'productivity.todayplan'.tr,
                action: 'productivity.seeall'.tr,
                onTap: () => Get.to(() => const TasksPage()),
              ),
              const SizedBox(height: 9),
              _TodayTasks(controller: controller),
              const SizedBox(height: 18),
              _SectionHeader(title: 'productivity.quickActions'.tr),
              const SizedBox(height: 10),
              _QuickActions(controller: controller),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'productivity.goalProgress'.tr,
                action: 'productivity.seeall'.tr,
                onTap: () => Get.to(() => const PlanGoalScreen()),
              ),
              const SizedBox(height: 9),
              _GoalProgress(goals: dashboard.goals),
              if (dashboard.motivation != null) ...[
                const SizedBox(height: 18),
                _MotivationCard(motivation: dashboard.motivation!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'productivity.title'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: onNotifications,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.completedToday,
    required this.totalToday,
    required this.focusMinutes,
    required this.habitStreak,
  });

  final int completedToday;
  final int totalToday;
  final int focusMinutes;
  final int? habitStreak;

  @override
  Widget build(BuildContext context) {
    final double percent = totalToday == 0
        ? 0
        : (completedToday / totalToday).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.productivityAccent],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'productivity.today'.tr,
            style: TextStyle(color: Colors.white.withValues(alpha: .72)),
          ),
          const SizedBox(height: 5),
          const Text(
            'Keep building momentum 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryStat(
                value: '$completedToday/$totalToday',
                label: 'Tasks',
              ),
              _SummaryStat(value: _formatMinutes(focusMinutes), label: 'Focus'),
              _SummaryStat(
                value: habitStreak == null ? '—' : '$habitStreak days',
                label: 'Streak',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.controller});

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    final visible = controller.tasks.take(3).toList(growable: false);
    if (visible.isEmpty) {
      return const _EmptyCard(
        icon: Icons.checklist_rounded,
        message: 'No tasks yet. Add one to get started.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (int index = 0; index < visible.length; index++) ...[
            ListTile(
              onTap: () => controller.toggleTask(
                visible[index].taskId,
                completed: !visible[index].completed,
              ),
              leading: Icon(
                visible[index].completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: visible[index].completed
                    ? AppColors.success
                    : colors.textMuted,
              ),
              title: Text(
                visible[index].title,
                style: TextStyle(
                  color: colors.textPrimary,
                  decoration: visible[index].completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                _taskSubtitle(visible[index]),
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ),
            if (index < visible.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'productivity.addTask'.tr,
        Icons.add_task_rounded,
        () async {
          await Get.to(() => const CreateTaskScreen());
          await controller.reload();
        },
      ),
      (
        'productivity.addHabit'.tr,
        Icons.local_fire_department_outlined,
        () async {
          await Get.to(() => const CreateHabitScreen());
          await controller.reload();
        },
      ),
      (
        'productivity.focus'.tr,
        Icons.timer_outlined,
        () async {
          await Get.to(() => const FocusPage());
        },
      ),
      (
        'productivity.newGoal'.tr,
        Icons.flag_outlined,
        () async {
          await Get.to(() => const CreateGoalScreen());
          await controller.reload();
        },
      ),
    ];
    return Row(
      children: [
        for (int index = 0; index < actions.length; index++) ...[
          Expanded(
            child: _ActionButton(
              title: actions[index].$1,
              icon: actions[index].$2,
              onTap: actions[index].$3,
            ),
          ),
          if (index < actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 86,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.productivityAccent),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textPrimary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({required this.goals});

  final List<ProductivityGoalProgress> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const _EmptyCard(
        icon: Icons.flag_outlined,
        message: 'No goals yet. Create one to track your progress.',
      );
    }
    final colors = _ProductivityColors(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (int index = 0; index < goals.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    goals[index].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
                Text(
                  '${goals[index].progressPercentage.round()}%',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(
              value: (goals[index].progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              borderRadius: BorderRadius.circular(20),
              color: AppColors.productivityAccent,
              backgroundColor: colors.surfaceSecondary,
            ),
            if (index < goals.length - 1) const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.motivation});

  final ProductivityMotivationCard motivation;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.productivityAccent.withValues(alpha: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.productivityAccent,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motivation.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  motivation.content,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text('common.retry'.tr)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Productivity is available after sign-in.')),
    );
  }
}

class _ProductivityColors {
  _ProductivityColors(BuildContext context)
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

String _taskSubtitle(ProductivityTask task) {
  if (task.overdue) return 'Overdue';
  if (task.dueDate == null) return task.category ?? 'No due date';
  return 'Due ${_formatDateTime(task.dueDate!)}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.month}/${local.day} $hour:$minute $period';
}

String _formatMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}
