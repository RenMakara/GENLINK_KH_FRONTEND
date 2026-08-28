import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../community_search_screen.dart';
import '../create_discussion_screen.dart';

// FORUM CATEGORY CARD
class ForumCategoryCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;
  final Color? accent;
  final bool isSelected;
  final VoidCallback? onTap;

  const ForumCategoryCard({
    super.key,
    required this.title,
    required this.count,
    this.icon,
    this.accent,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF171717) : const Color(0xFFF2F2EF));

    final cardBorder = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF303030) : AppColors.lightBorderSubtle);

    final titleColor = isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary);
    final countColor = isSelected ? Colors.black.withValues(alpha: 0.65) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final iconBoxBg = isSelected ? Colors.black.withValues(alpha: 0.08) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05));
    final iconColor = isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: countColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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

// FORUM THREAD CARD
class ForumThreadCard extends StatelessWidget {
  final String title;
  final String author;
  final String? avatarUrl;
  final String timeAgo;
  final String category;
  final int replies;
  final int likes;
  final bool isPinned;
  final VoidCallback? onTap;

  const ForumThreadCard({
    super.key,
    required this.title,
    required this.author,
    this.avatarUrl,
    required this.timeAgo,
    required this.category,
    required this.replies,
    required this.likes,
    required this.isPinned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? const Color(0xFF171717) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? const Color(0xFF303030) : AppColors.lightBorderSubtle;

    return InkWell(
      onTap: onTap ?? () => Get.to(() => const CreateDiscussionScreen()),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(
            color: isPinned
                ? textPrimary.withValues(alpha: 0.3)
                : borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? (avatarUrl!.startsWith('assets/')
                          ? AssetImage(avatarUrl!) as ImageProvider
                          : NetworkImage(avatarUrl!))
                      : const AssetImage('assets/images/user_profile.png'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      if (isPinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ) ??
                              TextStyle(
                                color: textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "• $timeAgo",
                        style: theme.textTheme.labelMedium?.copyWith(color: textMuted) ??
                            TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: borderSubtle, width: 0.8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: textSecondary,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$likes",
                      style: theme.textTheme.labelMedium?.copyWith(color: textSecondary) ??
                          TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: textSecondary,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$replies comments",
                      style: theme.textTheme.labelMedium?.copyWith(color: textSecondary) ??
                          TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// JOB CARD
class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String type;
  final String salary;
  final Color logoColor;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.type,
    required this.salary,
    required this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return InkWell(
      onTap: () => Get.to(() => const CommunitySearchScreen(activeTab: 'Career')),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.business_rounded,
                color: textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company,
                    style: theme.textTheme.bodySmall?.copyWith(color: textSecondary) ??
                        TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: textPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        salary,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.bold,
                            ) ??
                            TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
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

// MENTOR CARD
class MentorCard extends StatelessWidget {
  final String name;
  final String role;
  final String avatarUrl;

  const MentorCard({
    super.key,
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return InkWell(
      onTap: () => Get.to(() => const CommunitySearchScreen(activeTab: 'Career')),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.sm + 4),
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 10,
                  ) ??
                  TextStyle(color: textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Career & Networking Tab View component
/// Preserved as a standalone widget for Career feature entry points.
class CareerTabView extends StatelessWidget {
  const CareerTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context-Aware Career Search Bar
            InkWell(
              onTap: () => Get.to(
                () => const CommunitySearchScreen(activeTab: 'Career'),
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'community.searchJobs'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                          TextStyle(color: textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recommended Opportunities Hero List
            Text(
              'community.recommendedOpportunities'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const JobCard(
              title: "Junior Flutter Developer",
              company: "ABA Bank • Phnom Penh",
              type: "Full-Time",
              salary: "\$600 - \$900 / mo",
              logoColor: AppColors.brandPrimary,
            ),
            const JobCard(
              title: "UI/UX Design Intern",
              company: "Smart Axiata • Phnom Penh",
              type: "Internship",
              salary: "\$250 - \$350 / mo",
              logoColor: AppColors.danger,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Campus Alumni Mentors
            Text(
              'community.campusAlumniMentors'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MentorCard(
                    name: "Sokha Kim",
                    role: "Senior Tech Lead @ Wing",
                    avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                  ),
                  MentorCard(
                    name: "Bopha V.",
                    role: "Lead UX Designer @ ABA",
                    avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
                  ),
                  MentorCard(
                    name: "Dara N.",
                    role: "Mobile Architect @ Chip Mong",
                    avatarUrl: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

