import 'dart:io';
import 'poll_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_post_model.dart';
import '../screens/create_post_screen.dart';
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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
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

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.bookmark_border, color: textPrimary),
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
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.repeat_rounded, color: textPrimary),
                title: Text(
                  'community.repost'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary) ??
                      TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRepostDialog(context);
                },
              ),
            ),
            if (widget.post.isOwner) ...[
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined, color: textPrimary),
                  title: Text(
                    'community.editPost'.tr,
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
                    'community.deletePost'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger) ??
                        const TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeletePost(context);
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
              final avatarRadius = isVeryNarrow ? 17.0 : (isNarrow ? 19.0 : 21.0);
              final headerGap = isVeryNarrow ? 6.0 : (isNarrow ? 8.0 : 12.0);
              final authorFontSize = isVeryNarrow ? 13.5 : (isNarrow ? 14.5 : 15.5);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 10.0 : AppSpacing.md,
                  isNarrow ? 10.0 : AppSpacing.md,
                  isNarrow ? 4.0 : AppSpacing.sm,
                  8,
                ),
                child: Row(
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
                          Row(
                            children: [
                              Text(
                                _formatTimeAgo(widget.post.timeAgo),
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: textMuted,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                    ) ??
                                    TextStyle(color: textMuted, fontSize: isVeryNarrow ? 10.5 : 11.5),
                              ),
                              const SizedBox(width: 4),
                              Text('·', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfacePrimary
                                        : AppColors.lightBgSecondary,
                                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                                  ),
                                  child: Text(
                                    widget.post.community,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                          color: textSecondary,
                                          fontSize: isVeryNarrow ? 9.5 : 10.5,
                                          fontWeight: FontWeight.w600,
                                        ) ??
                                        TextStyle(
                                          color: textSecondary,
                                          fontSize: isVeryNarrow ? 9.5 : 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!widget.post.isOwner) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.controller.toggleFollowUser(widget.post.userId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.post.isFollowing
                                ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.post.isFollowing
                                  ? borderSubtle
                                  : (isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.35)),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.post.isFollowing)
                                Icon(Icons.add_rounded, size: 12, color: textPrimary),
                              if (!widget.post.isFollowing) const SizedBox(width: 2),
                              Text(
                                widget.post.isFollowing ? 'community.following'.tr : 'community.follow'.tr,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.post.isFollowing ? textSecondary : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                            color: widget.post.isLiked ? textPrimary : actionIconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.likesCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.post.isLiked ? textPrimary : actionIconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ) ??
                              TextStyle(
                                color: widget.post.isLiked ? textPrimary : actionIconColor,
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
                  onTap: () => _showRepostDialog(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: actionIconColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.repostsCount}",
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

                const Spacer(),

                // Bookmark Button
                IconButton(
                  onPressed: () {
                    _bookmarkAnimController.forward(from: 0.0);
                    widget.controller.toggleBookmark(widget.post.id);
                  },
                  icon: ScaleTransition(
                    scale: _bookmarkScaleAnim,
                    child: Icon(
                      widget.post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: widget.post.isBookmarked ? textPrimary : actionIconColor,
                      size: 21,
                    ),
                  ),
                  tooltip: widget.post.isBookmarked ? 'community.removeBookmark'.tr : 'community.saveBookmark'.tr,
                ),
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
}
