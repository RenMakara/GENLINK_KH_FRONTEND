import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'forum_discussion_screen.dart';
import 'widgets/community_widgets.dart';

class ForumCategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const ForumCategoryScreen({super.key, required this.categoryTitle});

  @override
  State<ForumCategoryScreen> createState() => _ForumCategoryScreenState();
}

class _ForumCategoryScreenState extends State<ForumCategoryScreen> {
  late final CommunityController _controller;
  List<ForumTopicModel> _discussions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
    } else {
      _controller = Get.put(CommunityController());
    }
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final fetched = await _controller.repository.getDiscussions(
        category: widget.categoryTitle,
        page: 1,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _discussions = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is AppError
              ? e.message
              : 'community.couldNotLoadDiscussions'.tr.isNotEmpty &&
                      'community.couldNotLoadDiscussions'.tr !=
                          'community.couldNotLoadDiscussions'
                  ? 'community.couldNotLoadDiscussions'.tr
                  : "Couldn't load discussions. Please try again.";
        });
      }
    }
  }

  void _handleLikeTap(ForumTopicModel topic, int index) async {
    final prevLiked = topic.isLiked;
    final prevUpvotes = topic.upvotes;

    setState(() {
      _discussions[index] = topic.copyWith(
        isLiked: !prevLiked,
        upvotes: prevUpvotes + (!prevLiked ? 1 : -1),
      );
    });

    final success = await _controller.toggleDiscussionLike(topic.id);
    if (!success && mounted) {
      setState(() {
        _discussions[index] = topic.copyWith(
          isLiked: prevLiked,
          upvotes: prevUpvotes,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 72,
        title: Text(
          widget.categoryTitle.tr.isNotEmpty &&
                  widget.categoryTitle.tr != widget.categoryTitle
              ? widget.categoryTitle.tr
              : widget.categoryTitle,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDiscussions,
        color: AppColors.communityAccent,
        backgroundColor:
            isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        child: _buildBody(context, isDark, textPrimary, textSecondary),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.communityAccent,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: textSecondary,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDiscussions,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'common.retry'.tr.isNotEmpty &&
                          'common.retry'.tr != 'common.retry'
                      ? 'common.retry'.tr
                      : 'Retry',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  foregroundColor: isDark
                      ? AppColors.darkTextInverse
                      : AppColors.lightTextInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              color: textSecondary.withValues(alpha: 0.5),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'community.noDiscussionsInCategory'.tr.isNotEmpty &&
                      'community.noDiscussionsInCategory'.tr !=
                          'community.noDiscussionsInCategory'
                  ? 'community.noDiscussionsInCategory'.tr
                  : 'No discussions found in this category.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final safeBottom = MediaQuery.paddingOf(context).bottom > 0
        ? MediaQuery.paddingOf(context).bottom
        : MediaQuery.viewPaddingOf(context).bottom;
    final bottomPadding = AppSpacing.md + safeBottom;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomPadding,
      ),
      itemCount: _discussions.length,
      itemBuilder: (context, index) {
        final topic = _discussions[index];
        return ForumThreadCard(
          title: topic.title,
          author: topic.authorName,
          avatarUrl: topic.authorAvatar,
          timeAgo: topic.timeAgo,
          createdAt: topic.createdAt,
          content: topic.content,
          category: topic.category,
          replies: topic.repliesCount,
          likes: topic.upvotes,
          isPinned: topic.isPinned,
          isLiked: topic.isLiked,
          onTap: () =>
              Get.to(() => ForumDiscussionScreen(discussion: topic)),
          onCommentTap: () =>
              Get.to(() => ForumDiscussionScreen(discussion: topic)),
          onLikeTap: () => _handleLikeTap(topic, index),
        );
      },
    );
  }
}
