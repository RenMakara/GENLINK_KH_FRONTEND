import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/quiz_models.dart';

/// Clean, responsive search bar for filtering categories.
class QuizCategorySearchBar extends StatelessWidget {
  const QuizCategorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: semantic.primaryText,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'quiz.searchCategories'.tr,
          hintStyle: TextStyle(
            fontSize: 14,
            color: semantic.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: semantic.textMuted,
            size: 20,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: semantic.textMuted,
                  size: 18,
                ),
                onPressed: onClear,
              );
            },
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
        ),
      ),
    );
  }
}

/// Horizontal category card that guarantees NO RenderFlex overflow.
class QuizCategoryCard extends StatelessWidget {
  const QuizCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final QuizCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final color = _getCategoryAccent(category);
    final icon = _getCategoryIcon(category);
    final tagline = _getCategoryTagline(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: semantic.borderSubtle,
              width: 1.0,
            ),
            boxShadow: semantic.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title, Questions Count, and Chevron
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: semantic.primaryText,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: semantic.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.questionsCount'.trParams({
                        'count': '${category.questionCount}',
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: semantic.secondaryText,
                      ),
                    ),
                    if (tagline != null && tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: semantic.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryAccent(QuizCategory cat) {
    final id = cat.id.toUpperCase();
    if (id.contains('FINANCE')) return AppColors.financeAccent;
    if (id.contains('HEALTH') || id.contains('SCIENCE')) return AppColors.success;
    if (id.contains('TECH')) return AppColors.brandPrimary;
    if (id.contains('COMMUNITY')) return AppColors.communityAccent;
    if (id.contains('LIFE') || id.contains('SKILL')) {
      return AppColors.growthAccent;
    }
    return AppColors.productivityAccent;
  }

  IconData _getCategoryIcon(QuizCategory cat) {
    final id = cat.id.toUpperCase();
    if (id.contains('FINANCE')) return Icons.account_balance_wallet_rounded;
    if (id.contains('HEALTH')) return Icons.favorite_rounded;
    if (id.contains('SCIENCE')) return Icons.biotech_rounded;
    if (id.contains('TECH')) return Icons.laptop_chromebook_rounded;
    if (id.contains('COMMUNITY')) return Icons.groups_rounded;
    if (id.contains('LIFE') || id.contains('SKILL')) {
      return Icons.lightbulb_rounded;
    }
    if (id.contains('HIST')) return Icons.museum_rounded;
    if (id.contains('GEO')) return Icons.public_rounded;
    if (id.contains('GENERAL') || id.contains('KNOWLEDGE')) {
      return Icons.menu_book_rounded;
    }
    return Icons.quiz_rounded;
  }

  String? _getCategoryTagline(QuizCategory cat) {
    // If backend provides description in data model, display it; otherwise hide gracefully.
    return null;
  }
}

/// Recently Played card with prominent "Continue" button.
class QuizRecentlyPlayedCard extends StatelessWidget {
  const QuizRecentlyPlayedCard({
    super.key,
    required this.category,
    required this.onContinue,
  });

  final QuizCategory category;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.growthAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.growthAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'quiz.questionsCount'.trParams({
                    'count': '${category.questionCount}',
                  }),
                  style: TextStyle(
                    fontSize: 12,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onContinue,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: semantic.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 17,
                      color: semantic.textInverse,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'common.continue'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: semantic.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no recently played quizzes exist.
class QuizEmptyRecentlyPlayedCard extends StatelessWidget {
  const QuizEmptyRecentlyPlayedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.backgroundSecondary,
            ),
            child: Icon(
              Icons.history_rounded,
              color: semantic.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'quiz.noRecentQuizzes'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'quiz.noRecentQuizzesSubtitle'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1v1 multiplayer challenge promotional card navigating to [AppRoutes.quizMultiplayer].
class QuizMultiplayerChallengeCard extends StatelessWidget {
  const QuizMultiplayerChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semantic = context.semanticColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.quizMultiplayer),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? semantic.surface
                : const Color(0xFFFAF7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : AppColors.productivityAccent.withValues(alpha: 0.3),
            ),
            boxShadow: semantic.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.growthAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.growthAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'quiz.challengeFriendsTitle'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: semantic.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.challengeFriendsSubtitle'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: semantic.backgroundSecondary,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: semantic.primaryText,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
