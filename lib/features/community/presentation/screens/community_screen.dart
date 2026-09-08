import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_header_widget.dart';
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
  const CommunityScreen({
    super.key,
    this.isHomeScreen = false,
    this.onNavigateTab,
  });

  /// Kept for source compatibility with older callers. The primary shell
  /// now presents Community directly, so the header always uses Community.
  @Deprecated('Community is always the primary shell experience.')
  final bool isHomeScreen;
  final ValueChanged<int>? onNavigateTab;

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
            isHomeScreen: isHomeScreen,
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
        _buildSuggestedEventsFeedPreview(
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
      items.add(const SizedBox(height: 16));
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

    // Render social posts with compact event and discussion discovery previews
    for (int i = 0; i < posts.length; i++) {
      if (i > 0) {
        items.add(const SizedBox(height: 12));
      }
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: PostCardWidget(
            post: posts[i],
            controller: controller,
          ),
        ),
      );

      // Insert Suggested Events preview after 1st post
      if (i == 0) {
        items.add(const SizedBox(height: 16));
        items.add(
          _buildSuggestedEventsFeedPreview(
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
      }

      // Insert Trending Discussions preview after 2nd post
      if (i == 1) {
        items.add(const SizedBox(height: 16));
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
        items.add(const SizedBox(height: 4));
      }
    }

    // If there is only 1 post, also show Trending Discussions preview
    if (posts.length == 1) {
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
    }

    // Loading More Indicator
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
        await controller.fetchDiscussions(isRefresh: true);
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

          // 1. Loading State
          if (controller.isLoadingForumDiscussions.value && latest.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.communityAccent,
                  strokeWidth: 2.5,
                ),
              ),
            );
          }

          // 2. Error State with Retry
          if (controller.hasForumError.value && latest.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 48,
                horizontal: AppSpacing.lg,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'community.couldNotLoadDiscussions'.tr.isNotEmpty &&
                              'community.couldNotLoadDiscussions'.tr !=
                                  'community.couldNotLoadDiscussions'
                          ? 'community.couldNotLoadDiscussions'.tr
                          : 'Couldn\'t load discussions.',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => controller.fetchDiscussions(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.communityAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        'common.retry'.tr.isNotEmpty &&
                                'common.retry'.tr != 'common.retry'
                            ? 'common.retry'.tr
                            : 'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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
      backgroundColor: surfaceSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Obx(() {
          // Loading state (initial load when events are empty)
          if (controller.isLoadingFeed.value && controller.events.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'community.upcomingEvents'.tr.isNotEmpty &&
                            'community.upcomingEvents'.tr != 'community.upcomingEvents'
                        ? 'community.upcomingEvents'.tr
                        : 'Upcoming Events',
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEventListSkeleton(isDark, surfaceSecondary, borderSubtle),
              ],
            );
          }

          // Error state
          if (controller.hasError.value && controller.events.isEmpty) {
            return _buildEventErrorState(
              context,
              controller,
              isDark,
              textPrimary,
              textSecondary,
              textMuted,
              surfaceSecondary,
              borderSubtle,
            );
          }

          final allEvents = controller.events;

          // Empty state
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Upcoming Events Header (Simple, Left-aligned, No filter button) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'community.upcomingEvents'.tr.isNotEmpty &&
                          'community.upcomingEvents'.tr != 'community.upcomingEvents'
                      ? 'community.upcomingEvents'.tr
                      : 'Upcoming Events',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Modern Compact Event Cards List ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allEvents.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final ev = allEvents[idx];
                    return _buildUpcomingEventCard(
                      context,
                      controller,
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

  Widget _buildEventListSkeleton(
    bool isDark,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final shimmerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
              border: Border.all(color: borderSubtle, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
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

  Widget _buildEventErrorState(
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
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'community.unableToLoadEvents'.tr.isNotEmpty &&
                      'community.unableToLoadEvents'.tr != 'community.unableToLoadEvents'
                  ? 'community.unableToLoadEvents'.tr
                  : 'Unable to load events',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => controller.fetchPosts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black87,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: Text(
                'community.tryAgain'.tr.isNotEmpty &&
                        'community.tryAgain'.tr != 'community.tryAgain'
                    ? 'community.tryAgain'.tr
                    : ('common.retry'.tr.isNotEmpty && 'common.retry'.tr != 'common.retry'
                        ? 'common.retry'.tr
                        : 'Try Again'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard(
    BuildContext context,
    CommunityController controller,
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
    final String onlineLabel = 'community.onlineEvent'.tr.isNotEmpty &&
            'community.onlineEvent'.tr != 'community.onlineEvent'
        ? 'community.onlineEvent'.tr
        : 'Online Event';
    final String inPersonLabel = 'community.inPerson'.tr.isNotEmpty &&
            'community.inPerson'.tr != 'community.inPerson'
        ? 'community.inPerson'.tr
        : 'In Person';
    final String locationDisplay = isOnline
        ? '🌐 $onlineLabel'
        : '📍 ${ev.location.isNotEmpty ? ev.location : inPersonLabel}';

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
      duration: Duration(milliseconds: 240 + (index.clamp(0, 5) * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(
            () => EventDetailsScreen(
              event: ev,
              heroTag: 'event-image-${ev.id}-tab',
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
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Hero(
                      tag: 'event-image-${ev.id}-tab',
                      child: _buildEventImage(ev, isDark, textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Right: Information Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Category Badge + Paid Badge + Bookmark Button
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
                              border: Border.all(
                                color: borderSubtle.withValues(alpha: 0.6),
                                width: 0.6,
                              ),
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
                                'community.paid'.tr.isNotEmpty &&
                                        'community.paid'.tr != 'community.paid'
                                    ? 'community.paid'.tr.toUpperCase()
                                    : 'PAID',
                                style: const TextStyle(
                                  color: AppColors.communityAccent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                controller.toggleEventBookmark(ev.id);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: AnimatedScale(
                                  scale: ev.isBookmarked ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    ev.isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: ev.isBookmarked
                                        ? AppColors.communityAccent
                                        : textMuted,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Title (Max 2 lines, handles English & Khmer)
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

                      // Date & Time (Max 1 line)
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

                      // Location / Online Event (Max 1 line)
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          );
        },
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

  static (String, String) _extractLocalizedDayAndMonth(String dateString) {
    if (dateString.trim().isEmpty) {
      return ('--', 'EVENT');
    }

    final isKhmer = Get.locale?.languageCode == 'km';
    final kmMonths = 'date.months'.tr.split(',');
    const enMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String getLocalizedMonth(int monthNum, String fallbackEn) {
      if (isKhmer && kmMonths.length == 12 && monthNum >= 1 && monthNum <= 12) {
        return kmMonths[monthNum - 1].trim();
      }
      return fallbackEn;
    }

    int? monthIndexFromName(String monthStr) {
      const enMonthKeys = [
        'jan', 'feb', 'mar', 'apr', 'may', 'jun',
        'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
      ];
      final lower = monthStr.toLowerCase().trim();
      for (int i = 0; i < enMonthKeys.length; i++) {
        if (lower.startsWith(enMonthKeys[i])) {
          return i + 1;
        }
      }
      return null;
    }

    // Check if the dateString already contains Khmer month names
    if (kmMonths.length == 12) {
      for (int i = 0; i < kmMonths.length; i++) {
        final kmName = kmMonths[i].trim();
        if (kmName.isNotEmpty && dateString.contains(kmName)) {
          final matchDay = RegExp(r'(\d{1,2})').firstMatch(dateString);
          final d = matchDay?.group(1) ?? '--';
          final localizedMonth = isKhmer ? kmName : enMonths[i];
          return (d, localizedMonth);
        }
      }
    }

    // 1. Try ISO / DateTime parse (e.g. 2026-07-25)
    final parsed = DateTime.tryParse(dateString.trim());
    if (parsed != null) {
      final mIndex = parsed.month;
      final fallbackEn = (mIndex >= 1 && mIndex <= 12) ? enMonths[mIndex - 1] : 'Event';
      final localizedMonth = getLocalizedMonth(mIndex, fallbackEn);
      return (parsed.day.toString(), localizedMonth);
    }

    // 2. Try match e.g. "25 Jul 2026" or "25 Jul"
    final match1 = RegExp(r'(\d{1,2})\s+([A-Za-z]+)').firstMatch(dateString);
    if (match1 != null) {
      final d = match1.group(1) ?? '';
      final mRaw = match1.group(2) ?? '';
      final mIndex = monthIndexFromName(mRaw);
      final fallbackEn = mRaw.length > 3 ? mRaw.substring(0, 3) : mRaw;
      final localizedMonth = mIndex != null ? getLocalizedMonth(mIndex, fallbackEn) : fallbackEn;
      return (d, localizedMonth);
    }

    // 3. Try match e.g. "Jul 25, 2026"
    final match2 = RegExp(r'([A-Za-z]+)\s+(\d{1,2})').firstMatch(dateString);
    if (match2 != null) {
      final mRaw = match2.group(1) ?? '';
      final d = match2.group(2) ?? '';
      final mIndex = monthIndexFromName(mRaw);
      final fallbackEn = mRaw.length > 3 ? mRaw.substring(0, 3) : mRaw;
      final localizedMonth = mIndex != null ? getLocalizedMonth(mIndex, fallbackEn) : fallbackEn;
      return (d, localizedMonth);
    }

    // 4. Try split tokens
    final parts = dateString.trim().split(RegExp(r'[\s,/-]+'));
    if (parts.isNotEmpty) {
      if (int.tryParse(parts[0]) != null) {
        final d = parts[0];
        if (parts.length > 1) {
          final mRaw = parts[1];
          final mIndex = monthIndexFromName(mRaw);
          final fallbackEn = mRaw.length > 3 ? mRaw.substring(0, 3) : mRaw;
          final localizedMonth = mIndex != null ? getLocalizedMonth(mIndex, fallbackEn) : fallbackEn;
          return (d, localizedMonth);
        }
        return (d, 'EVENT');
      }
    }

    return (dateString.length > 2 ? dateString.substring(0, 2) : dateString, 'EVENT');
  }

  Widget _buildDateBlock(EventModel ev, bool isDark, Color textPrimary, Color textSecondary) {
    final (day, month) = _extractLocalizedDayAndMonth(ev.dateString);
    final isKhmer = Get.locale?.languageCode == 'km';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isKhmer ? month : month.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: isKhmer ? 0.0 : 0.5,
                  height: 1.1,
                ),
              ),
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
    final joinLabel = 'community.join'.tr.isNotEmpty &&
            'community.join'.tr != 'community.join'
        ? 'community.join'.tr
        : 'Join';
    final joinedLabel = 'community.joined'.tr.isNotEmpty &&
            'community.joined'.tr != 'community.joined'
        ? 'community.joined'.tr
        : 'Joined';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(
            () => EventDetailsScreen(
              event: ev,
              heroTag: 'suggested-event-join-${ev.id}',
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isJoined ? 10 : 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isJoined
                ? (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary)
                : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isJoined
                ? Border.all(
                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isJoined) ...[
                Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                isJoined ? joinedLabel : joinLabel,
                style: TextStyle(
                  color: isJoined
                      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                      : (isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedEventsFeedPreview(
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
          // ── Section Header: ✨ Suggested Events | See all ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✨',
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'community.suggestedEvents'.tr.isNotEmpty &&
                                  'community.suggestedEvents'.tr !=
                                      'community.suggestedEvents'
                              ? 'community.suggestedEvents'.tr
                              : 'Suggested Events',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ) ??
                              TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.setCategory('Event'),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        'community.seeAll'.tr.isNotEmpty &&
                                'community.seeAll'.tr != 'community.seeAll'
                            ? 'community.seeAll'.tr
                            : 'See all',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Compact Suggested Event Cards ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: previewEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final ev = entry.value;
                final isOnline =
                    ev.eventType.toLowerCase().contains('online');
                final onlineLabel = 'community.onlineEvent'.tr.isNotEmpty &&
                        'community.onlineEvent'.tr != 'community.onlineEvent'
                    ? 'community.onlineEvent'.tr
                    : 'Online Event';
                final inPersonLabel = 'community.inPerson'.tr.isNotEmpty &&
                        'community.inPerson'.tr != 'community.inPerson'
                    ? 'community.inPerson'.tr
                    : 'In Person';
                final locationDisplay =
                    isOnline ? '🌐 $onlineLabel' : '📍 ${ev.location.isNotEmpty ? ev.location : inPersonLabel}';

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 180 + (index * 40)),
                  curve: Curves.easeOutQuad,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 4 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: index == previewEvents.length - 1 ? 0 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceSecondary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.squircle),
                      border: Border.all(color: borderSubtle, width: 0.8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.squircle),
                      child: InkWell(
                        onTap: () =>
                            Get.to(() => EventDetailsScreen(event: ev, heroTag: 'suggested-event-card-${ev.id}')),
                        borderRadius:
                            BorderRadius.circular(AppRadius.squircle),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              // 1. Date Block
                              _buildDateBlock(ev, isDark, textPrimary, textSecondary),
                              const SizedBox(width: 12),

                              // 2. Event Title & Location
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ev.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      locationDisplay,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 3. Join Button
                              _buildFeedJoinButton(
                                ev,
                                controller,
                                isDark,
                              ),
                            ],
                          ),
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
              'community.noUpcomingEvents'.tr.isNotEmpty &&
                      'community.noUpcomingEvents'.tr != 'community.noUpcomingEvents'
                  ? 'community.noUpcomingEvents'.tr
                  : 'No upcoming events',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'community.newEventsAppearHere'.tr.isNotEmpty &&
                      'community.newEventsAppearHere'.tr != 'community.newEventsAppearHere'
                  ? 'community.newEventsAppearHere'.tr
                  : 'New events will appear here.',
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
