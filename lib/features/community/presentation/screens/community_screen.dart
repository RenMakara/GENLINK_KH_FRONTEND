import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_header_widget.dart';
import '../widgets/filter_events_sheet.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/story_tray_widget.dart';
import 'community_search_screen.dart';
import 'create_post_screen.dart';
import 'event_details_screen.dart';
import 'forum_category_screen.dart';
import 'forum_discussion_screen.dart';
import '../../domain/models/community_models.dart';
import 'widgets/community_widgets.dart';

/// GenLink KH Community Screen
///
/// Features 4 sticky navigation tabs: Feed, Forum, Career, Event.
/// Architected with GetX, responsive web/tablet constraints, and
/// strict adherence to GenLink design tokens and GetX navigation.
class CommunityScreen extends GetView<CommunityController> {
  const CommunityScreen({super.key});

  CommunityController get _effectiveController {
    return Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());
  }

  @override
  Widget build(BuildContext context) {
    final commController = _effectiveController;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: Obx(
          () => CommunityHeaderWidget(
            activeCategory: commController.selectedCategory.value,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),

              // STICKY NAVIGATION TABS (Feed, Forum, Career, Event)
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: commController.categories.map((cat) {
                      final isSelected =
                          commController.selectedCategory.value == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: InkWell(
                          onTap: () => commController.setCategory(cat),
                          borderRadius: BorderRadius.circular(AppRadius.squircle),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? textPrimary
                                  : surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.squircle),
                              border: Border.all(
                                color: isSelected
                                    ? textPrimary
                                    : borderSubtle,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'community.${cat.toLowerCase()}'.tr,
                              style: theme.textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.darkTextInverse
                                            : AppColors.lightTextInverse)
                                        : textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ) ??
                                  TextStyle(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.darkTextInverse
                                            : AppColors.lightTextInverse)
                                        : textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // DYNAMIC TAB CONTENT BODY
              Expanded(
                child: Obx(() {
                  switch (commController.selectedCategory.value) {
                    case 'Forum':
                      return _buildForumTab(context, commController);
                    case 'Career':
                      return _buildCareerTab(context, commController);
                    case 'Event':
                      return _buildEventTab(context, commController);
                    case 'Feed':
                    default:
                      return _buildFeedTab(context, commController);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FEED TAB
  Widget _buildFeedTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;

    return RefreshIndicator(
      onRefresh: () => controller.refreshFeed(),
      color: AppColors.communityAccent,
      backgroundColor: surfaceSecondary,
      child: SingleChildScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stories Tray
            const StoryTrayWidget(),

            const SizedBox(height: AppSpacing.md),

            // Create Post Quick Bar (Senior UI/UX Redesign - Finance Aligned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: InkWell(
                onTap: () => Get.to(() => const CreatePostScreen()),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage('assets/images/user_profile.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'community.whatsHappeningSokny'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.5,
                                  ) ??
                                  TextStyle(
                                    color: textPrimary,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'community.shareWithCommunity'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ) ??
                                  TextStyle(
                                    color: textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_note_rounded,
                        color: textMuted.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Feed Posts List
            Obx(() {
              if (controller.isLoadingFeed.value) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.communityAccent,
                    ),
                  ),
                );
              }

              if (controller.hasError.value && controller.posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : 'community.couldNotLoadFeed'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary) ??
                            TextStyle(color: textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () => controller.fetchPosts(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text('common.retry'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.communityAccent,
                          foregroundColor: textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'community.noPostsYet'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                          TextStyle(color: textMuted),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.posts.length,
                    itemBuilder: (context, index) {
                      final post = controller.posts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: PostCardWidget(
                          post: post,
                          controller: controller,
                        ),
                      );
                    },
                  ),
                  if (controller.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.communityAccent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              );
            }),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // FORUM TAB
  Widget _buildForumTab(BuildContext context, CommunityController controller) {
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
            // Context-Aware Forum Search Bar
            InkWell(
              onTap: () => Get.to(
                () => const CommunitySearchScreen(activeTab: 'Forum'),
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
                      Icons.search,
                      color: textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'community.searchDiscussions'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                          TextStyle(color: textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Trending Topics
            Text(
              'community.trendingTopics'.tr,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  '#FlutterTech',
                  '#CampusHackathon',
                  '#CADTDesign',
                  '#RUPPExams',
                  '#AIWorkshop',
                ].map((topic) {
                  return InkWell(
                    onTap: () => Get.to(
                      () => ForumCategoryScreen(categoryTitle: topic),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.communityAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.communityAccent,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              color: AppColors.communityAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Forum Categories
            Text(
              'community.forumCategories'.tr,
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ForumCategoryCard(
                  title: "💻 Tech & Coding",
                  count: "342 Discussions",
                  accent: AppColors.communityAccent,
                  onTap: () => Get.to(() => const ForumCategoryScreen(categoryTitle: "Tech & Coding")),
                ),
                ForumCategoryCard(
                  title: "🎓 Campus Life",
                  count: "189 Discussions",
                  accent: AppColors.success,
                  onTap: () => Get.to(() => const ForumCategoryScreen(categoryTitle: "Campus Life")),
                ),
                ForumCategoryCard(
                  title: "📚 Academics",
                  count: "256 Discussions",
                  accent: AppColors.warning,
                  onTap: () => Get.to(() => const ForumCategoryScreen(categoryTitle: "Academics")),
                ),
                ForumCategoryCard(
                  title: "🚀 Projects",
                  count: "120 Discussions",
                  accent: AppColors.productivityAccent,
                  onTap: () => Get.to(() => const ForumCategoryScreen(categoryTitle: "Projects")),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Pinned & Latest Discussions List
            Text(
              'community.pinnedDiscussions'.tr,
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
            ForumThreadCard(
              title: "Guidelines for GenLink KH Annual Student Project Showcase 2026",
              author: "Admin Team",
              timeAgo: "1d ago",
              replies: 48,
              upvotes: 142,
              isPinned: true,
              onTap: () => Get.to(() => ForumDiscussionScreen(discussion: ForumTopicModel(id: '1', title: "Guidelines for GenLink KH Annual Student Project Showcase 2026", authorName: "Admin Team", timeAgo: "1d ago", repliesCount: 48, upvotes: 142, category: "Announcements", content: "Here are the guidelines for the upcoming 2026 student showcase."))),
            ),
            ForumThreadCard(
              title: "Best resources to master Flutter state management with GetX?",
              author: "Sokchea Lim",
              timeAgo: "3h ago",
              replies: 16,
              upvotes: 34,
              isPinned: false,
              onTap: () => Get.to(() => ForumDiscussionScreen(discussion: ForumTopicModel(id: '2', title: "Best resources to master Flutter state management with GetX?", authorName: "Sokchea Lim", timeAgo: "3h ago", repliesCount: 16, upvotes: 34, category: "Tech & Coding", content: "I've been struggling with state management. What are the best resources for GetX?"))),
            ),
            ForumThreadCard(
              title: "How to prepare for junior software engineer interviews in Cambodia?",
              author: "Rathana P.",
              timeAgo: "6h ago",
              replies: 29,
              upvotes: 65,
              isPinned: false,
              onTap: () => Get.to(() => ForumDiscussionScreen(discussion: ForumTopicModel(id: '3', title: "How to prepare for junior software engineer interviews in Cambodia?", authorName: "Rathana P.", timeAgo: "6h ago", repliesCount: 29, upvotes: 65, category: "Career", content: "Looking for tips on how to pass entry-level tech interviews here."))),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // CAREER TAB
  Widget _buildCareerTab(BuildContext context, CommunityController controller) {
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

  // EVENT TAB
  Widget _buildEventTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final eventsList = controller.events;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const CommunitySearchScreen(activeTab: 'Event'),
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
                            Icons.search,
                            color: textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'community.searchEventsHint'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                                TextStyle(color: textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    Get.bottomSheet(
                      const FilterEventsSheet(),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.communityAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.communityAccent),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.communityAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Featured Events Carousel
            Text(
              'community.featuredEvents'.tr,
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
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eventsList.length,
                itemBuilder: (context, idx) {
                  final ev = eventsList[idx];
                  return InkWell(
                    onTap: () => Get.to(() => EventDetailsScreen(event: ev)),
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.squircle),
                        image: ev.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(ev.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.squircle),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.darkBgPrimary.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ev.eventType == 'In person' ? ev.location : 'Online Event',
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.communityAccent,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  const TextStyle(
                                    color: AppColors.communityAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Event List
            Text(
              'community.upcomingEvents'.tr,
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
            ...eventsList.map((ev) {
              return InkWell(
                onTap: () => Get.to(() => EventDetailsScreen(event: ev)),
                borderRadius: BorderRadius.circular(AppRadius.squircle),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                        child: Image.network(
                              ev.imageUrl.isNotEmpty ? ev.imageUrl : 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=300',
                              width: 75,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, _) => Container(
                                width: 75,
                                height: 75,
                                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                                child: const Icon(Icons.event_outlined, size: 32),
                              ),
                            ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ) ??
                                  TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ev.eventType == 'In person' ? ev.location : 'Online Event',
                              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary) ??
                                  TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ev.timeString,
                              style: theme.textTheme.labelSmall?.copyWith(
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
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
