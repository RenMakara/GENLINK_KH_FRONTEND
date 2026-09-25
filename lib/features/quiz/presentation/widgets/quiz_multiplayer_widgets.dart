import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/models/quiz_match_models.dart';
import '../../domain/models/quiz_models.dart';

/// Top header for 1v1 multiplayer screens.
class MultiplayerHeader extends StatelessWidget implements PreferredSizeWidget {
  const MultiplayerHeader({
    super.key,
    required this.onBack,
    this.title,
    this.subtitle,
    this.showTrophy = true,
    this.onTrophyTap,
    this.padding,
    this.actions,
  });

  final VoidCallback onBack;
  final String? title;
  final String? subtitle;
  final bool showTrophy;
  final VoidCallback? onTrophyTap;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppBackButton(onPressed: onBack),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? 'quiz.multiplayerQuiz'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: semantic.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...?actions,
          if (showTrophy) ...[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: 'quiz.leaderboard'.tr,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTrophyTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.growthAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.growthAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.growthAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Search bar for 1v1 quizzes.
class MultiplayerQuizSearchBar extends StatelessWidget {
  const MultiplayerQuizSearchBar({
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
        style: TextStyle(fontSize: 14, color: semantic.primaryText),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'quiz.searchQuizzes'.tr,
          hintStyle: TextStyle(fontSize: 14, color: semantic.textMuted),
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

/// Horizontal category filter chips.
class MultiplayerCategoryFilterChips extends StatelessWidget {
  const MultiplayerCategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final List<QuizCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final categoryId = isAll ? 'ALL' : categories[index - 1].id;
          final label = isAll ? 'quiz.all'.tr : categories[index - 1].name;
          final isSelected = selectedCategoryId.toUpperCase() ==
              categoryId.toUpperCase();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategorySelected(categoryId),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? semantic.primary : semantic.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected ? semantic.primary : semantic.borderSubtle,
                  ),
                  boxShadow: isSelected ? semantic.cardShadow : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? semantic.textInverse
                          : semantic.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Styled quiz card for 1v1 selection.
class MultiplayerQuizCard extends StatelessWidget {
  const MultiplayerQuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  final QuizSummary quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final accent = _getCategoryAccent(quiz.category);
    final icon = _getCategoryIcon(quiz.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: semantic.primaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${'quiz.questionsCount'.trParams({'count': '${quiz.questionCount}'})} · ${quiz.xpReward} XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: semantic.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryAccent(String? category) {
    final cat = (category ?? '').toUpperCase();
    if (cat.contains('FINANCE')) return AppColors.financeAccent;
    if (cat.contains('HEALTH') || cat.contains('SCIENCE')) {
      return AppColors.success;
    }
    if (cat.contains('TECH')) return AppColors.brandPrimary;
    if (cat.contains('COMMUNITY')) return AppColors.communityAccent;
    if (cat.contains('LIFE') || cat.contains('SKILL')) {
      return AppColors.growthAccent;
    }
    return AppColors.productivityAccent;
  }

  IconData _getCategoryIcon(String? category) {
    final cat = (category ?? '').toUpperCase();
    if (cat.contains('FINANCE')) return Icons.account_balance_wallet_rounded;
    if (cat.contains('HEALTH')) return Icons.favorite_rounded;
    if (cat.contains('SCIENCE')) return Icons.biotech_rounded;
    if (cat.contains('TECH')) return Icons.laptop_chromebook_rounded;
    if (cat.contains('COMMUNITY')) return Icons.groups_rounded;
    if (cat.contains('LIFE') || cat.contains('SKILL')) {
      return Icons.lightbulb_rounded;
    }
    return Icons.quiz_rounded;
  }
}

/// Secondary discovery footer card.
class MultiplayerDiscoveryCard extends StatelessWidget {
  const MultiplayerDiscoveryCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.communityAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.communityAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'quiz.cantFindQuiz'.tr,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'quiz.moreQuizzesComingSoon'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: semantic.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Hero matchup view showing [User vs Opponent] with subtle animated radar.
class MultiplayerMatchupHero extends StatefulWidget {
  const MultiplayerMatchupHero({
    super.key,
    required this.currentUser,
    required this.opponent,
    required this.isSearching,
  });

  final UserEntity? currentUser;
  final QuizMatchPlayer? opponent;
  final bool isSearching;

  @override
  State<MultiplayerMatchupHero> createState() => _MultiplayerMatchupHeroState();
}

class _MultiplayerMatchupHeroState extends State<MultiplayerMatchupHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isSearching) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MultiplayerMatchupHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearching && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSearching && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final opponentFound = widget.opponent != null &&
        widget.opponent?.name?.trim().isNotEmpty == true;

    return Center(
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Celestial / Radar background rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 280,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: semantic.borderSubtle.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Side
                Expanded(
                  child: _buildPlayerColumn(
                    avatar: AppAvatar(
                      imageUrl: widget.currentUser?.avatarUrl,
                      name: widget.currentUser?.fullName,
                      size: 72,
                    ),
                    name: 'quiz.you'.tr,
                    levelText: 'quiz.levelIndicator'.trParams({
                      'level': '${widget.currentUser?.level ?? 1}',
                    }),
                    badgeColor: AppColors.brandPrimary,
                    hasCrown: true,
                  ),
                ),

                const SizedBox(width: 10),

                // Center VS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: semantic.borderSubtle),
                    boxShadow: semantic.cardShadow,
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: semantic.primaryText,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Opponent Side
                Expanded(
                  child: opponentFound
                      ? _buildPlayerColumn(
                          avatar: AppAvatar(
                            name: widget.opponent!.name,
                            size: 72,
                          ),
                          name: widget.opponent!.name ?? 'quiz.opponent'.tr,
                          levelText: 'quiz.opponent'.tr,
                          badgeColor: AppColors.growthAccent,
                          hasCrown: false,
                        )
                      : _buildUnknownOpponentColumn(semantic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerColumn({
    required Widget avatar,
    required String name,
    required String levelText,
    required Color badgeColor,
    required bool hasCrown,
  }) {
    final semantic = context.semanticColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.6),
                  width: 2.5,
                ),
              ),
              child: avatar,
            ),
            if (hasCrown)
              Positioned(
                top: -10,
                right: -4,
                child: Transform.rotate(
                  angle: 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.growthAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: semantic.primaryText,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            levelText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnknownOpponentColumn(dynamic semantic) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final alpha = 0.2 + (_pulseController.value * 0.4);
            return Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: semantic.primary.withValues(alpha: alpha),
                  width: 2.5,
                ),
              ),
              child: child,
            );
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.backgroundSecondary,
            ),
            child: Icon(
              Icons.question_mark_rounded,
              size: 32,
              color: semantic.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'quiz.findingOpponent'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: semantic.secondaryText,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: semantic.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'quiz.levelUnknown'.tr,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: semantic.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Feature highlights row for matchmaking (Real-time, Fair Match, Safe & Fun).
class MultiplayerFeatureHighlightsRow extends StatelessWidget {
  const MultiplayerFeatureHighlightsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.bolt_rounded,
              iconColor: AppColors.growthAccent,
              title: 'quiz.realtimeFeature'.tr,
              desc: 'quiz.realtimeFeatureDesc'.tr,
              semantic: semantic,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: semantic.borderSubtle,
          ),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.groups_rounded,
              iconColor: AppColors.brandPrimary,
              title: 'quiz.fairMatchFeature'.tr,
              desc: 'quiz.fairMatchFeatureDesc'.tr,
              semantic: semantic,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: semantic.borderSubtle,
          ),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.security_rounded,
              iconColor: AppColors.communityAccent,
              title: 'quiz.safeFunFeature'.tr,
              desc: 'quiz.safeFunFeatureDesc'.tr,
              semantic: semantic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required dynamic semantic,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: semantic.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              color: semantic.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Did you know?" tip card for the waiting screen.
class MultiplayerDidYouKnowCard extends StatelessWidget {
  const MultiplayerDidYouKnowCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.brandPrimary,
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
                  'quiz.didYouKnow'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'quiz.didYouKnowTip'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
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

/// Cancel Match button with distinct soft destructive styling.
class CancelMatchButton extends StatelessWidget {
  const CancelMatchButton({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCancel,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.28),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'quiz.cancelMatch'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1v1 Scoreboard displaying User vs Opponent with avatars, names, and scores.
class MultiplayerScoreboard extends StatelessWidget {
  const MultiplayerScoreboard({
    super.key,
    this.currentUser,
    this.currentUserName,
    required this.playerScore,
    this.opponent,
    this.opponentName,
    required this.opponentScore,
    this.highlightWinner = false,
    this.isWinner = false,
    this.isTie = false,
  });

  final UserEntity? currentUser;
  final String? currentUserName;
  final int playerScore;
  final QuizMatchPlayer? opponent;
  final String? opponentName;
  final int opponentScore;
  final bool highlightWinner;
  final bool isWinner;
  final bool isTie;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final userName = currentUserName ?? currentUser?.fullName ?? 'quiz.you'.tr;
    final opName = opponentName ?? opponent?.name ?? 'quiz.opponent'.tr;

    final userWon = highlightWinner && !isTie && isWinner;
    final opponentWon = highlightWinner && !isTie && !isWinner;

    return Row(
      children: [
        // User Player Card
        Expanded(
          child: _buildPlayerCard(
            context,
            avatar: AppAvatar(
              imageUrl: currentUser?.avatarUrl,
              name: userName,
              size: 42,
            ),
            name: userName,
            score: playerScore,
            isWinning: userWon,
            semantic: semantic,
          ),
        ),

        const SizedBox(width: 10),

        // Central VS Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: semantic.borderSubtle),
            boxShadow: semantic.cardShadow,
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: semantic.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Opponent Player Card
        Expanded(
          child: _buildPlayerCard(
            context,
            avatar: AppAvatar(
              name: opName,
              size: 42,
            ),
            name: opName,
            score: opponentScore,
            isWinning: opponentWon,
            semantic: semantic,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    BuildContext context, {
    required Widget avatar,
    required String name,
    required int score,
    required bool isWinning,
    required dynamic semantic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinning
              ? AppColors.growthAccent.withValues(alpha: 0.6)
              : semantic.borderSubtle,
          width: isWinning ? 1.5 : 1.0,
        ),
        boxShadow: semantic.cardShadow,
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: semantic.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isWinning
                        ? AppColors.growthAccent
                        : semantic.primaryText,
                    height: 1.1,
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

/// Question count progress bar alongside a compact circular countdown timer.
class MultiplayerProgressAndTimer extends StatelessWidget {
  const MultiplayerProgressAndTimer({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.timeRemaining,
    this.totalDuration = 15,
  });

  final int currentIndex;
  final int totalQuestions;
  final int timeRemaining;
  final int totalDuration;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final currentNumber = currentIndex + 1;
    final progress = totalQuestions > 0 ? currentNumber / totalQuestions : 0.0;
    final isLow = timeRemaining <= 5;
    final timerColor = isLow ? AppColors.danger : semantic.primary;
    final timerFraction = totalDuration > 0
        ? (timeRemaining / totalDuration).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Progress Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'quiz.questionOfTotal'.trParams({
                  'current': '$currentNumber',
                  'total': '$totalQuestions',
                }),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: semantic.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: semantic.borderSubtle.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(semantic.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Circular Timer Badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: timerColor.withValues(alpha: 0.08),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: timerFraction,
                  strokeWidth: 3.5,
                  backgroundColor: timerColor.withValues(alpha: 0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              Text(
                'quiz.secondsShort'.trParams({'seconds': '$timeRemaining'}),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: timerColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Elevated question card with category badge, question text, and subtitle hint.
class MultiplayerQuestionCard extends StatelessWidget {
  const MultiplayerQuestionCard({
    super.key,
    this.category,
    required this.question,
    this.hint,
  });

  final String? category;
  final String question;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null && category!.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.growthAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 15,
                    color: AppColors.growthAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    category!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.growthAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: semantic.primaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint ?? 'quiz.chooseCorrectAnswer'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: semantic.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Answer option card with letter badge (A, B, C, D) and selected/disabled states.
class MultiplayerOptionTile extends StatelessWidget {
  const MultiplayerOptionTile({
    super.key,
    required this.label,
    required this.index,
    required this.isSelected,
    this.isDisabled = false,
    this.onTap,
  });

  final String label;
  final int index;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final letter = String.fromCharCode(65 + index);

    final borderColor = isSelected ? semantic.primary : semantic.borderSubtle;
    final backgroundColor = isSelected
        ? semantic.primary.withValues(alpha: 0.08)
        : semantic.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected ? semantic.cardShadow : null,
            ),
            child: Row(
              children: [
                // Letter badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? semantic.primary
                        : semantic.backgroundSecondary,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? semantic.textInverse
                            : semantic.secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Answer Text
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: semantic.primaryText,
                      height: 1.35,
                    ),
                  ),
                ),

                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: semantic.primary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action button for submitting answer.
class MultiplayerSubmitButton extends StatelessWidget {
  const MultiplayerSubmitButton({
    super.key,
    required this.onSubmit,
    required this.isEnabled,
    this.isSubmitting = false,
  });

  final VoidCallback? onSubmit;
  final bool isEnabled;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final backgroundColor = isEnabled && !isSubmitting
        ? semantic.primary
        : semantic.borderSubtle.withValues(alpha: 0.5);

    final textColor = isEnabled && !isSubmitting
        ? semantic.textInverse
        : semantic.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled && !isSubmitting ? onSubmit : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: isSubmitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        semantic.textInverse,
                      ),
                    ),
                  )
                : Text(
                    'quiz.submitAnswer'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Celebratory hero banner on match completion.
class MultiplayerResultBanner extends StatelessWidget {
  const MultiplayerResultBanner({
    super.key,
    required this.isWinner,
    required this.isTie,
    this.customTitle,
    this.customSubtitle,
  });

  final bool isWinner;
  final bool isTie;
  final String? customTitle;
  final String? customSubtitle;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final title = customTitle ??
        (isWinner
            ? 'quiz.matchWon'.tr
            : isTie
                ? 'quiz.matchTie'.tr
                : 'quiz.matchComplete'.tr);

    final subtitle = customSubtitle ??
        (isWinner
            ? 'quiz.matchWonSubtitle'.tr
            : isTie
                ? 'quiz.matchTieSubtitle'.tr
                : 'quiz.matchLostSubtitle'.tr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trophy Illustration with celebratory aura
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.growthAccent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.growthAccent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                top: 10,
                right: 12,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.growthAccent,
                ),
              ),
              const Positioned(
                bottom: 12,
                left: 12,
                child: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.growthAccent,
                ),
              ),
              Icon(
                isTie || isWinner
                    ? Icons.emoji_events_rounded
                    : Icons.military_tech_rounded,
                size: 48,
                color: AppColors.growthAccent,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: semantic.primaryText,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: semantic.secondaryText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// XP Result Card showing earned XP.
class MultiplayerXpCard extends StatelessWidget {
  const MultiplayerXpCard({super.key, required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.growthAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'quiz.xpEarned'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: semantic.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '+$xp XP',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: semantic.primaryText,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Motivational Card encouraging continued participation.
class MultiplayerMotivationalCard extends StatelessWidget {
  const MultiplayerMotivationalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.brandPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'quiz.keepGoingTitle'.tr,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'quiz.keepGoingMessage'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: semantic.secondaryText,
                    height: 1.35,
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

