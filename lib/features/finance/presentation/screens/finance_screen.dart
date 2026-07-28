import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // =========================================================
    // APP COLORS
    // =========================================================

    final bgPrimary = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final surfacePrimary = isDark
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

    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // HEADER
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Finance",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Row(
                    children: [
                      Icon(Icons.notifications_none, color: textPrimary),

                      const SizedBox(width: 12),

                      CircleAvatar(
                        radius: 18,
                        backgroundColor: surfaceSecondary,
                        child: Text(
                          "SR",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =========================================================
              // BALANCE CARD
              // =========================================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfacePrimary
                      : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderStrong
                        : AppColors.lightPrimary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Balance - June 2026",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "\$4,820.50",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _balanceItem(
                            title: "Income",
                            amount: "+\$6,200",
                            amountColor: AppColors.success,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _balanceItem(
                            title: "Expenses",
                            amount: "-\$1,379.50",
                            amountColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =========================================================
              // MONTHLY SPENDING
              // =========================================================
              _card(
                color: surfacePrimary,
                borderColor: borderSubtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Monthly Spending", textPrimary),

                    const SizedBox(height: 4),

                    Text("June 2026", style: TextStyle(color: textSecondary)),

                    const SizedBox(height: 16),

                    LinearProgressIndicator(
                      value: .72,
                      borderRadius: BorderRadius.circular(20),
                      minHeight: 8,
                      backgroundColor: surfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.growthAccent,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$642 of \$900",
                          style: TextStyle(color: textSecondary),
                        ),

                        Text(
                          "72%",
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // EMERGENCY FUND
              // =========================================================
              _card(
                color: surfacePrimary,
                borderColor: borderSubtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Emergency Fund", textPrimary),

                    const SizedBox(height: 5),

                    Text(
                      "\$1,240 of \$3,000",
                      style: TextStyle(color: textSecondary),
                    ),

                    const SizedBox(height: 14),

                    LinearProgressIndicator(
                      value: .41,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: surfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.financeAccent,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Target: Dec 2026 • 41% complete",
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // SMART INSIGHT
              // =========================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.financeAccent.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.financeAccent.withValues(
                      alpha: isDark ? 0.30 : 0.20,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt, color: AppColors.financeAccent),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Smart Insight",
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "You're spending 15% more on food this month. Set a \$300 limit to stay on track.",
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================================================
              // QUICK ACTIONS
              // =========================================================
              Text(
                "Quick Actions",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    Icons.add,
                    "Add",
                    surfacePrimary,
                    iconColor: AppColors.brandPrimary,
                  ),

                  _ActionButton(
                    Icons.bar_chart,
                    "Budget",
                    surfacePrimary,
                    iconColor: AppColors.productivityAccent,
                  ),

                  _ActionButton(
                    Icons.savings,
                    "Goal",
                    surfacePrimary,
                    iconColor: AppColors.financeAccent,
                  ),

                  _ActionButton(
                    Icons.menu_book,
                    "Learn",
                    surfacePrimary,
                    iconColor: AppColors.growthAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================================================
              // RECENT TRANSACTIONS
              // =========================================================
              Text(
                "Recent Transactions",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _transaction(context, "Grab Food", "-\$8.50", textPrimary),

              _transaction(
                context,
                "Salary Deposit",
                "+\$2,500",
                AppColors.success,
              ),

              _transaction(context, "Netflix", "-\$15.99", textPrimary),

              const SizedBox(height: 20),

              // =========================================================
              // LEARN FINANCE
              // =========================================================
              _card(
                color: surfacePrimary,
                borderColor: borderSubtle,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Learn Finance",
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "3 of 5 topics completed.",
                            style: TextStyle(color: textSecondary),
                          ),

                          const SizedBox(height: 12),

                          LinearProgressIndicator(
                            value: .6,
                            borderRadius: BorderRadius.circular(20),
                            backgroundColor: surfaceSecondary,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.productivityAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BALANCE ITEM
  // =========================================================

  Widget _balanceItem({
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("", style: TextStyle(color: Colors.white70)),

          Text(title, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 4),

          Text(
            amount,
            style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _card({
    required Widget child,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // =========================================================
  // TRANSACTION
  // =========================================================

  Widget _transaction(
    BuildContext context,
    String title,
    String amount,
    Color amountColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark
              ? AppColors.darkSurfacePrimary
              : AppColors.lightSurfacePrimary,
          child: Icon(Icons.receipt_long, color: textMuted),
        ),

        title: Text(
          title,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        ),

        subtitle: Text("Today", style: TextStyle(color: textMuted)),

        trailing: Text(
          amount,
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================================================
// ACTION BUTTON
// =========================================================

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ActionButton(
    this.icon,
    this.title,
    this.backgroundColor, {
    required this.iconColor,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },

      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },

      onTapCancel: () {
        setState(() => _isPressed = false);
      },

      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 75,
          padding: const EdgeInsets.symmetric(vertical: 16),

          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),

            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),

          child: Column(
            children: [
              Icon(widget.icon, color: widget.iconColor),

              const SizedBox(height: 8),

              Text(
                widget.title,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
