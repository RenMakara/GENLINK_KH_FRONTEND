import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Soft surface colors that work well in dark mode
    final cardColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white;
    final scaffoldBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xffF6F6F6);
    final secondaryText = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Finance",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          "SR",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Balance Card (stays dark / high contrast)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark
                      ? Border.all(color: theme.colorScheme.outlineVariant)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Balance - June 2026",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Income",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "+\$6,200",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Expenses",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "-\$1,379.50",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// Monthly Spending
              _card(
                color: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monthly Spending",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("June 2026", style: TextStyle(color: secondaryText)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: .72,
                      borderRadius: BorderRadius.circular(20),
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$642 of \$900",
                          style: TextStyle(color: secondaryText),
                        ),
                        Text(
                          "72%",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Emergency Fund
              _card(
                color: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Emergency Fund",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "\$1,240 of \$3,000",
                      style: TextStyle(color: secondaryText),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: .41,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Target: Dec 2026 • 41% complete",
                      style: TextStyle(color: secondaryText),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Smart Insight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.12)
                      : const Color(0xffF2FFF7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt,
                      color: isDark ? Colors.greenAccent : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Smart Insight",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "You're spending 15% more on food this month. Set a \$300 limit to stay on track.",
                            style: TextStyle(color: secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Quick Actions",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(Icons.add, "Add", cardColor),
                  _ActionButton(Icons.bar_chart, "Budget", cardColor),
                  _ActionButton(Icons.savings, "Goal", cardColor),
                  _ActionButton(Icons.menu_book, "Learn", cardColor),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                "Recent Transactions",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _transaction(
                context,
                "Grab Food",
                "-\$8.50",
                theme.colorScheme.onSurface,
              ),
              _transaction(context, "Salary Deposit", "+\$2,500", Colors.green),
              _transaction(
                context,
                "Netflix",
                "-\$15.99",
                theme.colorScheme.onSurface,
              ),

              const SizedBox(height: 20),

              _card(
                color: cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Learn Finance",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "3 of 5 topics completed.",
                            style: TextStyle(color: secondaryText),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: .6,
                            borderRadius: BorderRadius.circular(20),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.primary
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: isDark
                            ? theme.colorScheme.onPrimary
                            : Colors.white,
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

  Widget _card({required Widget child, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _transaction(
    BuildContext context,
    String title,
    String amount,
    Color amountColor,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surface,
          child: Icon(
            Icons.receipt_long,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        title: Text(title),
        subtitle: Text(
          "Today",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _ActionButton(
    this.icon,
    this.title,
    this.backgroundColor, {
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
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
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: theme.colorScheme.onSurface),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
