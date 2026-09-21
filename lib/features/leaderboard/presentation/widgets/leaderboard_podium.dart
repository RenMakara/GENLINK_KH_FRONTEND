import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../domain/models/leaderboard_models.dart';

/// Top 3 podium section (#2 on left, #1 in center elevated, #3 on right).
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.entries,
    this.onTapUser,
  });

  final List<LeaderboardEntry> entries;
  final ValueChanged<LeaderboardEntry>? onTapUser;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final rank1 = entries.isNotEmpty ? entries[0] : null;
    final rank2 = entries.length > 1 ? entries[1] : null;
    final rank3 = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank #2 (Left)
        Expanded(
          child: rank2 != null
              ? _buildPodiumColumn(
                  context: context,
                  entry: rank2,
                  rankNumber: 2,
                  avatarSize: 52,
                  isElevated: false,
                  accentColor: const Color(0xFF94A3B8), // Silver
                  crownColor: const Color(0xFF94A3B8),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        // Rank #1 (Center, taller)
        Expanded(
          child: rank1 != null
              ? _buildPodiumColumn(
                  context: context,
                  entry: rank1,
                  rankNumber: 1,
                  avatarSize: 62,
                  isElevated: true,
                  accentColor: AppColors.warning, // Gold
                  crownColor: const Color(0xFFF59E0B),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        // Rank #3 (Right)
        Expanded(
          child: rank3 != null
              ? _buildPodiumColumn(
                  context: context,
                  entry: rank3,
                  rankNumber: 3,
                  avatarSize: 52,
                  isElevated: false,
                  accentColor: const Color(0xFFD97706), // Bronze
                  crownColor: const Color(0xFFD97706),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required BuildContext context,
    required LeaderboardEntry entry,
    required int rankNumber,
    required double avatarSize,
    required bool isElevated,
    required Color accentColor,
    required Color crownColor,
  }) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapUser != null ? () => onTapUser!(entry) : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: isElevated ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Color.alphaBlend(
                    accentColor.withValues(alpha: isElevated ? 0.14 : 0.08),
                    semantic.surface,
                  )
                : Color.alphaBlend(
                    accentColor.withValues(alpha: isElevated ? 0.10 : 0.05),
                    Colors.white,
                  ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
              width: isElevated ? 1.5 : 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isElevated ? 0.12 : 0.05),
                      blurRadius: isElevated ? 14 : 8,
                      offset: Offset(0, isElevated ? 4 : 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown Icon
              Icon(
                Icons.emoji_events_rounded,
                color: crownColor,
                size: isElevated ? 22 : 18,
              ),
              const SizedBox(height: 4),
              // Avatar with Stacked Rank Pill
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize + 4,
                    height: avatarSize + 4,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor,
                        width: isElevated ? 2.0 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: AppAvatar(
                        imageUrl: entry.avatarUrl,
                        name: entry.name,
                        size: avatarSize,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? semantic.surface : Colors.white,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        '$rankNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // User Name
              Text(
                entry.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: semantic.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              // Points
              Text(
                '${entry.points} ${'leaderboard.points'.tr}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 6),
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? semantic.surfaceElevated
                      : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${'leaderboard.level'.tr} ${entry.level}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? semantic.secondaryText : semantic.primaryText,
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
