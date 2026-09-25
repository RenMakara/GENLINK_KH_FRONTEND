import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.radius,
    this.color,
    this.strokeWidth = 1.4,
    this.dashLength = 6,
    this.gapLength = 5,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? Theme.of(context).colorScheme.outline,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    final step = dashLength + gapLength;
    for (final metric in path.computeMetrics()) {
      final count = math.max(1, (metric.length / step).round());
      final actualStep = metric.length / count;
      final actualDash = dashLength * (actualStep / step);

      for (var i = 0; i < count; i++) {
        final start = i * actualStep;
        canvas.drawPath(metric.extractPath(start, start + actualDash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength;
}
