import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_models.dart';
import 'widgets/community_widgets.dart';
import 'forum_discussion_screen.dart';

class ForumCategoryScreen extends StatelessWidget {
  final String categoryTitle;

  const ForumCategoryScreen({super.key, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    // Temporary isolated mock data based on existing ForumTopicModel
    final List<ForumTopicModel> categoryDiscussions = [
      ForumTopicModel(
        id: 'c1',
        title: 'Best resources for learning Flutter in 2026?',
        authorName: '@Rathana',
        category: categoryTitle,
        content:
            'I want to build cross-platform apps and need some updated resources. Any recommendations?',
        upvotes: 45,
        repliesCount: 12,
        timeAgo: '2h ago',
      ),
      ForumTopicModel(
        id: 'c2',
        title:
            'How to prepare for junior software engineer interviews in Cambodia?',
        authorName: '@Sokchea',
        category: categoryTitle,
        content: 'What should I focus on for entry-level positions locally?',
        upvotes: 89,
        repliesCount: 34,
        timeAgo: '5h ago',
      ),
      ForumTopicModel(
        id: 'c3',
        title: 'Has anyone integrated local payment gateways in Flutter?',
        authorName: '@DevKH',
        category: categoryTitle,
        content: 'Looking for KHQR integration examples in Dart.',
        upvotes: 120,
        repliesCount: 18,
        timeAgo: '1d ago',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 72,
        title: Text(
          categoryTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: categoryDiscussions.isEmpty
          ? Center(
              child: Text(
                'No discussions found.',
                style: TextStyle(color: textPrimary.withValues(alpha: 0.6)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              itemCount: categoryDiscussions.length,
              itemBuilder: (context, index) {
                final topic = categoryDiscussions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ForumThreadCard(
                    title: topic.title,
                    author: topic.authorName,
                    timeAgo: topic.timeAgo,
                    category: categoryTitle,
                    replies: topic.repliesCount,
                    likes: topic.upvotes,
                    isPinned: false,
                    isLiked: topic.isLiked,
                    onTap: () =>
                        Get.to(() => ForumDiscussionScreen(discussion: topic)),
                    onCommentTap: () =>
                        Get.to(() => ForumDiscussionScreen(discussion: topic)),
                  ),
                );
              },
            ),
    );
  }
}
