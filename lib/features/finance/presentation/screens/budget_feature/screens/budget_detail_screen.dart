import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Food & Drink',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    'Adjust',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Row ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  label: 'Budget',
                                  value: '\$300',
                                  color: textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                              Expanded(
                                child: _StatCell(
                                  label: 'Spent',
                                  value: '\$320',
                                  color: AppColors.brandPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                              Expanded(
                                child: _StatCell(
                                  label: 'Left',
                                  value: '-\$20',
                                  color: Colors.redAccent,
                                  textMuted: textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 1.0,
                              minHeight: 6,
                              backgroundColor: secondarySurface,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.growthAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '106% used',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  // color: AppColors.error.withValues(
                                  //   alpha: 0.10,
                                  // ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Over limit',
                                  style: TextStyle(
                                    // color: AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Expenses ──
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _ExpenseCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Grab Food',
                      subtitle: 'Jun 28 · 12:30 PM',
                      amount: '-\$8.50',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _ExpenseCard(
                      icon: Icons.lunch_dining_outlined,
                      title: 'Lunch Box',
                      subtitle: 'Jun 27',
                      amount: '-\$4.20',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _ExpenseCard(
                      icon: Icons.restaurant_outlined,
                      title: 'Phnom Penh Kitchen',
                      subtitle: 'Jun 26',
                      amount: '-\$12.00',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _ExpenseCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Market Grocery',
                      subtitle: 'Jun 23',
                      amount: '-\$28.50',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 16),

                    // ── Warning ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE8D5A3).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'Budget almost exhausted\nOnly \$60 remaining for food this month. Consider reducing dining out.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: inverseText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Adjust Budget',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textMuted;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color surface;
  final Color secondarySurface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  const _ExpenseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.surface,
    required this.secondarySurface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: secondarySurface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
