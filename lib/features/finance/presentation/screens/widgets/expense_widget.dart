import 'dart:math' as math;
import 'package:flutter/material.dart';

// PERIOD BUTTON
class PeriodButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color borderColor;
  final Color backgroundColor;

  const PeriodButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: selected ? null : Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? selectedTextColor : textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// SURFACE CARD
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  const SurfaceCard({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}

// DONUT CHART
class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

class ExpenseDonut extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final List<DonutSegment> segments;

  const ExpenseDonut({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth,
          segments: segments,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Color backgroundColor;
  final double strokeWidth;
  final List<DonutSegment> segments;

  _DonutPainter({
    required this.backgroundColor,
    required this.strokeWidth,
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = math.pi * 2 * segment.value;

      canvas.drawArc(rect, startAngle, sweep - 0.06, false, paint);

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.segments != segments;
  }
}

// CATEGORY ROW
class CategoryRow extends StatelessWidget {
  final String title;
  final String amount;
  final String percent;
  final double progress;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color backgroundColor;
  final bool showDivider;

  const CategoryRow({
    super.key,
    required this.title,
    required this.amount,
    required this.percent,
    required this.progress,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.backgroundColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: textMuted.withValues(alpha: .15)),
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Text(
                amount,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 36,
                child: Text(
                  percent,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// EXPENSE ITEM
class ExpenseItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color iconColor;
  final Color textPrimary;
  final Color textMuted;
  final bool showDivider;

  const ExpenseItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.iconColor,
    required this.textPrimary,
    required this.textMuted,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: textMuted.withValues(alpha: .12)),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            amount,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
