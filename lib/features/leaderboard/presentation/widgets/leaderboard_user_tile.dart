import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../domain/models/leaderboard_models.dart';

/// Reusable user tile for Leaderboard and Global Ranking lists.
class LeaderboardUserTile extends StatelessWidget {
  const LeaderboardUserTile({
    super.key,
    required this.entry,
    this.onTap,
    this.showPointsLabel = true,
    this.showMedalIcon = false,
    this.isCard = true,
  });

  final LeaderboardEntry entry;
  final VoidCallback? onTap;
  final bool showPointsLabel;
  final bool showMedalIcon;
  final bool isCard;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final isTop1 = entry.rank == 1 && showMedalIcon;
    final isTop2 = entry.rank == 2 && showMedalIcon;
    final isTop3 = entry.rank == 3 && showMedalIcon;

    Color? medalColor;
    if (showMedalIcon) {
      if (entry.rank == 1) medalColor = const Color(0xFFF59E0B);
      if (entry.rank == 2) medalColor = const Color(0xFF94A3B8);
      if (entry.rank == 3) medalColor = const Color(0xFFD97706);
    }

    Color tileBg;
    if (entry.isCurrentUser) {
      tileBg = isDark
          ? Color.alphaBlend(AppColors.brandPrimary.withValues(alpha: 0.16), semantic.surface)
          : Color.alphaBlend(AppColors.brandPrimary.withValues(alpha: 0.08), Colors.white);
    } else if (isTop1) {
      tileBg = isDark
          ? Color.alphaBlend(const Color(0xFFF59E0B).withValues(alpha: 0.12), semantic.surface)
          : const Color(0xFFFFFBEB);
    } else if (isTop2) {
      tileBg = isDark
          ? Color.alphaBlend(const Color(0xFF94A3B8).withValues(alpha: 0.08), semantic.surface)
          : const Color(0xFFF8FAFC);
    } else if (isTop3) {
      tileBg = isDark
          ? Color.alphaBlend(const Color(0xFFD97706).withValues(alpha: 0.08), semantic.surface)
          : const Color(0xFFFFFDF5);
    } else {
      tileBg = isDark ? semantic.surface : Colors.white;
    }

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCard ? 14 : 10,
        vertical: isCard ? 12 : 10,
      ),
      child: Row(
        children: [
          // Rank Badge / Number
          SizedBox(
            width: 32,
            child: isTop1
                ? Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: entry.isCurrentUser
                          ? AppColors.brandPrimary
                          : (medalColor ?? semantic.primaryText),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // User Avatar
          AppAvatar(
            imageUrl: entry.avatarUrl,
            name: entry.name,
            size: 40,
          ),
          const SizedBox(width: 12),
          // Username and Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: entry.isCurrentUser
                              ? AppColors.brandPrimary
                              : semantic.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'quiz.you'.tr,
                          style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${'leaderboard.level'.tr} ${entry.level}',
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points
          Text(
            showPointsLabel
                ? '${entry.points} ${'leaderboard.points'.tr}'
                : '${entry.points}',
            style: TextStyle(
              color: entry.isCurrentUser ? AppColors.brandPrimary : semantic.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: showPointsLabel ? 12.5 : 14,
            ),
          ),
          if (showMedalIcon && medalColor != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.military_tech_rounded,
              color: medalColor,
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (!isCard) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.brandPrimary
              : (isTop1
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : (isDark
                      ? semantic.borderSubtle
                      : semantic.borderSubtle.withValues(alpha: 0.8))),
          width: entry.isCurrentUser ? 1.4 : 1.0,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: content,
        ),
      ),
    );
  }
}
