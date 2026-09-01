import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';

/// Fixed background layer with a foreground child that can scroll or resize
/// independently. This is the single shared composition used by auth pages
/// and the post-registration profile setup flow.
class AuthBackgroundShell extends StatelessWidget {
  const AuthBackgroundShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: AnimatedAuthBackground()),
        child,
      ],
    );
  }
}

/// Calm, theme-aware decorative background for the signed-out welcome page.
///
/// A single 180-second controller drives several seamless sub-loops:
/// cyan (12s), violet (15s), wave (18s), and mint (20s). The painter is
/// connected directly to the controller, so only this layer repaints; the
/// authentication content above it is never rebuilt by the animation.
class AnimatedAuthBackground extends StatefulWidget {
  const AnimatedAuthBackground({super.key});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  static const _masterDuration = Duration(seconds: 180);
  static const _staticFrame = 0.23;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _masterDuration,
  );

  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final shouldReduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    if (_reduceMotion == shouldReduceMotion) return;
    _reduceMotion = shouldReduceMotion;

    if (shouldReduceMotion) {
      _controller
        ..stop()
        ..value = _staticFrame;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AuthBackgroundPainter(
              progress: _controller,
              baseColor: theme.scaffoldBackgroundColor,
              cyan: AppColors.communityAccent,
              blue: AppColors.brandPrimary,
              violet: AppColors.productivityAccent,
              mint: AppColors.financeAccent,
              isDark: isDark,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  _AuthBackgroundPainter({
    required this.progress,
    required this.baseColor,
    required this.cyan,
    required this.blue,
    required this.violet,
    required this.mint,
    required this.isDark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color baseColor;
  final Color cyan;
  final Color blue;
  final Color violet;
  final Color mint;
  final bool isDark;

  static const _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final t = progress.value;
    final shortest = math.min(size.width, size.height);
    final longest = math.max(size.width, size.height);
    final lightFactor = isDark ? 0.48 : 1.0;

    // 12-second cyan loop — lower-left, drifting by less than 20px.
    final cyanPhase = _tau * t * 15;
    _drawGlow(
      canvas,
      center: Offset(
        size.width * 0.05 + math.sin(cyanPhase) * 16,
        size.height * 0.68 + math.cos(cyanPhase) * 12,
      ),
      radius: longest * (0.56 + math.sin(cyanPhase) * 0.012),
      color: cyan,
      opacity: (0.095 + math.sin(cyanPhase) * 0.018) * lightFactor,
    );

    // 15-second blue/violet loop — upper-right, counter-moving for depth.
    final violetPhase = _tau * t * 12;
    _drawGlow(
      canvas,
      center: Offset(
        size.width * 0.96 + math.cos(violetPhase) * 14,
        size.height * 0.18 + math.sin(violetPhase) * 16,
      ),
      radius: longest * (0.48 + math.cos(violetPhase) * 0.012),
      color: violet,
      opacity: (0.075 + math.cos(violetPhase) * 0.014) * lightFactor,
    );

    // A second, cooler glow makes the transition between cyan and violet
    // feel continuous without adding blur filters.
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.78, size.height * 0.52),
      radius: shortest * 0.72,
      color: blue,
      opacity: 0.035 * lightFactor,
    );

    // 18-second translucent diagonal ribbon. Its Bezier geometry extends
    // beyond the viewport, so it remains responsive at every aspect ratio.
    final wavePhase = _tau * t * 10;
    final waveShiftX = math.sin(wavePhase) * 14;
    final waveShiftY = math.cos(wavePhase) * 12;
    final wave = Path()
      ..moveTo(-size.width * 0.24 + waveShiftX, size.height * 0.29 + waveShiftY)
      ..cubicTo(
        size.width * 0.16 + waveShiftX,
        size.height * 0.12 + waveShiftY,
        size.width * 0.58 + waveShiftX,
        size.height * 0.58 + waveShiftY,
        size.width * 1.24 + waveShiftX,
        size.height * 0.35 + waveShiftY,
      )
      ..lineTo(size.width * 1.24 + waveShiftX, size.height * 0.54 + waveShiftY)
      ..cubicTo(
        size.width * 0.62 + waveShiftX,
        size.height * 0.75 + waveShiftY,
        size.width * 0.12 + waveShiftX,
        size.height * 0.31 + waveShiftY,
        -size.width * 0.24 + waveShiftX,
        size.height * 0.49 + waveShiftY,
      )
      ..close();

    final waveBounds = wave.getBounds();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyan.withValues(alpha: 0),
            cyan.withValues(alpha: 0.028 * lightFactor),
            violet.withValues(
              alpha: (0.045 + math.sin(wavePhase) * 0.008) * lightFactor,
            ),
            violet.withValues(alpha: 0),
          ],
          stops: const [0, 0.28, 0.7, 1],
        ).createShader(waveBounds),
    );

    // 20-second mint loop — soft grounding glow near the bottom.
    final mintPhase = _tau * t * 9;
    _drawGlow(
      canvas,
      center: Offset(
        size.width * 0.74 + math.sin(mintPhase) * 12,
        size.height * 1.02 + math.cos(mintPhase) * 10,
      ),
      radius: longest * (0.42 + math.sin(mintPhase) * 0.01),
      color: mint,
      opacity: (0.065 + math.sin(mintPhase) * 0.012) * lightFactor,
    );
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity.clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.violet != violet ||
      oldDelegate.mint != mint ||
      oldDelegate.isDark != isDark;
}
