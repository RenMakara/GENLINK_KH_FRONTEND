import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';

class PeriodButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color textMuted;
  final Color selectedColor;
  final Color selectedTextColor;

  const PeriodButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.textMuted,
    required this.selectedColor,
    required this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? selectedTextColor : textMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadows;

  const SurfaceCard({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

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
  final Widget? center;

  const ExpenseDonut({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.segments,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              backgroundColor: backgroundColor,
              strokeWidth: strokeWidth,
              segments: segments,
            ),
          ),
          if (center != null)
            Padding(
              padding: EdgeInsets.all(strokeWidth + 2),
              child: Center(child: center!),
            ),
        ],
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
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (segments.isEmpty) return;

    final totalValue = segments.fold<double>(0.0, (sum, seg) => sum + seg.value);
    if (totalValue <= 0) return;

    double startAngle = -math.pi / 2;
    const double gapAngle = 0.05;
    final hasMultiple = segments.length > 1;

    for (final segment in segments) {
      final ratio = (segment.value / totalValue).clamp(0.0, 1.0);
      final rawSweep = math.pi * 2 * ratio;
      final sweepAngle = hasMultiple ? math.max(0.0, rawSweep - gapAngle) : rawSweep;

      if (sweepAngle > 0.01) {
        final paint = Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = hasMultiple ? StrokeCap.round : StrokeCap.butt
          ..isAntiAlias = true;

        canvas.drawArc(
          rect,
          startAngle + (hasMultiple ? gapAngle / 2 : 0),
          sweepAngle,
          false,
          paint,
        );
      }

      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.segments != segments;
  }
}

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
  final IconData? icon;
  final VoidCallback? onTap;

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
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidget = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: textMuted.withValues(alpha: 0.12),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon squircle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.category_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Center & Progress column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          amount,
                          maxLines: 1,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text(
                        percent,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: textMuted.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: itemWidget,
        ),
      );
    }
    return itemWidget;
  }
}

class ExpenseItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color iconColor;
  final Color textPrimary;
  final Color textMuted;
  final bool showDivider;
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: textMuted.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: iconColor),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: textMuted.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final Color textPrimary;
  final Color textMuted;
  final Color? actionColor;

  const ExpenseSectionHeader({
    super.key,
    required this.title,
    required this.textPrimary,
    required this.textMuted,
    this.subtitle,
    this.action,
    this.onAction,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                action!,
                style: TextStyle(
                  color: actionColor ?? textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ExpenseBackButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const ExpenseBackButton({
    super.key,
    required this.background,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class ExpenseAddButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const ExpenseAddButton({
    super.key,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_rounded, color: iconColor, size: 24),
        ),
      ),
    );
  }
}

class ExpensePeriodBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Color background;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;

  const ExpensePeriodBar({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    required this.background,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            splashRadius: 20,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: onPrevious != null ? textPrimary : textMuted.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: textPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            splashRadius: 20,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext != null ? textPrimary : textMuted.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class SpendingStatus extends StatelessWidget {
  final String title;
  final String remaining;
  final Color color;
  final Color background;
  final Color textMuted;

  const SpendingStatus({
    super.key,
    required this.title,
    required this.remaining,
    required this.color,
    required this.background,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            remaining,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseFilterChip extends StatelessWidget {
  final String title;
  final bool selected;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const ExpenseFilterChip({
    super.key,
    required this.title,
    required this.selected,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selectedColor : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: borderColor),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? selectedTextColor : textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ExpenseAmount extends StatelessWidget {
  final String amount;
  final bool positive;
  final Color textColor;
  final Color positiveColor;

  const ExpenseAmount({
    super.key,
    required this.amount,
    required this.positive,
    required this.textColor,
    required this.positiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      amount,
      style: TextStyle(
        color: positive ? positiveColor : textColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
