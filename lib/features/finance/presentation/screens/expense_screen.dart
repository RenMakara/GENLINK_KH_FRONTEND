import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  int selectedPeriod = 2; // 0 = Today, 1 = Week, 2 = Month

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Expenses',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ============================================================
              // PERIOD SELECTOR
              // ============================================================
              Row(
                children: [
                  Expanded(
                    child: _PeriodButton(
                      title: 'Today',
                      selected: selectedPeriod == 0,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 0;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _PeriodButton(
                      title: 'Week',
                      selected: selectedPeriod == 1,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 1;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _PeriodButton(
                      title: 'Month',
                      selected: selectedPeriod == 2,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 2;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ============================================================
              // TOTAL SPENT CARD
              // ============================================================
              _SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _ExpenseDonut(
                      size: 82,
                      strokeWidth: 9,
                      backgroundColor: secondarySurface,
                      segments: const [
                        _DonutSegment(
                          value: .40,
                          color: AppColors.growthAccent,
                        ),
                        _DonutSegment(
                          value: .25,
                          color: AppColors.brandPrimary,
                        ),
                        _DonutSegment(
                          value: .20,
                          color: AppColors.financeAccent,
                        ),
                        _DonutSegment(
                          value: .15,
                          color: AppColors.profileAccent,
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Spent',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '\$642',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'On track',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ============================================================
              // CATEGORY BREAKDOWN
              // ============================================================
              _SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _CategoryRow(
                      title: 'Food & Drink',
                      amount: '\$255 / \$300',
                      percent: '85%',
                      progress: .85,
                      color: AppColors.growthAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    _CategoryRow(
                      title: 'Transport',
                      amount: '\$138 / \$150',
                      percent: '92%',
                      progress: .92,
                      color: AppColors.brandPrimary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    _CategoryRow(
                      title: 'Study',
                      amount: '\$51 / \$150',
                      percent: '34%',
                      progress: .34,
                      color: AppColors.productivityAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    _CategoryRow(
                      title: 'Bills',
                      amount: '\$36 / \$300',
                      percent: '12%',
                      progress: .12,
                      color: AppColors.financeAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ============================================================
              // RECENT EXPENSES
              // ============================================================
              _SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _ExpenseItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Grab Food',
                      subtitle: 'Today · 12:30 PM · Food',
                      amount: '-\$8.50',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    _ExpenseItem(
                      icon: Icons.directions_bus_outlined,
                      title: 'Bus Pass',
                      subtitle: 'Today · 8:00 AM · Transport',
                      amount: '-\$1.25',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    _ExpenseItem(
                      icon: Icons.menu_book_outlined,
                      title: 'Textbooks',
                      subtitle: 'Yesterday · Study',
                      amount: '-\$45.00',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    _ExpenseItem(
                      icon: Icons.bolt_outlined,
                      title: 'Electricity',
                      subtitle: 'Jun 1 · Bills',
                      amount: '-\$36.00',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PERIOD BUTTON
// ===========================================================================

class _PeriodButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color borderColor;
  final Color backgroundColor;

  const _PeriodButton({
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

// ===========================================================================
// SURFACE CARD
// ===========================================================================

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  const _SurfaceCard({
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

// ===========================================================================
// DONUT CHART
// ===========================================================================

class _DonutSegment {
  final double value;
  final Color color;

  const _DonutSegment({required this.value, required this.color});
}

class _ExpenseDonut extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final List<_DonutSegment> segments;

  const _ExpenseDonut({
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
  final List<_DonutSegment> segments;

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

// ===========================================================================
// CATEGORY ROW
// ===========================================================================

class _CategoryRow extends StatelessWidget {
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

  const _CategoryRow({
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

// ===========================================================================
// EXPENSE ITEM
// ===========================================================================

class _ExpenseItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color iconColor;
  final Color textPrimary;
  final Color textMuted;
  final bool showDivider;

  const _ExpenseItem({
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
