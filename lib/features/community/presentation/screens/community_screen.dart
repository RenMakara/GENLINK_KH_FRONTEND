import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/shadows/app_shadows.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_header_widget.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/quick_create_post_card.dart';
import '../widgets/story_tray_widget.dart';
import '../widgets/community_creation_flow.dart';

import 'create_discussion_screen.dart';
import 'events_screen.dart';
import 'forum_category_screen.dart';
import 'forum_discussion_screen.dart';
import '../widgets/forum_share_to_chat_sheet.dart';
import 'widgets/community_widgets.dart';
import '../../../home/presentation/widgets/home_featured_events_carousel.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    this.isHomeScreen = true,
    this.onNavigateTab,
  });

  final bool isHomeScreen;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
  with TickerProviderStateMixin {
  late final TabController _tabController;
  AnimationController? _headerVisibilityController;
  Animation<double>? _headerVisibilityAnimation;
  Animation<Offset>? _headerSlideAnimation;
  Worker? _categoryWorker;
  bool _isHeaderVisible = true;

  CommunityController get _effectiveController {
    return Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());
  }

  @override
  void initState() {
    super.initState();
    final commController = _effectiveController;
    final initialIndex = commController.categories.indexOf(
      commController.selectedCategory.value,
    );
    _tabController = TabController(
      length: commController.categories.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    _initializeHeaderAnimations();

    _tabController.addListener(_handleTabChange);

    _categoryWorker = ever(commController.selectedCategory, (String cat) {
      if (!mounted) return;
      final targetIndex = commController.categories.indexOf(cat);
      if (targetIndex >= 0 &&
          targetIndex != _tabController.index &&
          !_tabController.indexIsChanging) {
        _tabController.animateTo(targetIndex);
      }
    });
  }

  void _initializeHeaderAnimations() {
    if (_headerVisibilityController != null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    final visibilityAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    _headerVisibilityController = controller;
    _headerVisibilityAnimation = visibilityAnimation;
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(visibilityAnimation);
  }

  void _handleTabChange() {
    if (!mounted) return;
    final commController = _effectiveController;
    final targetIndex = _tabController.index;
    if (targetIndex >= 0 && targetIndex < commController.categories.length) {
      final newCat = commController.categories[targetIndex];
      if (commController.selectedCategory.value != newCat) {
        commController.selectedCategory.value = newCat;
      }
    }
  }

  void _onTabTapped(String cat, int index) {
    final commController = _effectiveController;
    if (commController.selectedCategory.value == cat) {
      if (cat == 'Feed' || cat == 'For You') {
        commController.onFeedTabTappedAgain();
      }
    } else {
      commController.setCategory(cat);
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
    }
  }

  bool _handleContentScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final isAtTop = notification.metrics.pixels <=
        notification.metrics.minScrollExtent + 1;
    final shouldShow = isAtTop ||
        notification.direction == ScrollDirection.forward;

    if (shouldShow != _isHeaderVisible) {
      _initializeHeaderAnimations();
      setState(() => _isHeaderVisible = shouldShow);
      if (shouldShow) {
        _headerVisibilityController!.forward();
      } else {
        _headerVisibilityController!.reverse();
      }
    }
    return false;
  }

  @override
  void dispose() {
    _categoryWorker?.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _headerVisibilityController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initializeHeaderAnimations();
    final headerVisibilityAnimation = _headerVisibilityAnimation!;
    final headerSlideAnimation = _headerSlideAnimation!;
    final commController = _effectiveController;

    final semantic = AppColors.of(context);
    final bg = semantic.background;
    final borderSubtle = semantic.borderSubtle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // Keep the complete Home header outside the TabBarView so it
              // animates as one lightweight top slot while content scrolls.
              ClipRect(
                child: SizeTransition(
                  sizeFactor: headerVisibilityAnimation,
                  alignment: Alignment.topCenter,
                  child: SlideTransition(
                    position: headerSlideAnimation,
                    child: FadeTransition(
                      opacity: headerVisibilityAnimation,
                      child: IgnorePointer(
                        ignoring: !_isHeaderVisible,
                        child: ExcludeSemantics(
                          excluding: !_isHeaderVisible,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                CommunityHeaderWidget(
                                  activeCategory:
                                      commController.selectedCategory.value,
                                  activeCategoryBuilder: () =>
                                      commController.selectedCategory.value,
                                  isHomeScreen: widget.isHomeScreen,
                                ),
                                Obx(() {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    child: Container(
                                      height: 41,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.04),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(
                                          color: borderSubtle.withValues(
                                            alpha: isDark ? 0.60 : 0.70,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: commController.categories.map((cat) {
                                          final isSelected =
                                              commController.selectedCategory.value ==
                                                  cat;
                                          final String tabText;
                                          if (cat == 'For You') {
                                            tabText = ('community.forYou'.tr.isNotEmpty &&
                                                    'community.forYou'.tr !=
                                                        'community.forYou')
                                                ? 'community.forYou'.tr
                                                : 'For You';
                                          } else {
                                            final key =
                                                'community.${cat.toLowerCase()}';
                                            tabText = (key.tr.isNotEmpty &&
                                                    key.tr != key)
                                                ? key.tr
                                                : cat;
                                          }

                                          final activeBg = isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary;
                                          final activeText = isDark
                                              ? Colors.black
                                              : Colors.white;
                                          final inactiveText = isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary;

                                          final tabColor =
                                              isSelected ? activeText : inactiveText;

                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 1.5,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _onTabTapped(
                                                    cat,
                                                    commController.categories
                                                        .indexOf(cat),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppRadius.pill,
                                                  ),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 180,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    alignment: Alignment.center,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? activeBg
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        AppRadius.pill,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors.black
                                                                    .withValues(
                                                                  alpha: isDark
                                                                      ? 0.25
                                                                      : 0.08,
                                                                ),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(0, 1),
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        tabText,
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: tabColor,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                          fontSize: 12.5,
                                                          letterSpacing: -0.1,
                                                          fontFamilyFallback: const [
                                                            'KantumruyPro',
                                                            'Sora',
                                                          ],
                                                          height: 1.15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: _handleContentScroll,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _KeepAliveWrapper(
                        child: KeyedSubtree(
                          key: const ValueKey('ForYouTab'),
                          child: _buildFeedTab(context, commController),
                        ),
                      ),
                      _KeepAliveWrapper(
                        child: KeyedSubtree(
                          key: const ValueKey('FeedTab'),
                          child: _buildFeedTab(context, commController),
                        ),
                      ),
                      _KeepAliveWrapper(
                        child: KeyedSubtree(
                          key: const ValueKey('ForumTab'),
                          child: _buildForumTab(context, commController),
                        ),
                      ),
                      _KeepAliveWrapper(
                        child: KeyedSubtree(
                          key: const ValueKey('EventTab'),
                          child: _buildEventTab(context, commController),
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
    );
  }

  Widget _buildFeedTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final isNarrow = mediaQuery.size.width < 360;
    final isVeryNarrow = mediaQuery.size.width < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding =
        navBarHeight + navBarBottomMargin + visualBreathingRoom;

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
            const StoryTrayWidget(),

            const SizedBox(height: 10),

            const QuickCreatePostCard(),

            const SizedBox(height: 10),

            if (widget.isHomeScreen) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: HomeFeaturedEventsCarousel(),
              ),
              const SizedBox(height: 10),
            ],

            Obx(() {
              if (controller.isLoadingFeed.value && controller.posts.isEmpty) {
                return _buildFeedSkeletonLoader(
                  isDark,
                  surfaceSecondary,
                  borderSubtle,
                );
              }

              if (controller.hasError.value && controller.posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : 'community.couldNotLoadFeed'.tr,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                            ) ??
                            TextStyle(color: textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () => controller.fetchPosts(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text('common.retry'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          foregroundColor: isDark
                              ? AppColors.darkTextInverse
                              : AppColors.lightTextInverse,
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

    // ── Empty state ───────────────────────────────────────────────────────────
    // When the real backend returns 0 posts, show ONLY a friendly empty state.
    // No fake events, no fake discussions — a clean slate.
    if (posts.isEmpty) {
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
                Icons.dynamic_feed_outlined,
                size: 52,
                color: textMuted.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 16),
              Text(
                'community.noPostsYet'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'community.beFirstToShare'.tr,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => CommunityCreationFlow.openCreatePost(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'community.createPost'.tr.isNotEmpty &&
                          'community.createPost'.tr != 'community.createPost'
                      ? 'community.createPost'.tr
                      : 'Create a post',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  foregroundColor: isDark
                      ? AppColors.darkTextInverse
                      : AppColors.lightTextInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Populated unified feed ────────────────────────────────────────────────
    // Pure timeline of real backend posts. No discovery panels injected here —
    // event cards and discussion posts appear naturally when the backend
    // returns them as part of the feed.
    final List<Widget> items = [];

    for (int i = 0; i < posts.length; i++) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: PostCardWidget(
            key: ValueKey('post_${posts[i].id}'),
            post: posts[i],
            controller: controller,
          ),
        ),
      );
    }

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

  Widget _buildForumTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom > 0
        ? mediaQuery.padding.bottom
        : mediaQuery.viewPadding.bottom;
    final screenWidth = mediaQuery.size.width;
    final isNarrow = screenWidth < 360;
    final isVeryNarrow = screenWidth < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 12.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding =
        navBarHeight + navBarBottomMargin + visualBreathingRoom + 24.0;

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
                    Icon(Icons.forum_outlined, size: 48, color: textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'community.noDiscussionsYet'.tr.isNotEmpty &&
                              'community.noDiscussionsYet'.tr !=
                                  'community.noDiscussionsYet'
                          ? 'community.noDiscussionsYet'.tr
                          : 'No discussions yet',
                      style:
                          theme.textTheme.titleMedium?.copyWith(
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
                      style: TextStyle(color: textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          Get.to(() => const CreateDiscussionScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        foregroundColor: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
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
              Text(
                'community.latestDiscussions'.tr.isNotEmpty &&
                        'community.latestDiscussions'.tr !=
                            'community.latestDiscussions'
                    ? 'community.latestDiscussions'.tr
                    : 'Latest Discussions',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ) ??
                    TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 12),
              ...latest.map(
                (topic) => ForumThreadCard(
                  title: topic.title,
                  author: topic.isAnonymous ? 'Anonymous' : topic.authorName,
                  avatarUrl: topic.isAnonymous
                      ? null
                      : (topic.authorAvatar.isNotEmpty
                          ? topic.authorAvatar
                          : null),
                  timeAgo: topic.timeAgo,
                  createdAt: topic.createdAt,
                  content: topic.content,
                  category: topic.category,
                  replies: topic.repliesCount,
                  likes: topic.upvotes,
                  isPinned: false,
                  isLiked: topic.isLiked,
                  isBookmarked: controller.isDiscussionBookmarked(topic.id),
                  likers: topic.likers,
                  discussionId: topic.id,
                  isOwner: topic.checkIsOwner(controller.currentUserId),
                  isAnonymous: topic.isAnonymous,
                  onTap: () =>
                      Get.to(() => ForumDiscussionScreen(discussion: topic)),
                  onLikeTap: () => controller.toggleDiscussionLike(topic.id),
                  onCommentTap: () =>
                      Get.to(() => ForumDiscussionScreen(discussion: topic)),
                  onSaveTap: () =>
                      controller.toggleDiscussionBookmark(topic.id),
                  onShareToChatTap: () =>
                      ForumShareToChatSheet.show(context, topic: topic),
                  onCategoryTap: () => Get.to(
                    () => ForumCategoryScreen(categoryTitle: topic.category),
                  ),
                  onMoreTap: () =>
                      _showDiscussionMoreMenu(context, controller, topic),
                ),
              ),
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
    final bg = isDark ? AppColors.darkSurfaceSecondary : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

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
                  ListTile(
                    leading: Icon(
                      Icons.edit_outlined,
                      color: textPrimary,
                      size: 22,
                    ),
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
                    onTap: () async {
                      Get.back();
                      final updated = await Get.to(
                        () => CreateDiscussionScreen(initialDiscussion: topic),
                      );
                      if (updated == true) {
                        controller.forumLatestDiscussions.refresh();
                      }
                    },
                  ),
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
                    onTap: () async {
                      Get.back();
                      final ok = await controller.reportDiscussion(topic.id);
                      if (context.mounted) {
                        if (ok) {
                          AppNotificationBanner.showSuccess(
                            context: context,
                            title:
                                'community.reported'.tr.isNotEmpty &&
                                    'community.reported'.tr !=
                                        'community.reported'
                                ? 'community.reported'.tr
                                : 'Reported',
                            message:
                                'Thank you for reporting. Our team will review it.',
                          );
                        } else {
                          AppNotificationBanner.showError(
                            context: context,
                            title: 'Error',
                            message:
                                'Failed to submit report. Please try again.',
                          );
                        }
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.close_rounded,
                    color: textSecondary,
                    size: 22,
                  ),
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
    final dialogBg = isDark ? AppColors.darkSurfaceSecondary : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'community.deleteDiscussion'.tr.isNotEmpty &&
                  'community.deleteDiscussion'.tr !=
                      'community.deleteDiscussion'
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
              try {
                final success = await controller.deleteDiscussion(topic.id);
                if (success && context.mounted) {
                  AppNotificationBanner.showSuccess(
                    context: context,
                    title:
                        'community.discussionDeleted'.tr.isNotEmpty &&
                            'community.discussionDeleted'.tr !=
                                'community.discussionDeleted'
                        ? 'community.discussionDeleted'.tr
                        : 'Discussion Deleted',
                    message:
                        'community.discussionDeletedMsg'.tr.isNotEmpty &&
                            'community.discussionDeletedMsg'.tr !=
                                'community.discussionDeletedMsg'
                        ? 'community.discussionDeletedMsg'.tr
                        : 'Your discussion has been removed.',
                  );
                } else if (context.mounted) {
                  AppNotificationBanner.showError(
                    context: context,
                    title: 'Error',
                    message: 'Failed to delete discussion. Please try again.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMsg =
                      'Failed to delete discussion. Please try again.';
                  if (e is AppError) {
                    if (e.isForbidden) {
                      errorMsg =
                          'You do not have permission to delete this discussion.';
                    } else if (e.isNotFound) {
                      errorMsg = 'Discussion not found.';
                    } else if (e.message.isNotEmpty) {
                      errorMsg = e.message;
                    }
                  }
                  AppNotificationBanner.showError(
                    context: context,
                    title: 'Error',
                    message: errorMsg,
                  );
                }
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

  Widget _buildEventTab(BuildContext context, CommunityController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final isNarrow = mediaQuery.size.width < 360;
    final isVeryNarrow = mediaQuery.size.width < 335;
    final navBarHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
    final navBarBottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;
    const visualBreathingRoom = 28.0;
    final bottomPadding =
        navBarHeight + navBarBottomMargin + visualBreathingRoom + 28.0;

    return RefreshIndicator(
      onRefresh: () => controller.refreshEvents(),
      color: AppColors.communityAccent,
      backgroundColor: surfaceSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Obx(() {
          if (controller.isLoadingEvents.value && controller.events.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'community.upcomingEvents'.tr.isNotEmpty &&
                            'community.upcomingEvents'.tr !=
                                'community.upcomingEvents'
                        ? 'community.upcomingEvents'.tr
                        : 'Upcoming Events',
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEventListSkeleton(isDark, surfaceSecondary, borderSubtle),
              ],
            );
          }

          if (controller.hasEventsError.value && controller.events.isEmpty) {
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'community.upcomingEvents'.tr.isNotEmpty &&
                          'community.upcomingEvents'.tr !=
                              'community.upcomingEvents'
                      ? 'community.upcomingEvents'.tr
                      : 'Upcoming Events',
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.2,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ),

              const SizedBox(height: 12),

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
                    return EventCard(
                      key: ValueKey('community-event-card-${ev.id}'),
                      event: ev,
                      controller: controller,
                      index: idx,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      cardBg: surfaceSecondary,
                      borderSubtle: borderSubtle,
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

  Widget _buildFeedSkeletonLoader(
    bool isDark,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final shimmerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
              border: Border.all(
                color: borderSubtle.withValues(alpha: isDark ? 0.45 : 0.75),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 13,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 220,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => Container(
                      width: 48,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
              border: Border.all(
                color: borderSubtle.withValues(alpha: isDark ? 0.45 : 0.75),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 13,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 28,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
              border: Border.all(
                color: borderSubtle.withValues(alpha: isDark ? 0.45 : 0.75),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 240,
                  height: 13,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 10,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                      'community.unableToLoadEvents'.tr !=
                          'community.unableToLoadEvents'
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
              onPressed: () => controller.refreshEvents(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimary
                    : Colors.black87,
                foregroundColor: isDark
                    ? AppColors.darkTextInverse
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
              ),
              child: Text(
                'community.tryAgain'.tr.isNotEmpty &&
                        'community.tryAgain'.tr != 'community.tryAgain'
                    ? 'community.tryAgain'.tr
                    : ('common.retry'.tr.isNotEmpty &&
                              'common.retry'.tr != 'common.retry'
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

  /// Event tab empty state — shown when backend returns 0 events.
  Widget _buildEventEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 56,
        horizontal: AppSpacing.lg,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 52,
              color: textMuted.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'community.noUpcomingEvents'.tr.isNotEmpty &&
                      'community.noUpcomingEvents'.tr !=
                          'community.noUpcomingEvents'
                  ? 'community.noUpcomingEvents'.tr
                  : 'No upcoming events',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'community.newEventsAppearHere'.tr.isNotEmpty &&
                      'community.newEventsAppearHere'.tr !=
                          'community.newEventsAppearHere'
                  ? 'community.newEventsAppearHere'.tr
                  : 'New events will appear here.',
              style: TextStyle(color: textMuted, fontSize: 13.5, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
