import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class FocusCircularTimer extends StatelessWidget {
  const FocusCircularTimer({
    super.key,
    required this.progress,
    required this.remainingSeconds,
    required this.isPaused,
    required this.modeTitle,
    required this.durationMinutes,
    this.size = 236,
    this.strokeWidth = 12,
  });

  final double progress;
  final int remainingSeconds;
  final bool isPaused;
  final String modeTitle;
  final int durationMinutes;
  final double size;
  final double strokeWidth;

  static String formatCountdown(int totalSeconds) {
    final safeSeconds = totalSeconds.clamp(0, 24 * 60 * 60);
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ringColor = isPaused
        ? AppColors.warning
        : AppColors.productivityAccent;

    final trackColor = isPaused
        ? AppColors.warning.withValues(alpha: 0.16)
        : (isDark
            ? AppColors.darkBorderSubtle
            : AppColors.lightBorderSubtle);

    final iconBgColor = isPaused
        ? AppColors.warning.withValues(alpha: 0.14)
        : AppColors.productivityAccent.withValues(alpha: 0.12);

    final iconColor = isPaused
        ? AppColors.warning
        : AppColors.productivityAccent;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Track & Progress Ring
            SizedBox.expand(
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress.clamp(0.0, 1.0),
                  ringColor: ringColor,
                  trackColor: trackColor,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),

            // Inner Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaused
                        ? Icons.pause_rounded
                        : Icons.psychology_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),

                // Large Countdown Digits
                Text(
                  formatCountdown(remainingSeconds),
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),

                // Mode or Paused Status
                Text(
                  isPaused ? 'focus.paused'.tr : modeTitle,
                  style: TextStyle(
                    color: isPaused ? AppColors.warning : semantic.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),

                // Duration subtitle
                Text(
                  '$durationMinutes ${'focus.minutesShort'.tr}',
                  style: TextStyle(
                    color: semantic.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793 / 2; // 12 o'clock
      final sweepAngle = 2 * 3.141592653589793 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
