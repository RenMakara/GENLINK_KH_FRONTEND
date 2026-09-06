import 'dart:io';
import 'poll_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../screens/create_discussion_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/event_details_screen.dart';
import '../controllers/community_controller.dart';
import 'comments_bottom_sheet.dart';
import 'full_screen_image_viewer.dart';

class PostCardWidget extends StatefulWidget {
  final CommunityPostModel post;
  final CommunityController controller;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.controller,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> with TickerProviderStateMixin {
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnim;

  late AnimationController _bookmarkAnimController;
  late Animation<double> _bookmarkScaleAnim;

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_likeAnimController);

    _bookmarkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _bookmarkScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(_bookmarkAnimController);
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    _bookmarkAnimController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(String raw) {
    final trimmed = raw.trim();
    if (trimmed == 'Just now' || trimmed.toLowerCase().contains('just now')) {
      return 'community.justNow'.tr;
    } else if (trimmed == 'Yesterday') {
      return 'community.yesterday'.tr;
    } else if (trimmed == 'Today') {
      return 'community.today'.tr;
    } else if (trimmed.endsWith('m ago')) {
      final min = trimmed.replaceAll('m ago', '').trim();
      return 'community.minAgo'.trParams({'min': min});
    } else if (trimmed.endsWith('h ago')) {
      final hour = trimmed.replaceAll('h ago', '').trim();
      return 'community.hourAgo'.trParams({'hour': hour});
    } else if (trimmed.endsWith('d ago')) {
      final day = trimmed.replaceAll('d ago', '').trim();
      return '$day ថ្ងៃមុន';
    }
    return raw;
  }

  void _onLikeTap() {
    _likeAnimController.forward(from: 0.0);
    widget.controller.toggleLike(widget.post.id);
  }

  void _confirmDeletePost(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.squircle)),
        title: Text(
          'community.deletePost'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          'community.deletePostConfirm'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary) ??
              TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr,
              style: theme.textTheme.labelMedium?.copyWith(color: textSecondary) ??
                  TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.deletePost(widget.post.id);
              AppNotificationBanner.showDanger(
                context: context,
                title: "Post Deleted",
                message: "Your post has been removed.",
                actionLabel: "Undo",
                onAction: () {
                  widget.controller.undoDeletePost();
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(
              'common.delete'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDiscussion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? const Color(0xFF1E2228) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white70 : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'community.deleteDiscussion'.tr.isNotEmpty &&
                  'community.deleteDiscussion'.tr !=
                      'community.deleteDiscussion'
              ? '${'community.deleteDiscussion'.tr}?'
              : 'Delete Discussion?',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await widget.controller.deleteDiscussion(widget.post.id);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
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

  bool get _isOwnPost {
    String? currentUserId;
    if (Get.isRegistered<AuthController>()) {
      currentUserId = Get.find<AuthController>().currentUser.value?.id;
    }
    currentUserId ??= widget.controller.currentUserId;
    return widget.post.checkIsOwner(currentUserId) ||
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            widget.post.userId == currentUserId);
  }

  bool get _isFollowing {
    final livePost =
        widget.controller.posts.firstWhereOrNull((p) => p.id == widget.post.id);
    if (livePost != null) return livePost.isFollowing;
    return widget.controller.isFollowingUser(widget.post.userId) ||
        widget.post.isFollowing;
  }

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final isDiscussion = widget.post.postType == 'DISCUSSION';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Bookmark toggle (Always available)
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(
                  widget.post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border,
                  color: textPrimary,
                ),
                title: Text(
                  widget.post.isBookmarked ? 'community.removeBookmark'.tr : 'community.saveBookmark'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary) ??
                      TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.controller.toggleBookmark(widget.post.id);
                  if (widget.post.isBookmarked) {
                    AppNotificationBanner.showInfo(
                      context: context,
                      title: "Saved",
                      message: "Added to bookmarks.",
                      icon: Icons.bookmark_added_rounded,
                    );
                  }
                },
              ),
            ),

            // 2. OTHER USER'S POST OPTIONS: Repost / Unrepost, Report Post
            if (!_isOwnPost) ...[
              if (!isDiscussion)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(
                      Icons.repeat_rounded,
                      color: widget.post.isRepostedByMe ? AppColors.growthAccent : textPrimary,
                    ),
                    title: Text(
                      widget.post.isRepostedByMe ? 'community.unrepost'.tr : 'community.repost'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.post.isRepostedByMe ? AppColors.growthAccent : textPrimary,
                          ) ??
                          TextStyle(
                            color: widget.post.isRepostedByMe ? AppColors.growthAccent : textPrimary,
                          ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (widget.post.isRepostedByMe) {
                        widget.controller.unrepostPost(widget.post.id);
                        AppNotificationBanner.showInfo(
                          context: context,
                          title: 'community.unreposted'.tr,
                          message: 'community.unrepostedMsg'.tr,
                          icon: Icons.repeat_rounded,
                        );
                      } else {
                        _showRepostDialog(context);
                      }
                    },
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.flag_outlined, color: textPrimary),
                  title: Text(
                    isDiscussion
                        ? ('community.report'.tr.isNotEmpty && 'community.report'.tr != 'community.report'
                            ? 'community.report'.tr
                            : 'Report')
                        : 'community.reportPost'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary) ??
                        TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.controller.reportPost(widget.post.id);
                    AppNotificationBanner.showInfo(
                      context: context,
                      title: 'community.postReported'.tr,
                      message: 'community.postReportedMsg'.tr,
                      icon: Icons.flag_rounded,
                    );
                  },
                ),
              ),
            ],

            // 3. OWN POST OPTIONS: Edit Post, Delete Post (NO REPOST)
            if (_isOwnPost) ...[
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined, color: textPrimary),
                  title: Text(
                    isDiscussion
                        ? ('community.editDiscussion'.tr.isNotEmpty &&
                                'community.editDiscussion'.tr !=
                                    'community.editDiscussion'
                            ? 'community.editDiscussion'.tr
                            : 'Edit Discussion')
                        : 'community.editPost'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary) ??
                        TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context);
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text(
                    isDiscussion
                        ? ('community.deleteDiscussion'.tr.isNotEmpty &&
                                'community.deleteDiscussion'.tr !=
                                    'community.deleteDiscussion'
                            ? 'community.deleteDiscussion'.tr
                            : 'Delete Discussion')
                        : 'community.deletePost'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger) ??
                        const TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isDiscussion) {
                      _confirmDeleteDiscussion(context);
                    } else {
                      _confirmDeletePost(context);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    if (widget.post.postType == 'DISCUSSION') {
      final topic = widget.controller.getDiscussionById(widget.post.id);
      if (topic != null) {
        Get.to(() => CreateDiscussionScreen(initialDiscussion: topic));
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(initialPost: widget.post),
      ),
    );
  }

  void _showRepostDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final captionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          side: BorderSide(color: borderSubtle),
        ),
        title: Text(
          'community.repostContent'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'community.repostingOriginal'.trParams({'name': widget.post.authorName}),
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary) ??
                  TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              child: TextField(
                controller: captionController,
                minLines: 2,
                maxLines: 4,
                style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary) ??
                    TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                decoration: InputDecoration(
                  hintText: 'community.repostQuoteHint'.tr,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                      TextStyle(
                        color: textMuted,
                        fontSize: 14,
                      ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            child: Text(
              'common.cancel'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.repostPost(widget.post.id, caption: captionController.text);
              AppNotificationBanner.showSuccess(
                context: context,
                title: "✓ Reposted",
                message: "Post has been reposted to your feed.",
                icon: Icons.repeat_rounded,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
            child: Text(
              'community.repostNow'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final actionIconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(color: borderSubtle, width: 1.0),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repost Header Banner
          if (widget.post.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: 12,
                right: AppSpacing.md,
                bottom: 4,
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded, color: AppColors.darkTextSecondary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'community.userReposted'.trParams({'name': widget.post.repostedBy ?? ''}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                            fontWeight: FontWeight.bold,
                          ) ??
                          TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Optional Repost Quote Caption
          if (widget.post.repostCaption != null && widget.post.repostCaption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: 6,
                right: AppSpacing.md,
                bottom: 10,
              ),
              child: Text(
                widget.post.repostCaption!,
                style: theme.textTheme.titleSmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ) ??
                    TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.45),
              ),
            ),

          // Author Header Tile - Adaptive for 320px to 430px+
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final isVeryNarrow = constraints.maxWidth < 330;
              final avatarRadius = isVeryNarrow ? 17.0 : (isNarrow ? 19.0 : 20.0);
              final headerGap = isVeryNarrow ? 6.0 : (isNarrow ? 8.0 : 10.0);
              final authorFontSize = isVeryNarrow ? 13.5 : (isNarrow ? 14.5 : 15.0);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 10.0 : AppSpacing.md,
                  isNarrow ? 10.0 : AppSpacing.md,
                  isNarrow ? 4.0 : AppSpacing.sm,
                  8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final username = widget.post.authorTag.replaceAll('@', '');
                        Get.toNamed(AppRoutes.profile, parameters: {'username': username});
                      },
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: widget.post.authorAvatar.startsWith('assets/')
                            ? AssetImage(widget.post.authorAvatar) as ImageProvider
                            : (widget.post.authorAvatar.startsWith('http')
                                ? NetworkImage(widget.post.authorAvatar)
                                : null),
                        backgroundColor: isDark
                            ? const Color(0xFF242424)
                            : AppColors.lightBgSecondary,
                        child: (!widget.post.authorAvatar.startsWith('http') && !widget.post.authorAvatar.startsWith('assets/'))
                            ? Text(
                                widget.post.authorAvatar.isNotEmpty ? widget.post.authorAvatar[0] : 'U',
                                style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: headerGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    final username = widget.post.authorTag.replaceAll('@', '');
                                    Get.toNamed(AppRoutes.profile, parameters: {'username': username});
                                  },
                                  child: Text(
                                    widget.post.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: authorFontSize,
                                          letterSpacing: -0.2,
                                        ) ??
                                        TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: authorFontSize,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                ),
                              ),
                              if (widget.post.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: AppColors.darkTextSecondary, size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (widget.post.attachedEvent != null || widget.post.postType?.toLowerCase() == 'event')
                            Row(
                              children: [
                                Text(
                                  'community.postedAnEvent'.tr.isNotEmpty &&
                                          'community.postedAnEvent'.tr != 'community.postedAnEvent'
                                      ? 'community.postedAnEvent'.tr
                                      : 'Posted an event',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: isVeryNarrow ? 10.5 : 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('·', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatTimeAgo(widget.post.timeAgo),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                          color: textMuted,
                                          fontSize: isVeryNarrow ? 10.5 : 11.5,
                                        ) ??
                                        TextStyle(color: textMuted, fontSize: isVeryNarrow ? 10.5 : 11.5),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _formatTimeAgo(widget.post.timeAgo),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                          color: textMuted,
                                          fontSize: isVeryNarrow ? 10.5 : 11.5,
                                        ) ??
                                        TextStyle(color: textMuted, fontSize: isVeryNarrow ? 10.5 : 11.5),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('·', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (widget.post.postType == 'DISCUSSION' || widget.post.category != null)
                                        ? '${widget.post.category ?? 'Technology'} · ${'community.discussion'.tr.isNotEmpty && 'community.discussion'.tr != 'community.discussion' ? 'community.discussion'.tr : 'Discussion'}'
                                        : widget.post.community,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                          color: textSecondary,
                                          fontSize: isVeryNarrow ? 10.0 : 11.0,
                                          fontWeight: FontWeight.w500,
                                        ) ??
                                        TextStyle(
                                          color: textSecondary,
                                          fontSize: isVeryNarrow ? 10.0 : 11.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (!_isOwnPost) ...[
                      const SizedBox(width: 6),
                      Obx(() {
                        final isFollowing = _isFollowing;
                        final isLoading = widget.controller.followLoadingUserIds.contains(widget.post.userId);

                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: isLoading ? null : () => widget.controller.toggleFollowUser(widget.post.userId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: isFollowing
                                  ? (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isFollowing
                                    ? (isDark ? Colors.white30 : Colors.black26)
                                    : (isDark ? Colors.white.withValues(alpha: 0.40) : Colors.black.withValues(alpha: 0.35)),
                                width: 0.9,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: isFollowing
                                  ? Row(
                                      key: const ValueKey('following'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_rounded,
                                          size: 13,
                                          color: textPrimary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'community.following'.tr,
                                          style: TextStyle(
                                            fontSize: isVeryNarrow ? 10.0 : 11.0,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      key: const ValueKey('follow'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          size: 13,
                                          color: textPrimary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'community.follow'.tr,
                                          style: TextStyle(
                                            fontSize: isVeryNarrow ? 10.0 : 11.0,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded, color: actionIconColor, size: isVeryNarrow ? 18 : 20),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _showMoreMenu(context),
                      tooltip: 'Options',
                    ),
                  ],
                ),
              );
            },
          ),

          // Discussion Title (if discussion post)
          if (widget.post.discussionTitle != null &&
              widget.post.discussionTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                4,
                AppSpacing.md,
                2,
              ),
              child: Text(
                widget.post.discussionTitle!,
                style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      height: 1.35,
                    ) ??
                    TextStyle(
                      color: textPrimary,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
              ),
            ),

          // Post Content Text
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
              child: Text(
                widget.post.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: textPrimary,
                      fontSize: 14.5,
                      height: 1.50,
                      letterSpacing: 0.1,
                    ) ??
                    TextStyle(
                      color: textPrimary,
                      fontSize: 14.5,
                      height: 1.50,
                      letterSpacing: 0.1,
                    ),
              ),
            ),

          // Location Tag Chip
          if (widget.post.location != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: textMuted, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.post.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: textSecondary, fontSize: 12) ??
                          TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Responsive Multi-Image Grid Layout
          if (widget.post.imageUrls.isNotEmpty) _buildImageGrid(widget.post.imageUrls),

          // Modular Poll Widget Component
          if (widget.post.pollQuestion != null && widget.post.pollOptions != null)
            PollWidget(
              question: widget.post.pollQuestion!,
              options: widget.post.pollOptions!,
              duration: widget.post.pollDuration,
              hideResultsUntilVote: widget.post.hideResultsUntilVote,
            ),

          // Link Preview Card Component
          if (widget.post.linkUrl != null)
            _buildLinkPreviewCard(
              url: widget.post.linkUrl!,
              title: widget.post.linkPreviewTitle,
              domain: widget.post.linkPreviewDomain,
            ),

          // Attached Event Card Component
          if (widget.post.attachedEvent != null)
            _buildAttachedEventCard(context, widget.post.attachedEvent!),

          const SizedBox(height: 2),
          // Post Action Buttons Bar (Like, Comment, Repost, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                // Animated Like Button
                InkWell(
                  onTap: _onLikeTap,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeScaleAnim,
                          child: Icon(
                            widget.post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: widget.post.isLiked
                                ? AppColors.likedAccent
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.likesCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.post.isLiked
                                    ? AppColors.likedAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ) ??
                              TextStyle(
                                color: widget.post.isLiked
                                    ? AppColors.likedAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Comment Button
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsBottomSheet(postId: widget.post.id),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: actionIconColor, size: 19),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.commentsCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: actionIconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ) ??
                              TextStyle(color: actionIconColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Repost Button
                InkWell(
                  onTap: _isOwnPost
                      ? () {
                          AppNotificationBanner.showWarning(
                            context: context,
                            title: "Cannot Repost",
                            message: 'community.cannotRepostOwnPost'.tr,
                          );
                        }
                      : () {
                          if (widget.post.isRepostedByMe) {
                            widget.controller.unrepostPost(widget.post.id);
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: 'community.unreposted'.tr,
                              message: 'community.unrepostedMsg'.tr,
                              icon: Icons.repeat_rounded,
                            );
                          } else {
                            _showRepostDialog(context);
                          }
                        },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: widget.post.isRepostedByMe
                              ? AppColors.growthAccent
                              : actionIconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.repostsCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.post.isRepostedByMe
                                    ? AppColors.growthAccent
                                    : actionIconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ) ??
                              TextStyle(
                                color: widget.post.isRepostedByMe
                                    ? AppColors.growthAccent
                                    : actionIconColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bookmark Button
                Obx(() {
                  final livePost = widget.controller.posts.firstWhereOrNull((p) => p.id == widget.post.id);
                  final isBookmarked = livePost?.isBookmarked ?? widget.post.isBookmarked;

                  return IconButton(
                    onPressed: () {
                      _bookmarkAnimController.forward(from: 0.0);
                      widget.controller.toggleBookmark(widget.post.id);
                    },
                    icon: ScaleTransition(
                      scale: _bookmarkScaleAnim,
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isBookmarked ? const Color(0xFFF59E0B) : actionIconColor,
                        size: 21,
                      ),
                    ),
                    tooltip: isBookmarked ? 'community.removeBookmark'.tr : 'community.saveBookmark'.tr,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    final count = images.length;

    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: _buildSingleImage(images[0], index: 0, allImages: images),
          ),
        ),
      );
    }

    if (count == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          child: SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(child: _buildSingleImage(images[0], index: 0, allImages: images)),
                const SizedBox(width: 4),
                Expanded(child: _buildSingleImage(images[1], index: 1, allImages: images)),
              ],
            ),
          ),
        ),
      );
    }

    if (count == 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          child: SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSingleImage(images[0], index: 0, allImages: images)),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(child: _buildSingleImage(images[1], index: 1, allImages: images)),
                      const SizedBox(height: 4),
                      Expanded(child: _buildSingleImage(images[2], index: 2, allImages: images)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final extraCount = count - 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        child: SizedBox(
          height: 220,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.6,
            ),
            itemCount: 4,
            itemBuilder: (context, idx) {
              if (idx == 3 && extraCount > 0) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSingleImage(images[idx], index: idx, allImages: images),
                    GestureDetector(
                      onTap: () => _openFullScreenViewer(idx, images),
                      child: Container(
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkBgPrimary
                                : AppColors.lightPrimary)
                            .withValues(alpha: 0.65),
                        alignment: Alignment.center,
                        child: Text(
                          "+$extraCount",
                          style: const TextStyle(
                            color: AppColors.darkTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return _buildSingleImage(images[idx], index: idx, allImages: images);
            },
          ),
        ),
      ),
    );
  }

  void _openFullScreenViewer(int index, List<String> allImages) {
    final heroPrefix = 'post_${widget.post.id}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenImageViewer(
              images: allImages,
              initialIndex: index,
              heroTagPrefix: heroPrefix,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleImage(String url, {int index = 0, List<String>? allImages}) {
    final heroTag = 'post_${widget.post.id}_$index';
    final imagesList = allImages ?? [url];

    Widget imgWidget;
    if (url.startsWith('assets/')) {
      imgWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (url.startsWith('http')) {
      imgWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      imgWidget = Image.file(
        File(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreenViewer(index, imagesList),
      child: Hero(
        tag: heroTag,
        child: imgWidget,
      ),
    );
  }

  Widget _buildLinkPreviewCard({
    required String url,
    String? title,
    String? domain,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final displayDomain = domain ?? (url.contains('github.com') ? 'github.com' : 'campuslink.kh');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232323) : AppColors.lightBgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.link, color: textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ) ??
                      TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  displayDomain,
                  style: theme.textTheme.bodySmall?.copyWith(color: textSecondary) ??
                      TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(String dateString, String timeString) {
    if (dateString.trim().isEmpty) return '';

    String localizedDate = dateString.trim();
    final isKhmer = Get.locale?.languageCode == 'km';
    if (isKhmer) {
      final kmMonths = 'date.months'.tr.split(',');
      const enMonths = [
        'jan', 'feb', 'mar', 'apr', 'may', 'jun',
        'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
      ];
      if (kmMonths.length == 12) {
        for (int i = 0; i < enMonths.length; i++) {
          final regex = RegExp(enMonths[i], caseSensitive: false);
          if (regex.hasMatch(localizedDate)) {
            localizedDate = localizedDate.replaceFirst(regex, kmMonths[i].trim());
            break;
          }
        }
      }
    }

    if (timeString.trim().isNotEmpty) {
      return '$localizedDate · $timeString';
    }
    return localizedDate;
  }

  Widget _buildAttachedEventCard(BuildContext context, EventModel event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final badgeBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final ctaBg = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final ctaText = isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse;

    final hasLocalCover = event.coverImageFile != null;
    final hasNetworkCover = event.imageUrl.isNotEmpty;

    // Location / Online string resolution
    final isOnline = event.eventType.toLowerCase().contains('online');
    final String onlineLabel = 'community.onlineEvent'.tr.isNotEmpty &&
            'community.onlineEvent'.tr != 'community.onlineEvent'
        ? 'community.onlineEvent'.tr
        : 'Online Event';
    final String inPersonLabel = 'community.inPerson'.tr.isNotEmpty &&
            'community.inPerson'.tr != 'community.inPerson'
        ? 'community.inPerson'.tr
        : 'In person';

    final locationText = isOnline
        ? (event.onlineLink.isNotEmpty ? event.onlineLink : onlineLabel)
        : (event.location.isNotEmpty ? event.location : inPersonLabel);

    final locationIcon = isOnline ? Icons.videocam_outlined : Icons.location_on_outlined;

    // Formatted date & time display with localization support
    final dateTimeDisplay = _formatEventDate(event.dateString, event.timeString);

    final rawCat = event.category.isNotEmpty ? event.category : 'Event';
    final catKey = 'community.${rawCat.toLowerCase()}';
    final categoryDisplay = catKey.tr.isNotEmpty && catKey.tr != catKey ? catKey.tr : rawCat;

    final String joinedLabel = 'community.joined'.tr.isNotEmpty &&
            'community.joined'.tr != 'community.joined'
        ? 'community.joined'.tr
        : 'joined';
    final String viewEventLabel = 'community.viewEvent'.tr.isNotEmpty &&
            'community.viewEvent'.tr != 'community.viewEvent'
        ? 'community.viewEvent'.tr
        : 'View Event';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderSubtle, width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.to(
                () => EventDetailsScreen(
                  event: event,
                  heroTag: 'post-event-${event.id}-${widget.post.id}',
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Event Cover Image Banner
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Hero(
                      tag: 'post-event-${event.id}-${widget.post.id}',
                      child: hasLocalCover
                          ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                          : (hasNetworkCover
                              ? Image.network(
                                  event.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildMonochromeEventPlaceholder(isDark, textSecondary),
                                )
                              : _buildMonochromeEventPlaceholder(isDark, textSecondary)),
                    ),
                  ),

                  // 2. Event Info Details
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                categoryDisplay.toUpperCase(),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (event.isPaid) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.communityAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'community.paid'.tr.isNotEmpty && 'community.paid'.tr != 'community.paid'
                                      ? 'community.paid'.tr.toUpperCase()
                                      : 'PAID',
                                  style: const TextStyle(
                                    color: AppColors.communityAccent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Event Title (Most Prominent)
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Date & Time
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, color: textSecondary, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateTimeDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Location OR Online Indicator
                        Row(
                          children: [
                            Icon(locationIcon, color: textSecondary, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Short Description (if available)
                        if (event.description.trim().isNotEmpty &&
                            event.description.trim() != event.title) ...[
                          const SizedBox(height: 8),
                          Text(
                            event.description.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Bottom Row: Attendees count on left, View Event button on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (event.attendeesCount > 0)
                              Text(
                                '👥 ${event.attendeesCount} $joinedLabel',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: ctaBg,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                viewEventLabel,
                                style: TextStyle(
                                  color: ctaText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
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
      ),
    );
  }

  /// Clean monochrome GenLink Event Placeholder when no cover image is available
  Widget _buildMonochromeEventPlaceholder(bool isDark, Color textSecondary) {
    final bg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfaceSecondary;
    final iconColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 40, color: iconColor),
            const SizedBox(height: 6),
            Text(
              'GENLINK COMMUNITY EVENT',
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
