import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import '../screens/focus_history_screen.dart';
import 'focus_duration_sheet.dart';

class FocusHomeView extends StatelessWidget {
  const FocusHomeView({
    super.key,
    required this.controller,
    required this.selectedDuration,
    required this.isLoading,
    required this.onDurationChanged,
    required this.onStart,
    required this.onBack,
  });

  final ProductivityController controller;
  final int selectedDuration;
  final bool isLoading;
  final ValueChanged<int> onDurationChanged;
  final Future<void> Function() onStart;
  final VoidCallback onBack;

  static const _durations = [25, 50, 90];

  String _formatTodayMinutes(int minutes) {
    if (minutes < 60) return '$minutes ${'focus.minutesShort'.tr}';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: semantic.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBackButton(onPressed: onBack),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'focus.title'.tr,
                          style: TextStyle(
                            color: semantic.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'focus.tagline'.tr,
                          style: TextStyle(
                            color: semantic.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Motivation Banner
              _InspirationBanner(isDark: isDark),
              const SizedBox(height: 16),

              // Today Summary Card
              _TodayStatsCard(
                controller: controller,
                formatMinutes: _formatTodayMinutes,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Duration Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'focus.durationTitle'.tr,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selected = await FocusDurationSheet.show(
                        context,
                        initialDuration: selectedDuration,
                      );
                      if (selected != null) onDurationChanged(selected);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Duration Cards Row (25, 50, 90)
              Row(
                children: [
                  for (int i = 0; i < _durations.length; i++) ...[
                    Expanded(
                      child: _DurationSegmentCard(
                        minutes: _durations[i],
                        isSelected: selectedDuration == _durations[i],
                        onTap: () => onDurationChanged(_durations[i]),
                      ),
                    ),
                    if (i < _durations.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Primary CTA: Start Focus Button
              _StartFocusButton(
                enabled: !isLoading && !controller.isFocusActionLoading.value,
                onTap: onStart,
              ),
              const SizedBox(height: 24),

              // Recent Sessions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'focus.recentSessions'.tr,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => FocusHistoryScreen(controller: controller));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'focus.seeAll'.tr,
                            style: const TextStyle(
                              color: AppColors.productivityAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.productivityAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recent Sessions List
              _RecentSessionsList(controller: controller, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspirationBanner extends StatelessWidget {
  const _InspirationBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderSubtle
              : AppColors.lightBorderSubtle,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 26,
            color: AppColors.productivityAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'focus.smallStepsQuote'.tr,
              style: TextStyle(
                color: semantic.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Color(0xFF22C55E),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStatsCard extends StatelessWidget {
  const _TodayStatsCard({
    required this.controller,
    required this.formatMinutes,
    required this.isDark,
  });

  final ProductivityController controller;
  final String Function(int) formatMinutes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Obx(() {
      final stats = controller.focusStats.value;
      final sessionsCount = stats?.todaySessions ?? 0;
      final totalMinutes = stats?.todayMinutes ?? 0;
      final totalXp = stats?.totalXp ?? 0;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfacePrimary
              : AppColors.lightSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
          ),
        ),
        child: Row(
          children: [
            // 1. Sessions
            Expanded(
              child: _StatColumn(
                icon: Icons.stars_rounded,
                iconColor: AppColors.productivityAccent,
                value: '$sessionsCount',
                label: 'focus.todayStat'.tr,
                semantic: semantic,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),

            // 2. Focused Time
            Expanded(
              child: _StatColumn(
                icon: Icons.access_time_filled_rounded,
                iconColor: const Color(0xFF22C55E),
                value: formatMinutes(totalMinutes),
                label: 'focus.totalTime'.tr,
                semantic: semantic,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),

            // 3. XP Earned
            Expanded(
              child: _StatColumn(
                icon: Icons.diamond_rounded,
                iconColor: const Color(0xFF388BFD),
                value: '$totalXp',
                label: 'focus.xpEarned'.tr,
                semantic: semantic,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.semantic,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: semantic.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: semantic.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DurationSegmentCard extends StatelessWidget {
  const _DurationSegmentCard({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 68,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.productivityAccent
                : (isDark
                    ? AppColors.darkSurfacePrimary
                    : AppColors.lightSurfacePrimary),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? AppColors.productivityAccent
                  : (isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.productivityAccent.withValues(
                        alpha: 0.30,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes',
                style: TextStyle(
                  color: isSelected ? Colors.white : semantic.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'focus.minutesShort'.tr,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.90)
                      : semantic.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartFocusButton extends StatefulWidget {
  const _StartFocusButton({required this.enabled, required this.onTap});

  final bool enabled;
  final Future<void> Function() onTap;

  @override
  State<_StartFocusButton> createState() => _StartFocusButtonState();
}

class _StartFocusButtonState extends State<_StartFocusButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading || !widget.enabled) return;
    setState(() => _loading = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: widget.enabled && !_loading ? _handleTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.productivityAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            AppColors.productivityAccent.withValues(alpha: 0.45),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        elevation: 2,
        shadowColor: AppColors.productivityAccent.withValues(alpha: 0.35),
      ),
      child: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 22),
                const SizedBox(width: 8),
                Text(
                  'focus.startFocusSession'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({required this.controller, required this.isDark});

  final ProductivityController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Obx(() {
      if (controller.isFocusHistoryLoading.value) {
        return Container(
          width: double.infinity,
          height: 90,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfacePrimary
                : AppColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final completed = controller.focusHistory
          .where((s) => s.isCompleted)
          .take(4)
          .toList(growable: false);

      if (completed.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfacePrimary
                : AppColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),
          ),
          child: Text(
            'focus.noSessionsYet'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: semantic.textMuted, fontSize: 13),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfacePrimary
              : AppColors.lightSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
          ),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: completed.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
          ),
          itemBuilder: (context, index) {
            final session = completed[index];
            return _RecentSessionRow(session: session);
          },
        ),
      );
    });
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.session});

  final ProductivityFocusSession session;

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final prefix = isToday ? '${'focus.today'.tr} ' : '';

    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$prefix$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final modeUpper = (session.mode ?? 'POMODORO').toUpperCase();
    final isDeep = modeUpper == 'DEEP_FOCUS';
    final isLong = modeUpper == 'LONG_FOCUS';

    final icon = isDeep
        ? Icons.psychology_rounded
        : (isLong ? Icons.landscape_rounded : Icons.timer_outlined);

    final iconBgColor = isDeep
        ? AppColors.productivityAccent.withValues(alpha: 0.12)
        : (isLong
            ? const Color(0xFF388BFD).withValues(alpha: 0.12)
            : const Color(0xFFFF5252).withValues(alpha: 0.12));

    final iconColor = isDeep
        ? AppColors.productivityAccent
        : (isLong ? const Color(0xFF388BFD) : const Color(0xFFFF5252));

    final modeTitle = isDeep
        ? 'focus.modeDeepFocus'.tr
        : (isLong ? 'focus.modeLongFocus'.tr : 'focus.modePomodoro'.tr);

    final durationMinutes = session.durationMinutes > 0
        ? session.durationMinutes
        : (session.focusedSeconds ~/ 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Title & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeTitle,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(session.endedAt ?? session.startedAt),
                  style: TextStyle(
                    color: semantic.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Duration & XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$durationMinutes ${'focus.minutesShort'.tr}',
                style: TextStyle(
                  color: semantic.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+${session.xpEarned} XP',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Green checkmark
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 20,
          ),
        ],
      ),
    );
  }
}
