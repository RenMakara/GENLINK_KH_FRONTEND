import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'focus_circular_timer.dart';

class FocusRunningView extends StatelessWidget {
  const FocusRunningView({
    super.key,
    required this.session,
    required this.remainingSeconds,
    required this.actionLoading,
    required this.onBack,
    required this.onPause,
    required this.onLeave,
    this.onComplete,
  });

  final ProductivityFocusSession session;
  final int remainingSeconds;
  final bool actionLoading;
  final Future<void> Function() onBack;
  final Future<void> Function() onPause;
  final Future<void> Function() onLeave;
  final Future<void> Function()? onComplete;

  String _formatElapsed(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final plannedSeconds = session.durationMinutes * 60;
    final progress = plannedSeconds == 0
        ? 0.0
        : (1.0 - (remainingSeconds / plannedSeconds)).clamp(0.0, 1.0);

    final modeUpper = (session.mode ?? 'POMODORO').toUpperCase();
    final modeTitle = modeUpper == 'DEEP_FOCUS'
        ? 'focus.modeDeepFocus'.tr
        : (modeUpper == 'LONG_FOCUS'
            ? 'focus.modeLongFocus'.tr
            : 'focus.modePomodoro'.tr);

    final elapsedSeconds = (plannedSeconds - remainingSeconds).clamp(0, plannedSeconds);

    return Scaffold(
      backgroundColor: semantic.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => unawaited(onBack())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'focus.title'.tr,
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 6),

                    // Motivational copy
                    Text(
                      'focus.stayFocusedQuote'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Circular Countdown Timer (Visual Hero)
                    FocusCircularTimer(
                      progress: progress,
                      remainingSeconds: remainingSeconds,
                      isPaused: false,
                      modeTitle: modeTitle,
                      durationMinutes: session.durationMinutes,
                      size: 240,
                    ),
                    const SizedBox(height: 28),

                    // Motivational quote card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                            size: 24,
                            color: AppColors.productivityAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'focus.runningQuote'.tr,
                              style: TextStyle(
                                color: semantic.secondaryText,
                                fontSize: 12,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Controls Row (Pause + Leave)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pause Button
                        _ControlButton(
                          icon: Icons.pause_rounded,
                          label: 'focus.pause'.tr,
                          isPrimary: true,
                          isLoading: actionLoading,
                          onTap: onPause,
                        ),
                        const SizedBox(width: 36),

                        // Leave / Stop Button
                        _ControlButton(
                          icon: Icons.stop_rounded,
                          label: 'focus.leave'.tr,
                          isPrimary: false,
                          isLoading: actionLoading,
                          onTap: onLeave,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Current Session Status Footer Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                          // Status indicator dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Status text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'focus.currentSession'.tr,
                                  style: TextStyle(
                                    color: semantic.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${'focus.activeSession'.tr} • ${_formatTime(session.startedAt)}',
                                  style: TextStyle(
                                    color: semantic.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Elapsed
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'focus.elapsed'.tr,
                                style: TextStyle(
                                  color: semantic.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatElapsed(elapsedSeconds),
                                style: TextStyle(
                                  color: semantic.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isPrimary
        ? AppColors.productivityAccent
        : (isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.lightSurfacePrimary);

    final fgColor = isPrimary ? Colors.white : semantic.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => unawaited(onTap()),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isPrimary
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.darkBorderSubtle
                              : AppColors.lightBorderStrong,
                        ),
                  boxShadow: isPrimary
                      ? [
                          BoxShadow(
                            color: AppColors.productivityAccent.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fgColor,
                          ),
                        )
                      : Icon(icon, color: fgColor, size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: semantic.secondaryText,
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
