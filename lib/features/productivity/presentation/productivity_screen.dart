import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ProductivityPage extends StatelessWidget {
  const ProductivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ============================================================
    // APP COLORS
    // Same color system used by Finance
    // ============================================================

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,

      // No bottom navigation bar
      // No floating action button
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================================================
              // HEADER
              // ====================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productivity',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  Row(
                    children: [
                      // Notification
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Profile
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'R',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ====================================================
              // DAILY SUMMARY
              // ====================================================
              _buildDailySummary(
                isDark: isDark,
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              // ====================================================
              // TODAY'S PLAN
              // ====================================================
              _buildTodayPlan(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              // ====================================================
              // QUICK ACTIONS
              // ====================================================
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              _buildQuickActions(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 20),

              // ====================================================
              // WEEKLY FOCUS
              // ====================================================
              _buildWeeklyFocus(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              // ====================================================
              // GOAL PROGRESS
              // ====================================================
              _buildGoalProgress(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              // ====================================================
              // SMART INSIGHT
              // ====================================================
              _buildSmartInsight(
                isDark: isDark,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                border: border,
              ),

              const SizedBox(height: 16),

              // ====================================================
              // RECENT ACTIVITY
              // ====================================================
              _buildRecentActivity(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // DAILY SUMMARY
  // ==============================================================

  Widget _buildDailySummary({
    required bool isDark,
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color border,
  }) {
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
            'Wednesday, July 2',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Good morning, Ratha 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildSummaryStat(
                icon: Icons.check_circle_outline_rounded,
                value: '3/5',
                label: 'Tasks',
              ),

              const SizedBox(width: 8),

              _buildSummaryStat(
                icon: Icons.timer_outlined,
                value: '2h 14m',
                label: 'Focus',
              ),

              const SizedBox(width: 8),

              _buildSummaryStat(
                icon: Icons.local_fire_department_outlined,
                value: '7 days',
                label: 'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
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
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // TODAY PLAN
  // ==============================================================

  Widget _buildTodayPlan({
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return _buildCard(
      surface: surface,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today Plan',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'See all →',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _buildTask(
            title: 'Review weekly goals',
            subtitle: 'Completed · 9:00 AM',
            completed: true,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          Divider(height: 22, color: border),

          _buildTask(
            title: 'Deep work block – React',
            subtitle: 'Due · 2:00 PM',
            color: AppColors.productivityAccent,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          Divider(height: 22, color: border),

          _buildTask(
            title: 'Send client report',
            subtitle: 'Due · 5:00 PM',
            color: AppColors.financeAccent,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: .40,
                    minHeight: 6,
                    backgroundColor: surfaceSecondary,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.productivityAccent,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '40%',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            '2 of 5 tasks completed',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTask({
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textMuted,
    Color? color,
    bool completed = false,
  }) {
    return Row(
      children: [
        Icon(
          completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: completed ? AppColors.growthAccent : textMuted,
        ),

        const SizedBox(width: 10),

        if (!completed) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color ?? AppColors.productivityAccent,
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
                title,
                style: TextStyle(
                  color: completed ? textMuted : textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),

              const SizedBox(height: 3),

              Text(subtitle, style: TextStyle(color: textMuted, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // QUICK ACTIONS
  // ==============================================================

  Widget _buildQuickActions({
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return SizedBox(
      height: 92,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildQuickAction(
              icon: Icons.add_task_rounded,
              title: 'Add Task',
              accent: AppColors.brandPrimary,
              surface: surface,
              surfaceSecondary: surfaceSecondary,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
            ),

            const SizedBox(width: 8),

            _buildQuickAction(
              icon: Icons.local_fire_department_outlined,
              title: 'Add Habit',
              accent: AppColors.growthAccent,
              surface: surface,
              surfaceSecondary: surfaceSecondary,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
            ),

            const SizedBox(width: 8),

            _buildQuickAction(
              icon: Icons.timer_outlined,
              title: 'Focus',
              accent: AppColors.productivityAccent,
              surface: surface,
              surfaceSecondary: surfaceSecondary,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
            ),

            const SizedBox(width: 8),

            _buildQuickAction(
              icon: Icons.flag_outlined,
              title: 'New Goal',
              accent: AppColors.financeAccent,
              surface: surface,
              surfaceSecondary: surfaceSecondary,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color accent,
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return Container(
      width: 92,
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // WEEKLY FOCUS
  // ==============================================================

  Widget _buildWeeklyFocus({
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return _buildCard(
      surface: surface,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Focus',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'This week',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '8h 40m',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 7),

              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ 12h goal',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: .72,
              minHeight: 7,
              backgroundColor: surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(AppColors.productivityAccent),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '72% complete',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),

              Text(
                '3h 20m remaining',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // GOAL PROGRESS
  // ==============================================================

  Widget _buildGoalProgress({
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return _buildCard(
      surface: surface,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goal Progress',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'See all →',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildGoal(
            category: 'Skill',
            title: 'Master TypeScript',
            percentage: .62,
            value: '62%',
            accent: AppColors.brandPrimary,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          const SizedBox(height: 17),

          _buildGoal(
            category: 'Health',
            title: 'Daily Exercise',
            percentage: .38,
            value: '38%',
            accent: AppColors.growthAccent,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          const SizedBox(height: 17),

          _buildGoal(
            category: 'Productivity',
            title: 'Read 12 books',
            percentage: .75,
            value: '75%',
            accent: AppColors.productivityAccent,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildGoal({
    required String category,
    required String title,
    required double percentage,
    required String value,
    required Color accent,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
  }) {
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
                    category,
                    style: TextStyle(color: textMuted, fontSize: 9),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              value,
              style: TextStyle(
                color: textPrimary,
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
            value: percentage,
            minHeight: 6,
            backgroundColor: surfaceSecondary,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // SMART INSIGHT
  // ==============================================================

  Widget _buildSmartInsight({
    required bool isDark,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.productivityAccent.withValues(alpha: .08)
            : surface,
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
                  'Smart Insight',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'You are most productive between 9 AM and 11 AM. '
                  'Consider scheduling your hardest task during this time.',
                  style: TextStyle(
                    color: textSecondary,
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

  // ==============================================================
  // RECENT ACTIVITY
  // ==============================================================

  Widget _buildRecentActivity({
    required Color surface,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return _buildCard(
      surface: surface,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          _buildActivity(
            icon: Icons.timer_outlined,
            title: 'Completed Pomodoro session',
            time: '2h ago',
            accent: AppColors.productivityAccent,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          Divider(height: 1, color: border),

          _buildActivity(
            icon: Icons.check_circle_outline_rounded,
            title: 'Task: Weekly review done',
            time: '3h ago',
            accent: AppColors.growthAccent,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          Divider(height: 1, color: border),

          _buildActivity(
            icon: Icons.local_fire_department_outlined,
            title: 'Habit streak +1 — Reading',
            time: '6h ago',
            accent: AppColors.financeAccent,
            surfaceSecondary: surfaceSecondary,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildActivity({
    required IconData icon,
    required String title,
    required String time,
    required Color accent,
    required Color surfaceSecondary,
    required Color textPrimary,
    required Color textMuted,
  }) {
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
            child: Icon(icon, size: 16, color: accent),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(time, style: TextStyle(color: textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  // ==============================================================
  // COMMON CARD
  // ==============================================================

  Widget _buildCard({
    required Widget child,
    required Color surface,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
