import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/investing_basics.dart';

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

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),

        titleSpacing: 0,

        title: Text(
          'Learn Finance',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // PROGRESS CARD
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                '2 of 4 topics completed',
                                style: TextStyle(color: textMuted, fontSize: 9),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          '50%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .50,
                        minHeight: 5,
                        backgroundColor: surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // TOPICS
              // =================================================
              Text(
                'Topics',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.35,

                children: [
                  _TopicCard(
                    title: 'Budgeting 101',
                    icon: Icons.account_balance_wallet_outlined,
                    completed: true,
                    background: primary,
                    textPrimary: textInverse(isDark),
                  ),

                  _TopicCard(
                    title: 'Saving Habits',
                    icon: Icons.savings_outlined,
                    completed: true,
                    background: primary,
                    textPrimary: textInverse(isDark),
                  ),

                  _TopicCard(
                    title: 'Understanding Credit',
                    icon: Icons.credit_card_outlined,
                    completed: true,
                    background: primary,
                    textPrimary: textInverse(isDark),
                  ),

                  _TopicCard(
                    title: 'Investing Basics',
                    icon: Icons.show_chart_rounded,
                    completed: false,
                    background: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
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
                    background: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),

                  _TopicCard(
                    title: 'Tax Planning',
                    icon: Icons.receipt_long_outlined,
                    completed: false,
                    background: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =================================================
              // NEXT LESSON
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: border),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(11),
                      ),

                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: textInverse(isDark),
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next: Investing Basics',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '6 min read · +100 XP',
                            style: TextStyle(color: textMuted, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // START LEARNING
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 44,

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
                    foregroundColor: textInverse(isDark),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: const Text(
                    'Start Learning →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color textInverse(bool isDark) {
    return isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse;
  }
}

// =============================================================
// TOPIC CARD
// =============================================================

class _TopicCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool completed;

  final Color background;
  final Color? border;
  final Color textPrimary;
  final Color? textMuted;

  final VoidCallback? onTap;

  const _TopicCard({
    required this.title,
    required this.icon,
    required this.completed,
    required this.background,
    required this.textPrimary,
    this.border,
    this.textMuted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),

        child: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
            border: border != null ? Border.all(color: border!) : null,
          ),

          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: completed
                    ? textPrimary.withValues(alpha: .75)
                    : textMuted,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (completed)
                Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: textPrimary.withValues(alpha: .70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
