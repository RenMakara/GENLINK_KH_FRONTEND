import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/shadows/app_shadows.dart';

class Transaction extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color? amountColor;
  final Color background;
  final Color iconBackground;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onTap;
  final bool isCredit;

  const Transaction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.amountColor,
    required this.background,
    required this.iconBackground,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    this.onTap,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
              ),
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
                      fontWeight: FontWeight.w600,
                      height: 1.25,
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
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 145),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amount,
                  style: TextStyle(
                    color: amountColor ??
                        (isCredit ? AppColors.success : textPrimary),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String title;
  final Color textColor;

  const Legend({
    super.key,
    required this.color,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

class DonutChart extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final List<DonutSegment> segments;
  final Widget? center;

  const DonutChart({
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
              child: Center(child: center),
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
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final total = segments.fold<double>(0.0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / (total > 1.0 ? total : 1.0)) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final effectiveSweep =
          segments.length > 1 ? math.max(0.01, sweep - 0.05) : sweep;
      canvas.drawArc(rect, startAngle, effectiveSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class QuickAction extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback? onTap;
  final int maxLines;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.background,
    required this.border,
    required this.textColor,
    this.onTap,
    this.maxLines = 1,
    this.fontSize,
    this.padding,
  });

  @override
  State<QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<QuickAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.accent.withValues(alpha: 0.08)
                : widget.background,
            borderRadius: BorderRadius.circular(AppRadius.squircle),
            border: Border.all(
              color: _isPressed ? widget.accent : widget.border,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppShadows.cardLight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, size: 23, color: widget.accent),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: widget.maxLines > 1 ? 30 : null,
                child: Center(
                  child: Text(
                    widget.title,
                    maxLines: widget.maxLines,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: widget.fontSize ?? 12,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.squircle,
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
      ),
      child: child,
    );
  }
}

class BalanceCard extends StatefulWidget {
  final bool isDark;
  final Color surfaceSecondary;
  final String periodLabel;
  final String balance;
  final VoidCallback? onViewDetails;

  const BalanceCard({
    super.key,
    required this.isDark,
    required this.surfaceSecondary,
    required this.periodLabel,
    required this.balance,
    this.onViewDetails,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C382E),
            Color(0xFF13503E),
            Color(0xFF186851),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0B332A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF267D64).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FintechWavesPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Total Balance + Eye Toggle & View Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'finance.balance'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVisible = !_isVisible;
                                });
                              },
                              child: Icon(
                                _isVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.onViewDetails != null)
                        GestureDetector(
                          onTap: widget.onViewDetails,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'finance.viewDetails'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Large Balance (Responsive FittedBox with Privacy Blur)
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isVisible
                              ? Text(
                                  widget.balance,
                                  key: const ValueKey('balance_visible'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                )
                              : ClipRRect(
                                  key: const ValueKey('balance_blurred'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: 12,
                                      sigmaY: 12,
                                      tileMode: TileMode.decal,
                                    ),
                                    child: Text(
                                      widget.balance,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Bottom Row: Available Balance + Credit Card Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'finance.availableBalance'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.periodLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
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
    );
  }
}

class _FintechWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint1 = Paint()
      ..color = const Color(0xFF4BAE73).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.35,
        size.width,
        size.height * 0.40,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, wavePaint1);

    final wavePaint2 = Paint()
      ..color = const Color(0xFF67D897).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.58, size.height)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.55,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
