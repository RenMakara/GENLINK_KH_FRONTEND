import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_models.dart';

class ForumDiscussionScreen extends StatelessWidget {
  final ForumTopicModel discussion;

  const ForumDiscussionScreen({super.key, required this.discussion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 72,
        title: Text(
          'Discussion',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.communityAccent.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          discussion.authorName.substring(1, 2).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.communityAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discussion.authorName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              discussion.timeAgo,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Text(
                          discussion.category,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title & Content
                  Text(
                    discussion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    discussion.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textPrimary.withValues(alpha: 0.9),
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Actions
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        color: textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${discussion.upvotes}',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.comment_outlined,
                        color: textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${discussion.repliesCount}',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: AppSpacing.lg),

                  // Comments Section (Stubs)
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (discussion.repliesCount > 0)
                    ...List.generate(
                      2,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: surfaceSecondary,
                              child: Icon(
                                Icons.person,
                                size: 18,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: surfaceSecondary,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(color: borderSubtle),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '@User${index + 1}',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This is a helpful discussion. Thanks for sharing!',
                                      style: TextStyle(
                                        color: textPrimary.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Reply Input
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              border: Border(top: BorderSide(color: borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a reply...',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.communityAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.communityAccent,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
