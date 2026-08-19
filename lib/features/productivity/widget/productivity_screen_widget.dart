import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

// DATA MODELS
class ProductivityTaskData {
  final String title;
  final String subtitle;
  final bool completed;

  const ProductivityTaskData({
    required this.title,
    required this.subtitle,
    this.completed = false,
  });
}

class ProductivityActionData {
  final IconData icon;
  final String title;

  const ProductivityActionData({required this.icon, required this.title});
}

class ProductivityGoalData {
  final String category;
  final String title;
  final double percentage;
  final String value;

  const ProductivityGoalData({
    required this.category,
    required this.title,
    required this.percentage,
    required this.value,
  });
}

class ProductivityActivityData {
  final IconData icon;
  final String title;
  final String time;

  const ProductivityActivityData({
    required this.icon,
    required this.title,
    required this.time,
  });
}

// THEME COLORS

class _ProductivityColors {
  final bool isDark;

  _ProductivityColors(this.isDark);

  Color get bg => isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

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

// HEADER
class ProductivityHeader extends StatelessWidget {
  final String title;
  final String profileText;

  const ProductivityHeader({
    super.key,
    required this.title,
    required this.profileText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),

        Row(
          children: [
            _HeaderButton(icon: Icons.notifications_none_rounded),

            const SizedBox(width: 10),

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profileText,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;

  const _HeaderButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Icon(icon, size: 22, color: colors.textPrimary),
    );
  }
}

// DAILY SUMMARY
class ProductivitySummary extends StatelessWidget {
  final String date;
  final String greeting;
  final String tasks;
  final String focus;
  final String streak;

  const ProductivitySummary({
    super.key,
    required this.date,
    required this.greeting,
    required this.tasks,
    required this.focus,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.productivityAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _SummaryStat(
                icon: Icons.check_circle_outline_rounded,
                value: tasks,
                label: 'Tasks',
              ),

              const SizedBox(width: 8),

              _SummaryStat(
                icon: Icons.timer_outlined,
                value: focus,
                label: 'Focus',
              ),

              const SizedBox(width: 8),

              _SummaryStat(
                icon: Icons.local_fire_department_outlined,
                value: streak,
                label: 'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 16),

            const SizedBox(height: 7),

            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CARD
class ProductivityCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final Widget child;

  const ProductivityCard({
    super.key,
    required this.title,
    required this.child,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (actionText != null)
                Text(
                  actionText!,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
            ],
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }
}

// SECTION TITLE
class ProductivitySectionTitle extends StatelessWidget {
  final String title;

  const ProductivitySectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// TASK LIST
class ProductivityTaskList extends StatelessWidget {
  final List<ProductivityTaskData> tasks;
  final double progress;
  final String progressText;
  final String footerText;

  const ProductivityTaskList({
    super.key,
    required this.tasks,
    required this.progress,
    required this.progressText,
    required this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Column(
      children: [
        for (int i = 0; i < tasks.length; i++) ...[
          _TaskItem(task: tasks[i]),

          if (i != tasks.length - 1) Divider(height: 22, color: colors.border),
        ],

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colors.surfaceSecondary,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.productivityAccent,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Text(
              progressText,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            footerText,
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final ProductivityTaskData task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        Icon(
          task.completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: task.completed ? AppColors.growthAccent : colors.textMuted,
        ),

        const SizedBox(width: 10),

        if (!task.completed) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.productivityAccent,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  color: task.completed ? colors.textMuted : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                task.subtitle,
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// QUICK ACTIONS
class ProductivityQuickActions extends StatelessWidget {
  final List<ProductivityActionData> actions;

  const ProductivityQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              _QuickAction(action: actions[i], index: i),

              if (i != actions.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final ProductivityActionData action;
  final int index;

  const _QuickAction({required this.action, required this.index});

  Color get accent {
    switch (index) {
      case 0:
        return AppColors.brandPrimary;
      case 1:
        return AppColors.growthAccent;
      case 2:
        return AppColors.productivityAccent;
      default:
        return AppColors.financeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: 92,
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(action.icon, size: 20, color: accent),
          ),

          const SizedBox(height: 7),

          Text(
            action.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// WEEKLY PROGRESS
class ProductivityProgress extends StatelessWidget {
  final String valueText;
  final String goalText;
  final double percentage;
  final String percentageText;
  final String remainingText;

  const ProductivityProgress({
    super.key,
    required this.valueText,
    required this.goalText,
    required this.percentage,
    required this.percentageText,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              valueText,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(width: 7),

            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                goalText,
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: colors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation(AppColors.productivityAccent),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              percentageText,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),

            Text(
              remainingText,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

// GOALS
class ProductivityGoals extends StatelessWidget {
  final List<ProductivityGoalData> goals;

  const ProductivityGoals({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < goals.length; i++) ...[
          _GoalItem(goal: goals[i], index: i),

          if (i != goals.length - 1) const SizedBox(height: 17),
        ],
      ],
    );
  }
}

class _GoalItem extends StatelessWidget {
  final ProductivityGoalData goal;
  final int index;

  const _GoalItem({required this.goal, required this.index});

  Color get accent {
    switch (index) {
      case 0:
        return AppColors.brandPrimary;
      case 1:
        return AppColors.growthAccent;
      default:
        return AppColors.productivityAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.category,
                    style: TextStyle(color: colors.textMuted, fontSize: 9),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    goal.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              goal.value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: goal.percentage,
            minHeight: 6,
            backgroundColor: colors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    );
  }
}

// SMART INSIGHT
class ProductivityInsight extends StatelessWidget {
  final String title;
  final String message;

  const ProductivityInsight({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final isDark = colors.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.productivityAccent.withValues(alpha: .08)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.productivityAccent.withValues(alpha: .40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.productivityAccent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.productivityAccent,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// RECENT ACTIVITIES
class ProductivityActivities extends StatelessWidget {
  final List<ProductivityActivityData> activities;

  const ProductivityActivities({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Column(
      children: [
        for (int i = 0; i < activities.length; i++) ...[
          _ActivityItem(activity: activities[i], index: i),

          if (i != activities.length - 1)
            Divider(height: 1, color: colors.border),
        ],
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ProductivityActivityData activity;
  final int index;

  const _ActivityItem({required this.activity, required this.index});

  Color get accent {
    switch (index) {
      case 0:
        return AppColors.productivityAccent;
      case 1:
        return AppColors.growthAccent;
      default:
        return AppColors.financeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, size: 16, color: accent),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              activity.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(
            activity.time,
            style: TextStyle(color: colors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
