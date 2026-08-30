import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_creation_flow.dart';
import '../widgets/community_header_widget.dart';
import '../widgets/filter_events_sheet.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/story_tray_widget.dart';
import 'create_discussion_screen.dart';
import 'event_details_screen.dart';
import 'forum_category_screen.dart';
import 'forum_discussion_screen.dart';
import 'widgets/community_widgets.dart';

/// GenLink KH Community Screen
///
/// Features 3 sticky navigation tabs: Feed, Forum, Event.
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
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              const SizedBox(height: 6),

              // STICKY NAVIGATION TABS (Feed, Forum, Event)
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
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
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkTextInverse
                                        : AppColors.lightTextInverse)
                                    : textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // DYNAMIC TAB CONTENT BODY
              Expanded(
                child: Obx(() {
                  final activeCategory = commController.selectedCategory.value;
                  Widget content;
                  switch (activeCategory) {
                    case 'Forum':
                      content = KeyedSubtree(
                        key: const ValueKey('ForumTab'),
                        child: _buildForumTab(context, commController),
                      );
                      break;
                    case 'Event':
                      content = KeyedSubtree(
                        key: const ValueKey('EventTab'),
                        child: _buildEventTab(context, commController),
                      );
                      break;
                    case 'Feed':
                    default:
                      content = KeyedSubtree(
                        key: const ValueKey('FeedTab'),
                        child: _buildFeedTab(context, commController),
                      );
                      break;
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: content,
                  );
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
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final isNarrow = mediaQuery.size.width < 360;
    final isVeryNarrow = mediaQuery.size.width < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding = navBarHeight + navBarBottomMargin + visualBreathingRoom;

    return RefreshIndicator(
      onRefresh: () => controller.refreshFeed(),
      color: AppColors.communityAccent,
      backgroundColor: surfaceSecondary,
      child: SingleChildScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Stories Row (Horizontal swipeable row, no arrow, compact spacing)
            const StoryTrayWidget(),

            const SizedBox(height: 10),

            // 2. Post Composer ("What's on your mind?" with Photo, Video, Feeling, Location)
            _buildFeedPostComposer(
              context,
              controller,
              isDark,
              textPrimary,
              textSecondary,
              textMuted,
              surfaceSecondary,
              borderSubtle,
            ),

            const SizedBox(height: 12),

            // 3. Mixed Social Feed with Discovery Previews
            Obx(() {
              if (controller.isLoadingFeed.value && controller.posts.isEmpty) {
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
                          backgroundColor: isDark ? Colors.white : Colors.black87,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildMixedFeedContent(
                context,
                controller,
                isDark,
                textPrimary,
                textSecondary,
                textMuted,
                surfaceSecondary,
                borderSubtle,
              );
            }),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // POST COMPOSER WIDGET
  Widget _buildFeedPostComposer(
    BuildContext context,
    CommunityController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: borderSubtle, width: 0.8),
        ),
        child: Column(
          children: [
            // Top Row: Avatar + "What's on your mind?"
            InkWell(
              onTap: () => CommunityCreationFlow.openCreatePost(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.squircle),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/images/user_profile.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: borderSubtle,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'community.whatsOnYourMind'.tr.isNotEmpty &&
                                  'community.whatsOnYourMind'.tr !=
                                      'community.whatsOnYourMind'
                              ? 'community.whatsOnYourMind'.tr
                              : "What's on your mind?",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: borderSubtle, thickness: 0.8),

            // Bottom Row: Photo | Video | Feeling | Location
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildComposerQuickButton(
                    context: context,
                    icon: Icons.photo_library_outlined,
                    label: 'Photo',
                    color: const Color(0xFF4E95FF),
                    onTap: () => CommunityCreationFlow.openCreatePost(context),
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  _buildComposerQuickButton(
                    context: context,
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    color: const Color(0xFF43C97E),
                    onTap: () => CommunityCreationFlow.openCreatePost(context),
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  _buildComposerQuickButton(
                    context: context,
                    icon: Icons.sentiment_satisfied_alt_outlined,
                    label: 'Feeling',
                    color: const Color(0xFFF5A623),
                    onTap: () => CommunityCreationFlow.openCreatePost(context),
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  _buildComposerQuickButton(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    color: const Color(0xFFE05252),
                    onTap: () => CommunityCreationFlow.openCreatePost(context),
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerQuickButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MIXED FEED CONTENT BUILDER
  Widget _buildMixedFeedContent(
    BuildContext context,
    CommunityController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final posts = controller.posts;
    final List<Widget> items = [];

    if (posts.isEmpty) {
      items.add(
        _buildUpcomingEventsFeedPreview(
          context,
          controller,
          isDark,
          textPrimary,
          textSecondary,
          textMuted,
          surfaceSecondary,
          borderSubtle,
        ),
      );
      items.add(const SizedBox(height: 12));
      items.add(
        _buildTrendingDiscussionsFeedPreview(
          context,
          controller,
          isDark,
          textPrimary,
          textSecondary,
          textMuted,
          surfaceSecondary,
          borderSubtle,
        ),
      );
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.md),
          child: Center(
            child: Text(
              'community.noPostsYet'.tr,
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }

    // 1. First Social Post
    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: PostCardWidget(
          post: posts[0],
          controller: controller,
        ),
      ),
    );

    // 2. Upcoming Events Preview Section (1-2 compact cards)
    items.add(const SizedBox(height: 12));
    items.add(
      _buildUpcomingEventsFeedPreview(
        context,
        controller,
        isDark,
        textPrimary,
        textSecondary,
        textMuted,
        surfaceSecondary,
        borderSubtle,
      ),
    );

    // 3. Second Social Post (if available)
    if (posts.length > 1) {
      items.add(const SizedBox(height: 12));
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: PostCardWidget(
            post: posts[1],
            controller: controller,
          ),
        ),
      );
    }

    // 4. Trending Discussions Preview Section (1-2 compact cards)
    items.add(const SizedBox(height: 12));
    items.add(
      _buildTrendingDiscussionsFeedPreview(
        context,
        controller,
        isDark,
        textPrimary,
        textSecondary,
        textMuted,
        surfaceSecondary,
        borderSubtle,
      ),
    );

    // 5. Remaining Social Posts (post 2 onwards)
    if (posts.length > 2) {
      for (int i = 2; i < posts.length; i++) {
        items.add(const SizedBox(height: 12));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: PostCardWidget(
              post: posts[i],
              controller: controller,
            ),
          ),
        );
      }
    }

    // 6. Loading More Indicator
    if (controller.isLoadingMore.value) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.communityAccent,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  // FORUM TAB
  Widget _buildForumTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final isNarrow = mediaQuery.size.width < 360;
    final isVeryNarrow = mediaQuery.size.width < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding = navBarHeight + navBarBottomMargin + visualBreathingRoom;

    return RefreshIndicator(
      onRefresh: () async {
        controller.forumLatestDiscussions.refresh();
      },
      color: AppColors.communityAccent,
      backgroundColor: surfaceSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          bottomPadding,
        ),
        child: Obx(() {
          final latest = controller.forumLatestDiscussions;

          if (latest.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 48,
                horizontal: AppSpacing.lg,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 48,
                      color: textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'community.noDiscussionsYet'.tr.isNotEmpty &&
                              'community.noDiscussionsYet'.tr !=
                                  'community.noDiscussionsYet'
                          ? 'community.noDiscussionsYet'.tr
                          : 'No discussions yet',
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
                    const SizedBox(height: 6),
                    Text(
                      'community.startConversation'.tr.isNotEmpty &&
                              'community.startConversation'.tr !=
                                  'community.startConversation'
                          ? 'community.startConversation'.tr
                          : 'Start a conversation with the GenLink community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Get.to(() => const CreateDiscussionScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black87,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        'community.createDiscussion'.tr.isNotEmpty &&
                                'community.createDiscussion'.tr !=
                                    'community.createDiscussion'
                            ? 'community.createDiscussion'.tr
                            : 'Create Discussion',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest Discussions Section (Pinned Discussions completely removed)
              Text(
                'community.latestDiscussions'.tr.isNotEmpty &&
                        'community.latestDiscussions'.tr !=
                            'community.latestDiscussions'
                    ? 'community.latestDiscussions'.tr
                    : 'Latest Discussions',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ) ??
                    TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              ...latest.map((topic) => ForumThreadCard(
                    title: topic.title,
                    author: topic.authorName,
                    avatarUrl: topic.authorAvatar,
                    timeAgo: topic.timeAgo,
                    category: topic.category,
                    replies: topic.repliesCount,
                    likes: topic.upvotes,
                    isPinned: false,
                    isLiked: topic.isLiked,
                    onTap: () => Get.to(
                      () => ForumDiscussionScreen(discussion: topic),
                    ),
                    onLikeTap: () =>
                        controller.toggleDiscussionLike(topic.id),
                    onCommentTap: () => Get.to(
                      () => ForumDiscussionScreen(discussion: topic),
                    ),
                    onCategoryTap: () => Get.to(
                      () => ForumCategoryScreen(
                        categoryTitle: topic.category,
                      ),
                    ),
                    onMoreTap: () =>
                        _showDiscussionMoreMenu(context, controller, topic),
                  )),
            ],
          );
        }),
      ),
    );
  }

  void _showDiscussionMoreMenu(
    BuildContext context,
    CommunityController controller,
    ForumTopicModel topic,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2228) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final isOwner = topic.checkIsOwner(controller.currentUserId);

    Get.bottomSheet(
      Material(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderSubtle, width: 1),
          ),
          child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isOwner) ...[
                // Owner Option: Edit Discussion
                ListTile(
                  leading:
                      Icon(Icons.edit_outlined, color: textPrimary, size: 22),
                  title: Text(
                    'community.editDiscussion'.tr.isNotEmpty &&
                            'community.editDiscussion'.tr !=
                                'community.editDiscussion'
                        ? 'community.editDiscussion'.tr
                        : 'Edit Discussion',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => CreateDiscussionScreen(
                          initialDiscussion: topic,
                        ));
                  },
                ),
                // Owner Option: Delete Discussion
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  title: Text(
                    'community.deleteDiscussion'.tr.isNotEmpty &&
                            'community.deleteDiscussion'.tr !=
                                'community.deleteDiscussion'
                        ? 'community.deleteDiscussion'.tr
                        : 'Delete Discussion',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _showDeleteDiscussionDialog(context, controller, topic);
                  },
                ),
              ] else ...[
                // Non-Owner Option: Save
                ListTile(
                  leading: Icon(
                    Icons.bookmark_border_rounded,
                    color: textPrimary,
                    size: 22,
                  ),
                  title: Text(
                    'community.save'.tr.isNotEmpty &&
                            'community.save'.tr != 'community.save'
                        ? 'community.save'.tr
                        : 'Save',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: 'Saved',
                      message: 'Discussion saved to bookmarks.',
                    );
                  },
                ),
                // Non-Owner Option: Report
                ListTile(
                  leading: const Icon(
                    Icons.report_outlined,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  title: Text(
                    'community.report'.tr.isNotEmpty &&
                            'community.report'.tr != 'community.report'
                        ? 'community.report'.tr
                        : 'Report',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: 'Reported',
                      message:
                          'Thank you for reporting. Our team will review it.',
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              // Cancel
              ListTile(
                leading:
                    Icon(Icons.close_rounded, color: textSecondary, size: 22),
                title: Text(
                  'common.cancel'.tr.isNotEmpty &&
                          'common.cancel'.tr != 'common.cancel'
                      ? 'common.cancel'.tr
                      : 'Cancel',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
  }

  void _showDeleteDiscussionDialog(
    BuildContext context,
    CommunityController controller,
    ForumTopicModel topic,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2228) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white70 : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'community.deleteDiscussion'.tr.isNotEmpty &&
                  'community.deleteDiscussion'.tr != 'community.deleteDiscussion'
              ? '${'community.deleteDiscussion'.tr}?'
              : 'Delete Discussion?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'community.deleteDiscussionConfirm'.tr.isNotEmpty &&
                  'community.deleteDiscussionConfirm'.tr !=
                      'community.deleteDiscussionConfirm'
              ? 'community.deleteDiscussionConfirm'.tr
              : 'Are you sure you want to delete this discussion? This action cannot be undone.',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr.isNotEmpty &&
                      'common.cancel'.tr != 'common.cancel'
                  ? 'common.cancel'.tr
                  : 'Cancel',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await controller.deleteDiscussion(topic.id);
              if (success && context.mounted) {
                AppNotificationBanner.showSuccess(
                  context: context,
                  title: 'community.discussionDeleted'.tr.isNotEmpty &&
                          'community.discussionDeleted'.tr !=
                              'community.discussionDeleted'
                      ? 'community.discussionDeleted'.tr
                      : 'Discussion Deleted',
                  message: 'community.discussionDeletedMsg'.tr.isNotEmpty &&
                          'community.discussionDeletedMsg'.tr !=
                              'community.discussionDeletedMsg'
                      ? 'community.discussionDeletedMsg'.tr
                      : 'Your discussion has been removed.',
                );
              }
            },
            child: Text(
              'common.delete'.tr.isNotEmpty &&
                      'common.delete'.tr != 'common.delete'
                  ? 'common.delete'.tr
                  : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final isNarrow = mediaQuery.size.width < 360;
    final isVeryNarrow = mediaQuery.size.width < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding = navBarHeight + navBarBottomMargin + visualBreathingRoom + 28.0;

    return RefreshIndicator(
      onRefresh: () => controller.fetchPosts(),
      color: AppColors.communityAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Obx(() {
          final allEvents = controller.events;
          final isFiltered = controller.isEventFilterActive;

          if (allEvents.isEmpty) {
            return _buildEventEmptyState(
              context,
              isDark,
              textPrimary,
              textSecondary,
              textMuted,
              surfaceSecondary,
              borderSubtle,
            );
          }

          // Featured events: up to 3 highlighted events
          final featuredList = allEvents.take(3).toList();
          final featuredIds = featuredList.map((e) => e.id).toSet();

          // Deduplication: if no filter is applied, upcoming list displays events
          // excluding featured ones (or fallbacks safely if only 1 event exists)
          List<EventModel> upcomingList;
          if (isFiltered) {
            upcomingList = controller.filteredEvents;
          } else {
            final nonFeatured = allEvents.where((e) => !featuredIds.contains(e.id)).toList();
            upcomingList = nonFeatured.isNotEmpty
                ? nonFeatured
                : (allEvents.length > 1 ? allEvents.sublist(1) : allEvents);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ── Featured Events Carousel with smooth auto-play & page indicator ──
              FeaturedEventsCarousel(
                events: featuredList,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                surfaceSecondary: surfaceSecondary,
                borderSubtle: borderSubtle,
              ),

              const SizedBox(height: 22),

              // ── Upcoming Events Header with Filter Button ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'community.upcomingEvents'.tr.isNotEmpty &&
                                'community.upcomingEvents'.tr != 'community.upcomingEvents'
                            ? 'community.upcomingEvents'.tr
                            : 'Upcoming Events',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ) ??
                            TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Get.bottomSheet(
                          const FilterEventsSheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isEventFilterActive
                              ? (isDark
                                  ? AppColors.communityAccent.withValues(alpha: 0.15)
                                  : AppColors.communityAccent.withValues(alpha: 0.12))
                              : surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: controller.isEventFilterActive
                                ? AppColors.communityAccent
                                : borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: controller.isEventFilterActive
                                  ? AppColors.communityAccent
                                  : textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'community.filter'.tr.isNotEmpty &&
                                      'community.filter'.tr != 'community.filter'
                                  ? 'community.filter'.tr
                                  : 'Filter',
                              style: TextStyle(
                                color: controller.isEventFilterActive
                                    ? AppColors.communityAccent
                                    : textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Upcoming Events List / Filtered State ──────────────────────
              if (upcomingList.isEmpty)
                _buildFilterEmptyState(
                  context,
                  controller,
                  isDark,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  surfaceSecondary,
                  borderSubtle,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final ev = upcomingList[idx];
                      return _buildUpcomingEventCard(
                        context,
                        ev,
                        idx,
                        isDark,
                        textPrimary,
                        textSecondary,
                        textMuted,
                        surfaceSecondary,
                        borderSubtle,
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFilterEmptyState(
    BuildContext context,
    CommunityController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: borderSubtle),
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 28,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'community.noMatchingEvents'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => controller.resetEventFilter(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'community.resetFilters'.tr,
                style: const TextStyle(
                  color: AppColors.communityAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard(
    BuildContext context,
    EventModel ev,
    int index,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final isOnline = ev.eventType.toLowerCase().contains('online');
    final String locationDisplay = isOnline
        ? '🌐 Online Event'
        : '📍 ${ev.location.isNotEmpty ? ev.location : "In Person"}';

    final String dateDisplay = ev.timeString.isNotEmpty
        ? '📅 ${ev.dateString} · ${ev.timeString}'
        : (ev.dateString.isNotEmpty ? '📅 ${ev.dateString}' : '');

    final String rawCat = ev.category.isNotEmpty ? ev.category : 'Event';
    final String catKey = 'community.${rawCat.toLowerCase()}';
    final String categoryDisplay = catKey.tr.isNotEmpty && catKey.tr != catKey
        ? catKey.tr
        : rawCat;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + (index.clamp(0, 6) * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => Get.to(
          () => EventDetailsScreen(
            event: ev,
            heroTag: 'event-image-${ev.id}-upcoming',
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.squircle),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 92x92 Square Thumbnail with Hero
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Hero(
                    tag: 'event-image-${ev.id}-upcoming',
                    child: _buildEventImage(ev, isDark, textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right: Information Lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryDisplay,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (ev.isPaid) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.communityAccent
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'community.paid'.tr.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.communityAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.toggleEventBookmark(ev.id);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              ev.isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: ev.isBookmarked
                                  ? AppColors.communityAccent
                                  : textMuted,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      ev.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Date & Time
                    if (dateDisplay.isNotEmpty) ...[
                      Text(
                        dateDisplay,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Location / Online
                    Text(
                      locationDisplay,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildEventImage(EventModel ev, bool isDark, Color textMuted) {
    if (ev.coverImageFile != null) {
      return Image.file(
        ev.coverImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _eventPlaceholder(isDark, textMuted),
      );
    }
    if (ev.imageUrl.isNotEmpty) {
      return Image.network(
        ev.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _eventPlaceholder(isDark, textMuted),
      );
    }
    return _eventPlaceholder(isDark, textMuted);
  }

  static Widget _eventPlaceholder(bool isDark, Color textMuted) {
    return Container(
      color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: textMuted.withValues(alpha: 0.6),
          size: 28,
        ),
      ),
    );
  }

  static (String, String) _extractDayAndMonth(String dateString) {
    if (dateString.trim().isEmpty) {
      return ('--', 'EVENT');
    }

    final parsed = DateTime.tryParse(dateString.trim());
    if (parsed != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final mName = (parsed.month >= 1 && parsed.month <= 12)
          ? months[parsed.month - 1]
          : 'Event';
      return (parsed.day.toString(), mName);
    }

    final match1 = RegExp(r'(\d{1,2})\s+([A-Za-z]+)').firstMatch(dateString);
    if (match1 != null) {
      final d = match1.group(1) ?? '';
      final m = match1.group(2) ?? '';
      final mFormatted = m.length > 3 ? m.substring(0, 3) : m;
      return (d, mFormatted);
    }

    final match2 = RegExp(r'([A-Za-z]+)\s+(\d{1,2})').firstMatch(dateString);
    if (match2 != null) {
      final m = match2.group(1) ?? '';
      final d = match2.group(2) ?? '';
      final mFormatted = m.length > 3 ? m.substring(0, 3) : m;
      return (d, mFormatted);
    }

    final parts = dateString.trim().split(RegExp(r'[\s,/-]+'));
    if (parts.isNotEmpty) {
      if (int.tryParse(parts[0]) != null) {
        final d = parts[0];
        final m = parts.length > 1
            ? (parts[1].length > 3 ? parts[1].substring(0, 3) : parts[1])
            : 'Event';
        return (d, m);
      }
    }

    return (dateString.length > 2 ? dateString.substring(0, 2) : dateString, 'EVENT');
  }

  Widget _buildUpcomingEventsFeedPreview(
    BuildContext context,
    CommunityController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      final previewEvents = controller.events.take(2).toList();
      if (previewEvents.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header: Upcoming Events | See all ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'community.upcomingEvents'.tr.isNotEmpty &&
                            'community.upcomingEvents'.tr != 'community.upcomingEvents'
                        ? 'community.upcomingEvents'.tr
                        : 'Upcoming Events',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => controller.setCategory('Event'),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'home.seeAll'.tr.isNotEmpty && 'home.seeAll'.tr != 'home.seeAll'
                          ? 'home.seeAll'.tr
                          : 'See all',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Compact Horizontal Event Cards ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: previewEvents.map((ev) {
                final isOnline = ev.eventType.toLowerCase().contains('online');
                final String locationDisplay = isOnline
                    ? '🌐 Online Event'
                    : '📍 ${ev.location.isNotEmpty ? ev.location : "Phnom Penh"}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    border: Border.all(color: borderSubtle, width: 0.8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    child: InkWell(
                      onTap: () => Get.to(
                        () => EventDetailsScreen(
                          event: ev,
                          heroTag: 'event-image-${ev.id}-feed',
                        ),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.squircle),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Prominent Date Block
                            _buildDateBlock(ev, isDark, textPrimary, textSecondary),
                            const SizedBox(width: 12),

                            // Right: Title, Location, and Join Button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ev.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          locationDisplay,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFeedJoinButton(ev, controller, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTrendingDiscussionsFeedPreview(
    BuildContext context,
    CommunityController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final theme = Theme.of(context);

    return Obx(() {
      final previewDiscussions =
          controller.forumLatestDiscussions.take(2).toList();
      if (previewDiscussions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header: Trending Discussions | See all ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'community.trendingDiscussions'.tr.isNotEmpty &&
                            'community.trendingDiscussions'.tr !=
                                'community.trendingDiscussions'
                        ? 'community.trendingDiscussions'.tr
                        : 'Trending Discussions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => controller.setCategory('Forum'),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'home.seeAll'.tr.isNotEmpty &&
                              'home.seeAll'.tr != 'home.seeAll'
                          ? 'home.seeAll'.tr
                          : 'See all',
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Compact Discussion Cards ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: previewDiscussions.map((topic) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    border: Border.all(color: borderSubtle, width: 0.8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.squircle),
                    child: InkWell(
                      onTap: () => Get.to(
                        () => ForumDiscussionScreen(discussion: topic),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.squircle),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${topic.repliesCount} replies · ${topic.upvotes} likes · ${topic.category}',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDateBlock(
    EventModel ev,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final (day, month) = _extractDayAndMonth(ev.dateString);
    final blockBg = isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF1);
    final blockBorder = isDark ? const Color(0xFF2E3540) : const Color(0xFFD6DBE2);

    return Container(
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: blockBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blockBorder, width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month.toUpperCase(),
            style: const TextStyle(
              color: AppColors.communityAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedJoinButton(
    EventModel ev,
    CommunityController controller,
    bool isDark,
  ) {
    final isJoined = ev.isRsvped;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.toggleRsvp(ev.id),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isJoined ? 12 : 16,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isJoined
                ? (isDark
                    ? AppColors.communityAccent.withValues(alpha: 0.16)
                    : AppColors.communityAccent.withValues(alpha: 0.12))
                : (isDark ? Colors.white : Colors.black87),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isJoined
                ? Border.all(
                    color: AppColors.communityAccent.withValues(alpha: 0.6),
                    width: 1.0,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isJoined) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.communityAccent,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                isJoined ? 'Joined' : 'Join',
                style: TextStyle(
                  color: isJoined
                      ? AppColors.communityAccent
                      : (isDark ? Colors.black : Colors.white),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: borderSubtle),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 36,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Discover events happening around your campus and community.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Featured Events Carousel with auto-play, touch pause/resume, scale/opacity animation, and minimal indicator
class FeaturedEventsCarousel extends StatefulWidget {
  final List<EventModel> events;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color surfaceSecondary;
  final Color borderSubtle;

  const FeaturedEventsCarousel({
    super.key,
    required this.events,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.surfaceSecondary,
    required this.borderSubtle,
  });

  @override
  State<FeaturedEventsCarousel> createState() => _FeaturedEventsCarouselState();
}

class _FeaturedEventsCarouselState extends State<FeaturedEventsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.90,
      initialPage: 0,
    );
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.events.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 4500), (timer) {
      if (!mounted || _isUserInteracting) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.events.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _isUserInteracting = false;
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) => _onUserInteractionStart(),
          onPointerUp: (_) => _onUserInteractionEnd(),
          onPointerCancel: (_) => _onUserInteractionEnd(),
          child: SizedBox(
            height: 330,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.events.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final ev = widget.events[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    double opacity = 1.0;

                    if (_pageController.position.haveDimensions) {
                      final page = _pageController.page ??
                          _pageController.initialPage.toDouble();
                      final diff = (page - index).abs();
                      scale = (1.0 - (diff * 0.05)).clamp(0.95, 1.0);
                      opacity = (1.0 - (diff * 0.15)).clamp(0.85, 1.0);
                    } else {
                      scale = index == _currentPage ? 1.0 : 0.95;
                      opacity = index == _currentPage ? 1.0 : 0.88;
                    }

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    );
                  },
                  child: _buildFeaturedCard(ev),
                );
              },
            ),
          ),
        ),
        if (widget.events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.events.length,
              (dotIndex) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == dotIndex ? 22 : 5,
                height: 4.5,
                decoration: BoxDecoration(
                  color: _currentPage == dotIndex
                      ? (widget.isDark ? Colors.white : Colors.black)
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturedCard(EventModel ev) {
    final isOnline = ev.eventType.toLowerCase().contains('online');
    final String locationDisplay = isOnline
        ? ('community.onlineEvent'.tr.isNotEmpty &&
                'community.onlineEvent'.tr != 'community.onlineEvent'
            ? 'community.onlineEvent'.tr
            : '🌐 Online Event')
        : (ev.location.isNotEmpty ? '📍 ${ev.location}' : '📍 In Person');

    final String dateDisplay = ev.timeString.isNotEmpty
        ? '📅 ${ev.dateString} · ${ev.timeString}'
        : (ev.dateString.isNotEmpty ? '📅 ${ev.dateString}' : '');

    final String rawCat = ev.category.isNotEmpty ? ev.category : 'Event';
    final String catKey = 'community.${rawCat.toLowerCase()}';
    final String categoryBadge = catKey.tr.isNotEmpty && catKey.tr != catKey
        ? catKey.tr.toUpperCase()
        : rawCat.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: InkWell(
        onTap: () => Get.to(
          () => EventDetailsScreen(
            event: ev,
            heroTag: 'event-image-${ev.id}-featured',
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: widget.surfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : widget.borderSubtle,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDark ? 0.35 : 0.08,
                ),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-bleed Background Event Image
                Hero(
                  tag: 'event-image-${ev.id}-featured',
                  child: CommunityScreen._buildEventImage(
                    ev,
                    widget.isDark,
                    widget.textMuted,
                  ),
                ),

                // 2. Multi-stop Dark Gradient Overlay for Maximum Readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.32),
                        Colors.black.withValues(alpha: 0.48),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),

                // 3. Foreground Information Layer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category Badge & Bookmark Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              categoryBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Get.find<CommunityController>()
                                  .toggleEventBookmark(ev.id);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                ev.isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: ev.isBookmarked
                                    ? AppColors.communityAccent
                                    : Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        ev.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          height: 1.22,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Subtitle
                      if (ev.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          ev.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Grouped Metadata Panel (Clean Frosted Container)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (dateDisplay.isNotEmpty)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (dateDisplay.isNotEmpty)
                              const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    locationDisplay,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Bottom Row: Attendees & View Details Action
                      Row(
                        children: [
                          if (ev.attendeeAvatars.isNotEmpty) ...[
                            SizedBox(
                              width: 18.0 *
                                      (ev.attendeeAvatars.take(3).length - 1) +
                                  24,
                              height: 24,
                              child: Stack(
                                children: List.generate(
                                  ev.attendeeAvatars.take(3).length,
                                  (avatarIdx) => Positioned(
                                    left: avatarIdx * 16.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 10.5,
                                        backgroundImage: AssetImage(
                                          ev.attendeeAvatars[avatarIdx],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            const Icon(
                              Icons.people_outline_rounded,
                              color: Colors.white70,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${ev.attendeesCount} ${'community.joined'.tr.isNotEmpty && 'community.joined'.tr != 'community.joined' ? 'community.joined'.tr : 'joined'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'community.viewDetails'.tr.isNotEmpty &&
                                          'community.viewDetails'.tr !=
                                              'community.viewDetails'
                                      ? 'community.viewDetails'.tr
                                      : 'View details',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ],
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
        ),
      ),
    );
  }
}
