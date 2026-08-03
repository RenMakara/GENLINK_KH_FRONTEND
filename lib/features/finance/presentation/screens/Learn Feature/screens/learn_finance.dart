import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Learn%20Feature/screens/investing_basics.dart';

class LearnFinanceScreen extends StatelessWidget {
  const LearnFinanceScreen({super.key});

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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────
              // HEADER (same style as FinanceScreen)
              // ─────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Learn Finance',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────
              // PROGRESS CARD
              // ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
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
                                'Your Progress',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '3 of 6 topics completed',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '50%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: 0.50,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────
              // TOPICS
              // ─────────────────────────────────────────
              Text(
                'Topics',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.4,
                children: [
                  _TopicCard(
                    title: 'Budgeting 101',
                    icon: Icons.account_balance_wallet_outlined,
                    completed: true,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                  ),
                  _TopicCard(
                    title: 'Saving Habits',
                    icon: Icons.savings_outlined,
                    completed: true,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                  ),
                  _TopicCard(
                    title: 'Understanding Credit',
                    icon: Icons.credit_card_outlined,
                    completed: true,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                  ),
                  _TopicCard(
                    title: 'Investing Basics',
                    icon: Icons.show_chart_rounded,
                    completed: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvestingBasicsScreen(),
                        ),
                      );
                    },
                  ),
                  _TopicCard(
                    title: 'Loans & Debt',
                    icon: Icons.account_balance_outlined,
                    completed: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                  ),
                  _TopicCard(
                    title: 'Tax Planning',
                    icon: Icons.receipt_long_outlined,
                    completed: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    primary: primary,
                    textInverse: textInverse,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────
              // NEXT LESSON (Smart Insight style)
              // ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.bolt_rounded, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next: Investing Basics',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '6 min read · +100 XP',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────
              // START LEARNING BUTTON
              // ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvestingBasicsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: textInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Learning →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Extra bottom space so content clears the nav bar
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOPIC CARD  (matches screenshot: filled when completed)
// ─────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool completed;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;
  final Color textInverse;
  final VoidCallback? onTap;

  const _TopicCard({
    required this.title,
    required this.icon,
    required this.completed,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    required this.textInverse,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: completed ? primary : surface,
            borderRadius: BorderRadius.circular(14),
            border: completed ? null : Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: completed
                    ? textInverse.withValues(alpha: 0.85)
                    : textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: completed ? textInverse : textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              if (completed)
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: textInverse.withValues(alpha: 0.9),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
