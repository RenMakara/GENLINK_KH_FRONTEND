import 'package:flutter/material.dart';
import 'package:genlink_frontend/core/theme/theme_provider.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:provider/provider.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Finance",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => provider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WalletBalanceCard(theme: theme),
            const SizedBox(height: 20),
            _QuickActionsRow(theme: theme),
            const SizedBox(height: 28),
            _SectionHeader(title: "Budget Overview"),
            const SizedBox(height: 12),
            _BudgetCard(theme: theme),
            const SizedBox(height: 28),
            _SectionHeader(title: "Saving Goals"),
            const SizedBox(height: 12),
            _SavingGoalsList(theme: theme),
            const SizedBox(height: 28),
            _SectionHeader(title: "Expense Summary"),
            const SizedBox(height: 12),
            _ExpenseSummaryCard(theme: theme),
            const SizedBox(height: 28),
            _SectionHeader(title: "Recent Transactions"),
            const SizedBox(height: 12),
            _TransactionsList(theme: theme),
            const SizedBox(height: 28),
            _SectionHeader(title: "Financial Literacy"),
            const SizedBox(height: 12),
            _LiteracyCard(theme: theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Balance Card
// ---------------------------------------------------------------------------

class _WalletBalanceCard extends StatelessWidget {
  final ThemeData theme;
  const _WalletBalanceCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.financeAccent,
            AppColors.financeAccent.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.financeAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Demo Wallet",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Balance",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "\$85.00",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "USD  \u00b7  Simulation",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Row
// ---------------------------------------------------------------------------

class _QuickActionsRow extends StatelessWidget {
  final ThemeData theme;
  const _QuickActionsRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.add_circle_outline,
          label: "Top Up",
          color: AppColors.financeAccent,
          onTap: () {},
        ),
        _QuickAction(
          icon: Icons.qr_code_scanner,
          label: "Pay",
          color: AppColors.financeAccent,
          onTap: () {},
        ),
        _QuickAction(
          icon: Icons.savings_outlined,
          label: "Save",
          color: AppColors.financeAccent,
          onTap: () {},
        ),
        _QuickAction(
          icon: Icons.receipt_long_outlined,
          label: "Expenses",
          color: AppColors.financeAccent,
          onTap: () {},
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          "See all",
          style: TextStyle(
            color: AppColors.financeAccent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Budget Card
// ---------------------------------------------------------------------------

class _BudgetCard extends StatelessWidget {
  final ThemeData theme;
  const _BudgetCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    const spent = 180.0;
    const total = 300.0;
    const ratio = spent / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "July 2026",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.financeAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "WARNING",
                  style: TextStyle(
                    color: AppColors.financeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$180",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  "/ \$300",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.financeAccent.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.financeAccent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BudgetChip(label: "Food", spent: "\$90", allocated: "\$120"),
              const SizedBox(width: 8),
              _BudgetChip(label: "Other", spent: "\$90", allocated: "\$180"),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final String label;
  final String spent;
  final String allocated;

  const _BudgetChip({
    required this.label,
    required this.spent,
    required this.allocated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$spent / $allocated",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saving Goals List
// ---------------------------------------------------------------------------

class _SavingGoalsList extends StatelessWidget {
  final ThemeData theme;
  const _SavingGoalsList({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SavingGoalTile(
          theme: theme,
          title: "New Laptop",
          current: 150,
          target: 800,
          progress: 18,
          date: "Dec 2026",
        ),
        const SizedBox(height: 10),
        _SavingGoalTile(
          theme: theme,
          title: "Travel Fund",
          current: 320,
          target: 500,
          progress: 64,
          date: "Mar 2027",
        ),
      ],
    );
  }
}

class _SavingGoalTile extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final double current;
  final double target;
  final int progress;
  final String date;

  const _SavingGoalTile({
    required this.theme,
    required this.title,
    required this.current,
    required this.target,
    required this.progress,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.financeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.financeAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${current.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)}  \u00b7  $date",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4,
                    backgroundColor: AppColors.financeAccent.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.financeAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "$progress%",
            style: const TextStyle(
              color: AppColors.financeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense Summary Card
// ---------------------------------------------------------------------------

class _ExpenseSummaryCard extends StatelessWidget {
  final ThemeData theme;
  const _ExpenseSummaryCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "July 2026",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              Text(
                "Total: \$120.00",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ExpenseBar(
            label: "Food",
            amount: 60,
            maxAmount: 60,
            color: AppColors.financeAccent,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _ExpenseBar(
            label: "Other",
            amount: 60,
            maxAmount: 60,
            color: AppColors.financeAccent.withOpacity(0.5),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  final String label;
  final double amount;
  final double maxAmount;
  final Color color;
  final ThemeData theme;

  const _ExpenseBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxAmount > 0 ? amount / maxAmount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            Text(
              "\$${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions List
// ---------------------------------------------------------------------------

class _TransactionsList extends StatelessWidget {
  final ThemeData theme;
  const _TransactionsList({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _TransactionTile(
          title: "Brown Coffee",
          subtitle: "Iced latte",
          amount: -15.00,
          type: "MOCK_KHQR_PAYMENT",
          icon: Icons.local_cafe,
          time: "2 hours ago",
        ),
        SizedBox(height: 10),
        _TransactionTile(
          title: "Top Up",
          subtitle: "Demo deposit",
          amount: 100.00,
          type: "DEPOSIT",
          icon: Icons.add_circle_outline,
          time: "Yesterday",
        ),
        SizedBox(height: 10),
        _TransactionTile(
          title: "Reward",
          subtitle: "Quiz completed",
          amount: 1.00,
          type: "REWARD",
          icon: Icons.card_giftcard,
          time: "2 days ago",
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String type;
  final IconData icon;
  final String time;

  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.icon,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = amount >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.financeAccent.withOpacity(0.12)
                  : theme.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPositive ? AppColors.financeAccent : theme.colorScheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$subtitle  \u00b7  $time",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isPositive ? '+' : '-'} \$${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: isPositive ? AppColors.financeAccent : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Financial Literacy Card
// ---------------------------------------------------------------------------

class _LiteracyCard extends StatelessWidget {
  final ThemeData theme;
  const _LiteracyCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.growthAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.growthAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Financial Literacy",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "2 of 6 lessons completed",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                "40 XP",
                style: TextStyle(
                  color: AppColors.growthAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 2 / 6,
              minHeight: 6,
              backgroundColor: AppColors.growthAccent.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.growthAccent),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.growthAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Continue Learning",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
