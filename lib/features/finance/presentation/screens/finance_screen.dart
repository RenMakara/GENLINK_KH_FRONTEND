import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/widgets/finance_widget.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finance',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'SR',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ============================================================
              // BALANCE
              // ============================================================
              _BalanceCard(isDark: isDark, surfaceSecondary: surfaceSecondary),

              const SizedBox(height: 16),

              // ============================================================
              // MONTHLY SPENDING
              // ============================================================
              _AppCard(
                color: surface,
                borderColor: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Spending',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'June 2026',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        DonutChart(
                          size: 68,
                          strokeWidth: 8,
                          backgroundColor: surfaceSecondary,
                          segments: const [
                            DonutSegment(
                              value: .28,
                              color: AppColors.growthAccent,
                            ),
                            DonutSegment(
                              value: .25,
                              color: AppColors.brandPrimary,
                            ),
                            DonutSegment(
                              value: .22,
                              color: AppColors.financeAccent,
                            ),
                            DonutSegment(
                              value: .15,
                              color: AppColors.productivityAccent,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Legend(
                          color: AppColors.growthAccent,
                          title: 'Food',
                          textColor: textMuted,
                        ),

                        const SizedBox(width: 18),

                        Legend(
                          color: AppColors.brandPrimary,
                          title: 'Transport',
                          textColor: textMuted,
                        ),

                        const SizedBox(width: 18),

                        Legend(
                          color: AppColors.financeAccent,
                          title: 'Bills',
                          textColor: textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .72,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
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
                          '\$642 of \$900',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),

                        Text(
                          '72%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // EMERGENCY FUND
              // ============================================================
              _AppCard(
                color: surface,
                borderColor: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Fund',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '\$1,240 of \$3,000',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        DonutChart(
                          size: 52,
                          strokeWidth: 7,
                          backgroundColor: surfaceSecondary,
                          segments: const [
                            DonutSegment(
                              value: .41,
                              color: AppColors.financeAccent,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .41,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.financeAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Target: Dec 2026 • 41% complete',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // SMART INSIGHT
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.financeAccent.withValues(alpha: .08)
                      : AppColors.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.financeAccent.withValues(alpha: .45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.financeAccent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.financeAccent,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Insight',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "You're spending 15% more on food this month. "
                            "Set a \$300 limit to stay on track.",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ============================================================
              // QUICK ACTIONS
              // ============================================================
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_rounded,
                      title: 'Add Expense',
                      accent: AppColors.brandPrimary,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      title: 'Set Budget',
                      accent: AppColors.productivityAccent,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _QuickAction(
                      icon: Icons.savings_outlined,
                      title: 'Save Goal',
                      accent: AppColors.financeAccent,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _QuickAction(
                      icon: Icons.menu_book_rounded,
                      title: 'Learn',
                      accent: AppColors.growthAccent,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // RECENT TRANSACTIONS
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpenseScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All →',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Transaction(
                title: 'Grab Food',
                subtitle: 'Today · 12:30 PM · Food',
                amount: '-\$8.50',
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.growthAccent,
                background: surface,
                iconBackground: surfaceSecondary,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              Transaction(
                title: 'Salary Deposit',
                subtitle: 'Jun 1 · ABA Bank',
                amount: '+\$2,500',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.financeAccent,
                amountColor: AppColors.financeAccent,
                background: surface,
                iconBackground: surfaceSecondary,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              Transaction(
                title: 'Netflix',
                subtitle: 'Yesterday · Card',
                amount: '-\$15.99',
                icon: Icons.play_circle_outline_rounded,
                iconColor: AppColors.brandPrimary,
                background: surface,
                iconBackground: surfaceSecondary,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              const SizedBox(height: 16),

              // ============================================================
              // LEARN FINANCE
              // ============================================================
              _AppCard(
                color: surface,
                borderColor: border,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn Finance',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '3 of 5 topics completed. Keep going!',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: .6,
                              minHeight: 6,
                              backgroundColor: surfaceSecondary,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.productivityAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 22,
                        color: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// APP CARD
// ============================================================================

class _AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _AppCard({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}

// ============================================================================
// BALANCE CARD
// ============================================================================

class _BalanceCard extends StatelessWidget {
  final bool isDark;
  final Color surfaceSecondary;

  const _BalanceCard({required this.isDark, required this.surfaceSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkBorderStrong) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Balance · June 2026',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .65),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            '\$4,820.50',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  title: 'Income',
                  amount: '+\$6,200',
                  amountColor: AppColors.financeAccent,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _BalanceItem(
                  title: 'Expenses',
                  amount: '-\$1,379.50',
                  amountColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BALANCE ITEM
// ============================================================================

class _BalanceItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color amountColor;

  const _BalanceItem({
    required this.title,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: amountColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// QUICK ACTION
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.accent,
    required this.background,
    required this.border,
    required this.textColor,
    this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,

      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },

      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },

      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },

      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 92,
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.accent.withValues(alpha: .08)
                : widget.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isPressed ? widget.accent : widget.border,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: .15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(
                    alpha: _isPressed ? .18 : .10,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedScale(
                  scale: _isPressed ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Icon(widget.icon, size: 20, color: widget.accent),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  widget.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 10,
                    fontWeight: _isPressed ? FontWeight.w600 : FontWeight.w500,
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
