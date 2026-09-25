import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/opportunity_model.dart';
import '../controllers/community_controller.dart';
import '../screens/opportunity_details_screen.dart';
import 'community_design_tokens.dart';

class OpportunityCardWidget extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback? onBookmarkToggle;

  const OpportunityCardWidget({
    super.key,
    required this.opportunity,
    this.onBookmarkToggle,
  });

  Color _getTypeColor(String type) {
    final upper = type.toUpperCase();
    switch (upper) {
      case 'INTERNSHIP':
        return const Color(0xFF2563EB); // Royal Blue
      case 'SCHOLARSHIP':
        return const Color(0xFFD97706); // Amber / Gold
      case 'JOB':
      case 'FULL_TIME':
      case 'FULL-TIME':
        return const Color(0xFF059669); // Emerald Green
      case 'HACKATHON':
        return const Color(0xFF7C3AED); // Vivid Purple
      case 'VOLUNTEER':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final mutedText =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final typeColor = _getTypeColor(opportunity.type);
    final initialLetter = opportunity.organization.isNotEmpty
        ? opportunity.organization[0].toUpperCase()
        : (opportunity.title.isNotEmpty
            ? opportunity.title[0].toUpperCase()
            : 'O');

    return Container(
      margin: const EdgeInsets.only(
        left: CommunityCardStyle.pageHorizontalMargin,
        right: CommunityCardStyle.pageHorizontalMargin,
        bottom: CommunityCardStyle.cardBottomMargin,
      ),
      decoration: CommunityCardStyle.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CommunityCardStyle.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(CommunityCardStyle.cardRadius),
          onTap: () {
            Get.to(
              () => OpportunityDetailsScreen(opportunity: opportunity),
              transition: Transition.cupertino,
            );
          },
          child: Padding(
            padding: CommunityCardStyle.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Org initial, Org name, Location, Bookmark button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: typeColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initialLetter,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opportunity.organization.isNotEmpty
                                ? opportunity.organization
                                : 'GenLink Opportunity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (opportunity.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: mutedText,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    opportunity.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Bookmark Button
                    GetBuilder<CommunityController>(
                      builder: (controller) {
                        final isSaved = opportunity.savedByMe;
                        final isLoading = controller
                            .opportunityBookmarkLoadingIds
                            .contains(opportunity.id);

                        return SizedBox(
                          width: 36,
                          height: 36,
                          child: isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 21,
                                  splashRadius: 18,
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: isSaved
                                        ? AppColors.brandPrimary
                                        : mutedText,
                                  ),
                                  onPressed: () {
                                    if (onBookmarkToggle != null) {
                                      onBookmarkToggle!();
                                    } else {
                                      controller.toggleOpportunityBookmark(
                                        opportunity.id,
                                      );
                                    }
                                  },
                                ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Title
                Text(
                  opportunity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),

                if (opportunity.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    opportunity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Bottom row: Type pill, Deadline countdown chip, and Arrow
                Row(
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: typeColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        opportunity.displayType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Deadline Chip
                    _buildDeadlineChip(context, isDark),

                    const Spacer(),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: mutedText.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(BuildContext context, bool isDark) {
    if (opportunity.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_outlined, size: 12, color: Colors.red),
            SizedBox(width: 3),
            Text(
              'Expired',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final days = opportunity.daysLeft;
    final isExpiringSoon = opportunity.isExpiringSoon;
    final chipColor = isExpiringSoon
        ? const Color(0xFFD97706)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    final text = days != null
        ? (days == 0
            ? 'Due today'
            : (days == 1 ? '1 day left' : '$days days left'))
        : opportunity.formattedDeadline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? const Color(0xFFD97706).withValues(alpha: isDark ? 0.18 : 0.10)
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpiringSoon ? Icons.access_time_rounded : Icons.calendar_today_outlined,
            size: 11.5,
            color: chipColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: isExpiringSoon ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
