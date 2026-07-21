import 'package:flutter/material.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:get/get.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Builder(
            builder: (context) {
              final themeController = Get.find<ThemeController>();
              return Obx(
                () => IconButton(
                  icon: Icon(
                    themeController.isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => themeController.toggle(context),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Balance",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(.75),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "\$12,850.00",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(icon: Icons.send, text: "Send"),
                _ActionButton(
                  icon: Icons.account_balance_wallet,
                  text: "Top Up",
                ),
                _ActionButton(icon: Icons.receipt_long, text: "Bills"),
                _ActionButton(icon: Icons.bar_chart, text: "Report"),
              ],
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Transactions",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                children: const [
                  TransactionTile(
                    title: "Netflix",
                    subtitle: "Subscription",
                    amount: "- \$12.99",
                    icon: Icons.movie,
                  ),
                  TransactionTile(
                    title: "Salary",
                    subtitle: "Company",
                    amount: "+ \$2,500",
                    icon: Icons.work,
                  ),
                  TransactionTile(
                    title: "Coffee",
                    subtitle: "Starbucks",
                    amount: "- \$5.20",
                    icon: Icons.local_cafe,
                  ),
                  TransactionTile(
                    title: "Nike",
                    subtitle: "Shopping",
                    amount: "- \$149.00",
                    icon: Icons.shopping_bag,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ActionButton({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(.12),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(.6),
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              color: amount.startsWith("+") ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
