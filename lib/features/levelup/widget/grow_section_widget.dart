import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/colors/app_colors.dart';

/// Modern Gamified Soft 3D "GROW" Section Widget for the GenLink Level Up screen.
/// Displays a 3x2 grid of vibrant feature cards with soft 3D dimensional vector icons,
/// subtle corner watermarks, and smooth tactile micro-animations.
class GrowSectionWidget extends StatelessWidget {
  const GrowSectionWidget({
    super.key,
    this.onTasksTap,
    this.onHabitsTap,
    this.onGoalsTap,
    this.onFocusTap,
    this.onQuizTap,
    this.onLeaderboardTap,
    this.onExploreAllTap,
  });

  final VoidCallback? onTasksTap;
  final VoidCallback? onHabitsTap;
  final VoidCallback? onGoalsTap;
  final VoidCallback? onFocusTap;
  final VoidCallback? onQuizTap;
  final VoidCallback? onLeaderboardTap;
  final VoidCallback? onExploreAllTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final exploreTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "GROW" and "Explore all >"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'levelup.grow'.tr,
              style: TextStyle(
                color: headerTextColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExploreAllTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'levelup.exploreAll'.tr,
                    style: TextStyle(
                      color: exploreTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: exploreTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3x2 Grid Row 1: Tasks | Habits | Goals
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.tasks'.tr,
                  subtitle: 'levelup.tasksSubtitle'.tr,
                  icon: const Soft3DTasksIcon(size: 40),
                  gradient: const [
                    Color(0xFF5292F7),
                    Color(0xFF2563EB),
                  ],
                  shadowColor: const Color(0xFF2563EB),
                  watermark: const _WaveWatermark(),
                  onTap: onTasksTap,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.habits'.tr,
                  subtitle: 'levelup.habitsSubtitle'.tr,
                  icon: const Soft3DHabitsIcon(size: 40),
                  gradient: const [
                    Color(0xFFFFA26B),
                    Color(0xFFF9683A),
                  ],
                  shadowColor: const Color(0xFFF9683A),
                  watermark: const _LeafWatermark(),
                  onTap: onHabitsTap,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.goals'.tr,
                  subtitle: 'levelup.goalsSubtitle'.tr,
                  icon: const Soft3DGoalsIcon(size: 40),
                  gradient: const [
                    Color(0xFF55E59B),
                    Color(0xFF13AF6A),
                  ],
                  shadowColor: const Color(0xFF13AF6A),
                  watermark: const _MountainWatermark(),
                  onTap: onGoalsTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3x2 Grid Row 2: Focus | Quiz | Leaderboard
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.focus'.tr,
                  subtitle: 'levelup.focusSubtitle'.tr,
                  icon: const Soft3DFocusIcon(size: 40),
                  gradient: const [
                    Color(0xFFC084FC),
                    Color(0xFF7E3FF2),
                  ],
                  shadowColor: const Color(0xFF7E3FF2),
                  watermark: const _RingsWatermark(),
                  onTap: onFocusTap,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.quiz'.tr,
                  subtitle: 'levelup.quizSubtitle'.tr,
                  icon: const Soft3DQuizIcon(size: 40),
                  gradient: const [
                    Color(0xFFFFDD53),
                    Color(0xFFF59E0B),
                  ],
                  shadowColor: const Color(0xFFF59E0B),
                  watermark: const _StarWatermark(),
                  onTap: onQuizTap,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GrowFeatureCard(
                  title: 'levelup.leaderboard'.tr,
                  subtitle: 'levelup.leaderboardSubtitle'.tr,
                  icon: const Soft3DLeaderboardIcon(size: 40),
                  gradient: const [
                    Color(0xFF38BDF8),
                    Color(0xFF0284C7),
                  ],
                  shadowColor: const Color(0xFF0284C7),
                  watermark: const _BarChartWatermark(),
                  onTap: onLeaderboardTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive Gamified Card with soft gradients, 3D icon, white typography,
/// and a subtle decorative corner watermark.
class GrowFeatureCard extends StatefulWidget {
  const GrowFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.watermark,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final List<Color> gradient;
  final Color shadowColor;
  final Widget watermark;
  final VoidCallback? onTap;

  @override
  State<GrowFeatureCard> createState() => _GrowFeatureCardState();
}

class _GrowFeatureCardState extends State<GrowFeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: isDark ? 0.38 : 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle corner watermark
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Opacity(
                    opacity: 0.16,
                    child: widget.watermark,
                  ),
                ),

                // Top-left ambient highlight
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.8, -0.8),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Foreground Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 11, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: 3D Icon + Chevron Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.icon,
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Text Block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 9.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SOFT 3D VECTOR ICONS
// =============================================================================

/// 1. Tasks Soft 3D Icon: White paper clipboard with blue binder clip & checklist
class Soft3DTasksIcon extends StatelessWidget {
  const Soft3DTasksIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TasksIconPainter(),
      ),
    );
  }
}

class _TasksIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Clipboard body
    final clipPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.78),
          Radius.circular(w * 0.16),
        ),
      );

    // Soft drop shadow
    canvas.drawShadow(clipPath, Colors.black.withValues(alpha: 0.20), 3.0, true);

    // Paper gradient
    final paperPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2EDFE)],
      ).createShader(Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.78));
    canvas.drawPath(clipPath, paperPaint);

    // Top Binder Clip
    final clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.08, w * 0.36, h * 0.17),
      Radius.circular(w * 0.08),
    );
    final clipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromLTWH(w * 0.32, h * 0.08, w * 0.36, h * 0.17));
    canvas.drawRRect(clipRRect, clipPaint);

    // Small clip pin
    final pinRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, h * 0.12, w * 0.14, h * 0.07),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(pinRRect, Paint()..color = const Color(0xFFDBEAFE));

    // Checklist Item 1 (Checkbox + Task Line)
    final checkPaint = Paint()..color = const Color(0xFF2563EB);
    final box1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.15, h * 0.15),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(box1, checkPaint);

    final tick1 = Path()
      ..moveTo(w * 0.25, h * 0.45)
      ..lineTo(w * 0.28, h * 0.49)
      ..lineTo(w * 0.34, h * 0.42);
    canvas.drawPath(
      tick1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final line1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, h * 0.43, w * 0.36, h * 0.05),
      const Radius.circular(2),
    );
    canvas.drawRRect(line1, Paint()..color = const Color(0xFF93C5FD));

    // Checklist Item 2 (Checkbox + Task Line)
    final box2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.62, w * 0.15, h * 0.15),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(box2, checkPaint);

    final tick2 = Path()
      ..moveTo(w * 0.25, h * 0.69)
      ..lineTo(w * 0.28, h * 0.73)
      ..lineTo(w * 0.34, h * 0.66);
    canvas.drawPath(
      tick2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final line2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, h * 0.67, w * 0.28, h * 0.05),
      const Radius.circular(2),
    );
    canvas.drawRRect(line2, Paint()..color = const Color(0xFF93C5FD));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Habits Soft 3D Icon: Golden dual curved rotating arrows with dimensional depth
class Soft3DHabitsIcon extends StatelessWidget {
  const Soft3DHabitsIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HabitsIconPainter(),
      ),
    );
  }
}

class _HabitsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.30;
    final strokeW = w * 0.15;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy + 2), radius: radius),
      -math.pi * 0.85,
      math.pi * 0.85,
      false,
      shadowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy + 2), radius: radius),
      math.pi * 0.15,
      math.pi * 0.85,
      false,
      shadowPaint,
    );

    // Warm golden gradient paint
    final arcPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFE65100),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    // Top-right arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.85,
      math.pi * 0.85,
      false,
      arcPaint,
    );

    // Bottom-left arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.15,
      math.pi * 0.85,
      false,
      arcPaint,
    );

    // Arrow head 1 (at bottom-left end of top arc)
    final arrow1Center = Offset(
      center.dx + radius * math.cos(0.0),
      center.dy + radius * math.sin(0.0),
    );
    final arrow1 = Path()
      ..moveTo(arrow1Center.dx - w * 0.05, arrow1Center.dy - w * 0.10)
      ..lineTo(arrow1Center.dx + w * 0.12, arrow1Center.dy)
      ..lineTo(arrow1Center.dx - w * 0.05, arrow1Center.dy + w * 0.10)
      ..close();
    canvas.drawPath(arrow1, Paint()..color = const Color(0xFFFFA000));

    // Arrow head 2 (at top-right end of bottom arc)
    final arrow2Center = Offset(
      center.dx + radius * math.cos(math.pi),
      center.dy + radius * math.sin(math.pi),
    );
    final arrow2 = Path()
      ..moveTo(arrow2Center.dx + w * 0.05, arrow2Center.dy + w * 0.10)
      ..lineTo(arrow2Center.dx - w * 0.12, arrow2Center.dy)
      ..lineTo(arrow2Center.dx + w * 0.05, arrow2Center.dy - w * 0.10)
      ..close();
    canvas.drawPath(arrow2, Paint()..color = const Color(0xFFFFB300));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Goals Soft 3D Icon: Billowing emerald flag on pole with highlights
class Soft3DGoalsIcon extends StatelessWidget {
  const Soft3DGoalsIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalsIconPainter(),
      ),
    );
  }
}

class _GoalsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pole
    final poleRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.07, h * 0.78),
      Radius.circular(w * 0.035),
    );
    final polePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.07, h * 0.78));
    canvas.drawRRect(poleRRect, polePaint);

    // Finial ball on pole
    canvas.drawCircle(
      Offset(w * 0.255, h * 0.12),
      w * 0.065,
      Paint()..color = const Color(0xFFF1F5F9),
    );

    // Billowing Flag Path
    final flagPath = Path()
      ..moveTo(w * 0.27, h * 0.16)
      ..cubicTo(w * 0.46, h * 0.10, w * 0.65, h * 0.24, w * 0.88, h * 0.18)
      ..lineTo(w * 0.88, h * 0.56)
      ..cubicTo(w * 0.65, h * 0.62, w * 0.46, h * 0.48, w * 0.27, h * 0.54)
      ..close();

    // Soft drop shadow
    canvas.drawShadow(flagPath, Colors.black.withValues(alpha: 0.22), 3.0, true);

    // Green Flag Gradient
    final flagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF86EFAC),
          Color(0xFF22C55E),
          Color(0xFF15803D),
        ],
      ).createShader(Rect.fromLTWH(w * 0.27, h * 0.10, w * 0.61, h * 0.52));
    canvas.drawPath(flagPath, flagPaint);

    // Top Wave Specular Highlight
    final highlightPath = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..cubicTo(w * 0.46, h * 0.12, w * 0.65, h * 0.25, w * 0.86, h * 0.20);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Focus Soft 3D Icon: Purple & lavender stopwatch with top crown & dial
class Soft3DFocusIcon extends StatelessWidget {
  const Soft3DFocusIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FocusIconPainter(),
      ),
    );
  }
}

class _FocusIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.56);
    final outerRadius = w * 0.35;

    // Top crown stem & button
    final crownStem = Rect.fromLTWH(w * 0.46, h * 0.10, w * 0.08, h * 0.12);
    canvas.drawRect(crownStem, Paint()..color = const Color(0xFFC084FC));

    final crownCap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.06, w * 0.24, h * 0.07),
      const Radius.circular(3),
    );
    canvas.drawRRect(crownCap, Paint()..color = const Color(0xFF9333EA));

    // Outer Bezel Shadow
    final bezelPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawShadow(bezelPath, Colors.black.withValues(alpha: 0.24), 3.5, true);

    // Outer Bezel Gradient
    final bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE9D5FF),
          Color(0xFFA855F7),
          Color(0xFF6B21A8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawPath(bezelPath, bezelPaint);

    // Inner Watch Face
    final faceRadius = outerRadius * 0.74;
    final facePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF5EEFD)],
      ).createShader(Rect.fromCircle(center: center, radius: faceRadius));
    canvas.drawCircle(center, faceRadius, facePaint);

    // Center pin
    canvas.drawCircle(center, w * 0.04, Paint()..color = const Color(0xFF7C3AED));

    // Clock hand 1 (10 o'clock)
    canvas.drawLine(
      center,
      Offset(center.dx - faceRadius * 0.50, center.dy - faceRadius * 0.55),
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Clock hand 2 (2 o'clock)
    canvas.drawLine(
      center,
      Offset(center.dx + faceRadius * 0.55, center.dy - faceRadius * 0.40),
      Paint()
        ..color = const Color(0xFF9333EA)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Quiz Soft 3D Icon: Cream white gamepad controller with warm golden buttons
class Soft3DQuizIcon extends StatelessWidget {
  const Soft3DQuizIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QuizIconPainter(),
      ),
    );
  }
}

class _QuizIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final controllerPath = Path()
      ..moveTo(w * 0.20, h * 0.32)
      ..cubicTo(w * 0.38, h * 0.28, w * 0.62, h * 0.28, w * 0.80, h * 0.32)
      ..cubicTo(w * 0.95, h * 0.36, w * 0.96, h * 0.64, w * 0.85, h * 0.78)
      ..cubicTo(w * 0.79, h * 0.86, w * 0.66, h * 0.80, w * 0.60, h * 0.64)
      ..cubicTo(w * 0.55, h * 0.54, w * 0.45, h * 0.54, w * 0.40, h * 0.64)
      ..cubicTo(w * 0.34, h * 0.80, w * 0.21, h * 0.86, w * 0.15, h * 0.78)
      ..cubicTo(w * 0.04, h * 0.64, w * 0.05, h * 0.36, w * 0.20, h * 0.32)
      ..close();

    // Soft drop shadow
    canvas.drawShadow(
        controllerPath, Colors.black.withValues(alpha: 0.18), 3.0, true);

    // Controller body gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFFEF3C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(controllerPath, bodyPaint);

    // D-Pad on left grip (Plus shape)
    final dPadCenter = Offset(w * 0.29, h * 0.52);
    final dPadPaint = Paint()..color = const Color(0xFFF59E0B);
    final dPadArm = w * 0.05;
    final dPadThick = w * 0.04;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: dPadCenter, width: dPadThick, height: dPadArm * 2.4),
        const Radius.circular(1.5),
      ),
      dPadPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: dPadCenter, width: dPadArm * 2.4, height: dPadThick),
        const Radius.circular(1.5),
      ),
      dPadPaint,
    );

    // Action buttons on right grip (4 colored dots)
    final btnCenter = Offset(w * 0.71, h * 0.52);
    final btnDist = w * 0.06;
    final btnRadius = w * 0.03;

    canvas.drawCircle(Offset(btnCenter.dx, btnCenter.dy - btnDist), btnRadius,
        dPadPaint);
    canvas.drawCircle(Offset(btnCenter.dx, btnCenter.dy + btnDist), btnRadius,
        dPadPaint);
    canvas.drawCircle(Offset(btnCenter.dx - btnDist, btnCenter.dy), btnRadius,
        dPadPaint);
    canvas.drawCircle(Offset(btnCenter.dx + btnDist, btnCenter.dy), btnRadius,
        dPadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Leaderboard Soft 3D Icon: Golden trophy cup with star emblem and pedestal
class Soft3DLeaderboardIcon extends StatelessWidget {
  const Soft3DLeaderboardIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeaderboardIconPainter(),
      ),
    );
  }
}

class _LeaderboardIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Handles on sides
    final handlePaint = Paint()
      ..color = const Color(0xFFFFCA28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final leftHandle = Path()
      ..moveTo(w * 0.26, h * 0.30)
      ..cubicTo(w * 0.10, h * 0.32, w * 0.10, h * 0.50, w * 0.28, h * 0.52);
    canvas.drawPath(leftHandle, handlePaint);

    final rightHandle = Path()
      ..moveTo(w * 0.74, h * 0.30)
      ..cubicTo(w * 0.90, h * 0.32, w * 0.90, h * 0.50, w * 0.72, h * 0.52);
    canvas.drawPath(rightHandle, handlePaint);

    // Trophy cup bowl
    final cupPath = Path()
      ..moveTo(w * 0.24, h * 0.24)
      ..lineTo(w * 0.76, h * 0.24)
      ..cubicTo(w * 0.76, h * 0.54, w * 0.60, h * 0.64, w * 0.50, h * 0.64)
      ..cubicTo(w * 0.40, h * 0.64, w * 0.24, h * 0.54, w * 0.24, h * 0.24)
      ..close();

    // Shadow
    canvas.drawShadow(cupPath, Colors.black.withValues(alpha: 0.22), 3.0, true);

    // Golden gradient
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFCA28),
          Color(0xFFFFA000),
        ],
      ).createShader(Rect.fromLTWH(w * 0.24, h * 0.24, w * 0.52, h * 0.40));
    canvas.drawPath(cupPath, goldPaint);

    // Stem
    final stem = Rect.fromLTWH(w * 0.45, h * 0.64, w * 0.10, h * 0.12);
    canvas.drawRect(stem, Paint()..color = const Color(0xFFFFB300));

    // Base pedestal
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.76, w * 0.40, h * 0.12),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(base, Paint()..color = const Color(0xFFFFA000));

    // Star in center of cup
    _drawStar(canvas, Offset(w * 0.50, h * 0.40), w * 0.08, w * 0.04);
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, double innerR) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final double innerAngle = outerAngle + (math.pi / 5);

      final double ox = center.dx + outerR * math.cos(outerAngle);
      final double oy = center.dy + outerR * math.sin(outerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }

      final double ix = center.dx + innerR * math.cos(innerAngle);
      final double iy = center.dy + innerR * math.sin(innerAngle);
      path.lineTo(ix, iy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// SUBTLE CORNER WATERMARKS
// =============================================================================

/// Tasks watermark: soft sinusoidal wave bands
class _WaveWatermark extends StatelessWidget {
  const _WaveWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 48,
      child: CustomPaint(
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(size.width * 0.35, size.height * 0.45, size.width * 0.65,
          size.height * 0.85, size.width, size.height * 0.65);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.95)
      ..cubicTo(size.width * 0.35, size.height * 0.75, size.width * 0.65,
          size.height * 1.15, size.width, size.height * 0.95);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Habits watermark: soft curved leaf / botanical outline
class _LeafWatermark extends StatelessWidget {
  const _LeafWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _LeafPainter(),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..cubicTo(size.width * 0.15, size.height * 0.30, size.width * 0.50,
          size.height * 0.15, size.width * 0.85, size.height * 0.15)
      ..cubicTo(size.width * 0.85, size.height * 0.70, size.width * 0.50,
          size.height * 0.85, size.width * 0.15, size.height * 0.85);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Goals watermark: soft mountain terrain silhouette
class _MountainWatermark extends StatelessWidget {
  const _MountainWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 46,
      child: CustomPaint(
        painter: _MountainPainter(),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.22)
      ..lineTo(size.width * 0.65, size.height * 0.58)
      ..lineTo(size.width * 0.85, size.height * 0.34)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Focus watermark: concentric rounded ring arcs
class _RingsWatermark extends StatelessWidget {
  const _RingsWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _RingsPainter(),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width, size.height);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, size.width * 0.40, paint);
    canvas.drawCircle(center, size.width * 0.70, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Quiz watermark: soft rounded 5-point star silhouette
class _StarWatermark extends StatelessWidget {
  const _StarWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _StarPainter(),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.60, size.height * 0.60);
    final outerR = size.width * 0.38;
    final innerR = size.width * 0.18;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final double innerAngle = outerAngle + (math.pi / 5);

      final double ox = center.dx + outerR * math.cos(outerAngle);
      final double oy = center.dy + outerR * math.sin(outerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }

      final double ix = center.dx + innerR * math.cos(innerAngle);
      final double iy = center.dy + innerR * math.sin(innerAngle);
      path.lineTo(ix, iy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Leaderboard watermark: soft rising bar chart columns
class _BarChartWatermark extends StatelessWidget {
  const _BarChartWatermark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 48,
      child: CustomPaint(
        painter: _BarChartPainter(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Bar 1 (Left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.60, size.width * 0.20,
            size.height * 0.40),
        const Radius.circular(3),
      ),
      paint,
    );

    // Bar 2 (Middle, highest)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.44, size.height * 0.25, size.width * 0.20,
            size.height * 0.75),
        const Radius.circular(3),
      ),
      paint,
    );

    // Bar 3 (Right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.70, size.height * 0.42, size.width * 0.20,
            size.height * 0.58),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
