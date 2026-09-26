import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../design_system/colors/app_colors.dart';

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

/// Independent [TickerProvider] for the shared auth background animation.
class _SharedAuthBackgroundTickerProvider implements TickerProvider {
  const _SharedAuthBackgroundTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) =>
      Ticker(onTick, debugLabel: 'SharedAuthBackgroundTicker');
}

/// Global coordinator that maintains a single, continuous 12-second wave loop
/// shared across all active authentication screens.
///
/// Benefits:
/// 1. Route transitions (e.g. Login -> Register -> Forgot Password) do NOT
///    reset the background wave animation. The waves remain at the exact same
///    position and phase across screen switches.
/// 2. Eliminates duplicate animation loops during page transitions, saving CPU
///    and GPU cycles.
/// 3. Automatically disposed when the last auth screen unmounts.
class SharedAuthBackgroundCoordinator {
  SharedAuthBackgroundCoordinator._();
  static final SharedAuthBackgroundCoordinator instance =
      SharedAuthBackgroundCoordinator._();

  static const _masterDuration = Duration(seconds: 12);
  static const _staticFrame = 0.23;

  AnimationController? _controller;
  int _refCount = 0;

  Animation<double> acquire({required bool reduceMotion}) {
    if (_controller == null) {
      _controller = AnimationController(
        vsync: const _SharedAuthBackgroundTickerProvider(),
        duration: _masterDuration,
      );
      if (reduceMotion) {
        _controller!.value = _staticFrame;
      } else {
        _controller!.repeat();
      }
    }
    _refCount++;
    return _controller!;
  }

  void release() {
    _refCount--;
    if (_refCount <= 0) {
      _controller?.dispose();
      _controller = null;
      _refCount = 0;
    }
  }

  void updateReducedMotion(bool reduceMotion) {
    final c = _controller;
    if (c == null) return;
    if (reduceMotion) {
      c.stop();
      c.value = _staticFrame;
    } else if (!c.isAnimating) {
      c.repeat();
    }
  }
}

class AnimatedAuthBackground extends StatefulWidget {
  const AnimatedAuthBackground({super.key});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground> {
  Animation<double>? _progress;
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final shouldReduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    if (_progress == null) {
      _reduceMotion = shouldReduceMotion;
      _progress = SharedAuthBackgroundCoordinator.instance.acquire(
        reduceMotion: shouldReduceMotion,
      );
    } else if (_reduceMotion != shouldReduceMotion) {
      _reduceMotion = shouldReduceMotion;
      SharedAuthBackgroundCoordinator.instance.updateReducedMotion(
        shouldReduceMotion,
      );
    }
  }

  @override
  void dispose() {
    SharedAuthBackgroundCoordinator.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressAnim = _progress;

    if (progressAnim == null) {
      return ColoredBox(color: theme.scaffoldBackgroundColor);
    }

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AuthBackgroundPainter(
              progress: progressAnim,
              baseColor: theme.scaffoldBackgroundColor,
              cyan: AppColors.communityAccent,
              violet: AppColors.productivityAccent,
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
    required this.violet,
    required this.isDark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color baseColor;
  final Color cyan;
  final Color violet;
  final bool isDark;

  static const _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final phase = _tau * progress.value;
    final lightFactor = isDark ? 0.52 : 1.0;

    final topShift = Offset(math.sin(phase) * 10, math.cos(phase) * 5);
    final bottomShift = Offset(math.cos(phase) * -12, math.sin(phase) * 6);

    _drawTopWave(canvas, size, shift: topShift, lightFactor: lightFactor);
    _drawBottomWave(canvas, size, shift: bottomShift, lightFactor: lightFactor);
  }

  void _drawTopWave(
    Canvas canvas,
    Size size, {
    required Offset shift,
    required double lightFactor,
  }) {
    final width = size.width;
    final height = size.height;
    final wave = Path()
      ..moveTo(-width * 0.12 + shift.dx, height * 0.12 + shift.dy)
      ..cubicTo(
        width * 0.15 + shift.dx,
        height * 0.09 + shift.dy,
        width * 0.36 + shift.dx,
        height * 0.24 + shift.dy,
        width * 0.58 + shift.dx,
        height * 0.21 + shift.dy,
      )
      ..cubicTo(
        width * 0.80 + shift.dx,
        height * 0.18 + shift.dy,
        width * 0.96 + shift.dx,
        height * 0.05 + shift.dy,
        width * 1.12 + shift.dx,
        height * 0.01 + shift.dy,
      )
      ..lineTo(width * 1.12 + shift.dx, height * 0.17 + shift.dy)
      ..cubicTo(
        width * 0.93 + shift.dx,
        height * 0.25 + shift.dy,
        width * 0.76 + shift.dx,
        height * 0.31 + shift.dy,
        width * 0.55 + shift.dx,
        height * 0.29 + shift.dy,
      )
      ..cubicTo(
        width * 0.30 + shift.dx,
        height * 0.27 + shift.dy,
        width * 0.10 + shift.dx,
        height * 0.20 + shift.dy,
        -width * 0.12 + shift.dx,
        height * 0.19 + shift.dy,
      )
      ..close();

    final bounds = Rect.fromLTWH(0, 0, width, height * 0.42);
    canvas.drawPath(
      wave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cyan.withValues(alpha: 0.015 * lightFactor),
            cyan.withValues(alpha: 0.075 * lightFactor),
            cyan.withValues(alpha: 0.028 * lightFactor),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(bounds),
    );
  }

  void _drawBottomWave(
    Canvas canvas,
    Size size, {
    required Offset shift,
    required double lightFactor,
  }) {
    final width = size.width;
    final height = size.height;
    final tint = Path()
      ..moveTo(-width * 0.12 + shift.dx, height * 0.70 + shift.dy)
      ..cubicTo(
        width * 0.15 + shift.dx,
        height * 0.62 + shift.dy,
        width * 0.38 + shift.dx,
        height * 0.73 + shift.dy,
        width * 0.61 + shift.dx,
        height * 0.69 + shift.dy,
      )
      ..cubicTo(
        width * 0.82 + shift.dx,
        height * 0.66 + shift.dy,
        width * 0.98 + shift.dx,
        height * 0.57 + shift.dy,
        width * 1.12 + shift.dx,
        height * 0.52 + shift.dy,
      )
      ..lineTo(width * 1.12 + shift.dx, height * 1.12 + shift.dy)
      ..lineTo(-width * 0.12 + shift.dx, height * 1.12 + shift.dy)
      ..close();

    final band = Path()
      ..moveTo(-width * 0.12 + shift.dx, height * 0.70 + shift.dy)
      ..cubicTo(
        width * 0.15 + shift.dx,
        height * 0.62 + shift.dy,
        width * 0.38 + shift.dx,
        height * 0.73 + shift.dy,
        width * 0.61 + shift.dx,
        height * 0.69 + shift.dy,
      )
      ..cubicTo(
        width * 0.82 + shift.dx,
        height * 0.66 + shift.dy,
        width * 0.98 + shift.dx,
        height * 0.57 + shift.dy,
        width * 1.12 + shift.dx,
        height * 0.52 + shift.dy,
      )
      ..lineTo(width * 1.12 + shift.dx, height * 0.69 + shift.dy)
      ..cubicTo(
        width * 0.91 + shift.dx,
        height * 0.79 + shift.dy,
        width * 0.75 + shift.dx,
        height * 0.84 + shift.dy,
        width * 0.55 + shift.dx,
        height * 0.81 + shift.dy,
      )
      ..cubicTo(
        width * 0.31 + shift.dx,
        height * 0.78 + shift.dy,
        width * 0.10 + shift.dx,
        height * 0.83 + shift.dy,
        -width * 0.12 + shift.dx,
        height * 0.89 + shift.dy,
      )
      ..close();

    final bounds = Rect.fromLTWH(0, height * 0.48, width, height * 0.64);
    canvas.drawPath(
      tint,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            violet.withValues(alpha: 0.018 * lightFactor),
            violet.withValues(alpha: 0.028 * lightFactor),
            violet.withValues(alpha: 0.012 * lightFactor),
          ],
          stops: const [0, 0.3, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      band,
      Paint()..color = violet.withValues(alpha: 0.042 * lightFactor),
    );
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.cyan != cyan ||
      oldDelegate.violet != violet ||
      oldDelegate.isDark != isDark;
}
