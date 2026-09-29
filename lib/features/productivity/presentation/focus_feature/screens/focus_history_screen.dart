import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';

class FocusHistoryScreen extends StatelessWidget {
  const FocusHistoryScreen({super.key, required this.controller});

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: semantic.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'focus.recentSessions'.tr,
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfacePrimary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'focus.all'.tr,
                          style: TextStyle(
                            color: semantic.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: semantic.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: Obx(() {
                if (controller.isFocusHistoryLoading.value &&
                    controller.focusHistory.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final completed = controller.focusHistory
                    .where((s) => s.isCompleted)
                    .toList(growable: false);

                if (completed.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: semantic.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'focus.noSessionsYet'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: semantic.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by date
                final groups = _groupByDate(completed);

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 280 &&
                        controller.focusHistoryHasMore.value &&
                        !controller.isFocusHistoryLoading.value) {
                      controller.loadNextFocusHistoryPage();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => controller.loadFocusHistory(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount:
                          groups.length +
                          (controller.focusHistoryHasMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= groups.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: controller.isFocusHistoryLoading.value
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        final group = groups[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 14,
                                bottom: 8,
                                left: 4,
                              ),
                              child: Text(
                                group.dateLabel,
                                style: TextStyle(
                                  color: semantic.secondaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfacePrimary
                                    : AppColors.lightSurfacePrimary,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorderSubtle
                                      : AppColors.lightBorderSubtle,
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: group.sessions.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: isDark
                                      ? AppColors.darkBorderSubtle
                                      : AppColors.lightBorderSubtle,
                                ),
                                itemBuilder: (context, sIndex) {
                                  final session = group.sessions[sIndex];
                                  return _HistorySessionRow(session: session);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<ProductivityFocusSession> sessions) {
    final map = <String, List<ProductivityFocusSession>>{};
    for (final s in sessions) {
      final date = s.endedAt ?? s.startedAt;
      final label = _dateHeader(date);
      map.putIfAbsent(label, () => []).add(s);
    }
    return map.entries
        .map((e) => _DateGroup(dateLabel: e.key, sessions: e.value))
        .toList();
  }

  String _dateHeader(DateTime? date) {
    if (date == null) return 'focus.recent'.tr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'focus.today'.tr;
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (sessionDate == yesterday) {
      return '${'focus.yesterday'.tr} • ${_monthName(date.month)} ${date.day}, ${date.year}';
    }
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class _DateGroup {
  const _DateGroup({required this.dateLabel, required this.sessions});
  final String dateLabel;
  final List<ProductivityFocusSession> sessions;
}

class _HistorySessionRow extends StatelessWidget {
  const _HistorySessionRow({required this.session});

  final ProductivityFocusSession session;

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

    final timeString = _formatTime(session.endedAt ?? session.startedAt);
    final focusedSeconds = session.focusedSeconds.clamp(0, 1 << 31);
    final focusedMinutes = focusedSeconds ~/ 60;
    final durationLabel = focusedMinutes > 0
        ? '$focusedMinutes ${'focus.minutesShort'.tr} ${focusedSeconds % 60} ${'focus.secondsShort'.tr}'
        : '$focusedSeconds ${'focus.secondsShort'.tr}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Mode Icon
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
                  timeString,
                  style: TextStyle(color: semantic.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Duration & XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                durationLabel,
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

          // Completion checkmark
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
