import 'dart:io';
import 'poll_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/date_formatter.dart';
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
import 'community_design_tokens.dart';
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

  bool _isContentExpanded = false;
  int _currentImageIndex = 0;

  @override
  void didUpdateWidget(covariant PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _currentImageIndex = 0;
    }
  }

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
    return formatCommunityTimestamp(raw);
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
        isDark ? AppColors.darkSurfaceSecondary : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
    final surface = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
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
    final actionIconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final resolvedEvent = widget.post.attachedEvent ??
        (widget.post.isEventPost && widget.post.eventId != null
            ? widget.controller.events.firstWhereOrNull(
                (e) => e.id == widget.post.eventId,
              )
            : null);

    return Container(
      margin: const EdgeInsets.only(bottom: CommunityCardStyle.cardBottomMargin),
      decoration: CommunityCardStyle.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  Icon(Icons.repeat_rounded, color: textSecondary, size: 16),
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

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final isVeryNarrow = constraints.maxWidth < 330;
              final avatarRadius = isVeryNarrow ? 17.0 : (isNarrow ? 18.0 : 19.0);
              final headerGap = isVeryNarrow ? 6.0 : (isNarrow ? 8.0 : 10.0);
              final authorFontSize = isVeryNarrow ? 13.5 : (isNarrow ? 14.0 : 14.5);

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
                        onBackgroundImageError: widget.post.authorAvatar.startsWith('http')
                            ? (_, _) {}
                            : null,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.lightBgSecondary,
                        child: (!widget.post.authorAvatar.startsWith('http') && !widget.post.authorAvatar.startsWith('assets/'))
                            ? Text(
                                widget.post.authorAvatar.isNotEmpty
                                    ? widget.post.authorAvatar[0]
                                    : (widget.post.authorName.trim().isNotEmpty
                                        ? widget.post.authorName.trim()[0].toUpperCase()
                                        : 'U'),
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
                                Icon(Icons.verified, color: textSecondary, size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (widget.post.attachedEvent != null || widget.post.postType?.toLowerCase() == 'event')
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'community.postedAnEvent'.tr.isNotEmpty &&
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
                                  TextSpan(
                                    text: ' · ${_formatTimeAgo(widget.post.timeAgo)}',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (widget.post.location != null && widget.post.location!.isNotEmpty)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.post.location!,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' · ${_formatTimeAgo(widget.post.timeAgo)}',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (widget.post.postType == 'DISCUSSION' || widget.post.category != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CommunityCategoryBadge(
                                    label: widget.post.category ?? 'Technology',
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    fontSize: isVeryNarrow ? 10.0 : 10.5,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '· ${_formatTimeAgo(widget.post.timeAgo)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: isVeryNarrow ? 10.5 : 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.post.community,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' · ${_formatTimeAgo(widget.post.timeAgo)}',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: isVeryNarrow ? 10.5 : 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.content,
                    maxLines: (widget.post.content.length <= 220 || _isContentExpanded)
                        ? null
                        : 4,
                    overflow: (widget.post.content.length <= 220 || _isContentExpanded)
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontSize: 14.5,
                          height: 1.55,
                          letterSpacing: 0.15,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          height: 1.55,
                          letterSpacing: 0.15,
                        ),
                  ),
                  if (widget.post.content.length > 220) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isContentExpanded = !_isContentExpanded),
                      child: Text(
                        _isContentExpanded
                            ? ('common.seeLess'.tr.isNotEmpty && 'common.seeLess'.tr != 'common.seeLess'
                                ? 'common.seeLess'.tr
                                : 'See less')
                            : ('common.seeMore'.tr.isNotEmpty && 'common.seeMore'.tr != 'common.seeMore'
                                ? 'common.seeMore'.tr
                                : '...See more'),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

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

          // ─── Step 3B-Frontend: Video rendering ───────────────────────
          // isVideoPost is true only when videoUrl != null && non-empty.
          // This fires ONLY for VIDEO posts. Image/text posts unaffected.
          if (widget.post.isVideoPost)
            VideoPostMedia(videoUrl: widget.post.videoUrl!),
          // Integration point for Step 3B-Backend:
          // When backend returns videoUrl in PostResponse, it will be parsed
          // into CommunityPostModel.videoUrl and rendered here automatically.
          // ─────────────────────────────────────────────────────────────

          if (widget.post.imageUrls.isNotEmpty &&
              !(resolvedEvent != null &&
                  widget.post.imageUrls.length == 1 &&
                  widget.post.imageUrls.first == resolvedEvent.imageUrl))
            _buildImageCarousel(widget.post.imageUrls),

          if (widget.post.pollQuestion != null && widget.post.pollOptions != null)
            PollWidget(
              postId: widget.post.id,
              question: widget.post.pollQuestion!,
              options: widget.post.pollOptions!,
              totalVotes: widget.post.pollTotalVotes,
              hasVoted: widget.post.hasVoted,
              myOptionId: widget.post.myOptionId,
              duration: widget.post.pollDuration,
              hideResultsUntilVote: widget.post.hideResultsUntilVote,
              onVote: (optionId) async {
                await widget.controller.votePoll(widget.post.id, optionId);
              },
            ),

          if (widget.post.linkUrl != null)
            _buildLinkPreviewCard(
              url: widget.post.linkUrl!,
              title: widget.post.linkPreviewTitle,
              domain: widget.post.linkPreviewDomain,
            ),

          if (resolvedEvent != null)
            _buildAttachedEventCard(context, resolvedEvent),

          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                InkWell(
                  onTap: _onLikeTap,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeScaleAnim,
                          child: Icon(
                            widget.post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: widget.post.isLiked
                                ? AppColors.likedAccent
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.post.likesCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.post.isLiked
                                    ? AppColors.likedAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ) ??
                              TextStyle(
                                color: widget.post.isLiked
                                    ? AppColors.likedAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: actionIconColor, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.post.commentsCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: actionIconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ) ??
                              TextStyle(color: actionIconColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: widget.post.isRepostedByMe
                              ? AppColors.growthAccent
                              : actionIconColor,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.post.repostsCount}",
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.post.isRepostedByMe
                                    ? AppColors.growthAccent
                                    : actionIconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ) ??
                              TextStyle(
                                color: widget.post.isRepostedByMe
                                    ? AppColors.growthAccent
                                    : actionIconColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

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
                        color: isBookmarked
                            ? AppColors.warning
                            : actionIconColor,
                        size: 19,
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

  Widget _buildImageCarousel(List<String> images) {
    final count = images.length;
    if (count == 0) return const SizedBox.shrink();

    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: _buildSingleImage(images[0], index: 0, allImages: images),
          ),
        ),
      );
    }

    final activeIndex = _currentImageIndex.clamp(0, count - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        child: SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: count,
                onPageChanged: (idx) {
                  setState(() {
                    _currentImageIndex = idx;
                  });
                },
                itemBuilder: (context, idx) {
                  return _buildSingleImage(images[idx], index: idx, allImages: images);
                },
              ),
              // Subtle top-right index counter badge (e.g. "1/3")
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeIndex + 1}/$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              // Subtle bottom dot indicators
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(count, (dotIdx) {
                        final isSelected = dotIdx == activeIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isSelected ? 12 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
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
        errorBuilder: (context, error, stackTrace) => Container(
          color: (Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceSecondary
              : AppColors.lightBgSecondary),
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted),
            size: 32,
          ),
        ),
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
    final surface = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
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
        border: Border.all(color: borderSubtle.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
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

  String _formatEventDate(EventModel event) {
    final isKhmer = Get.locale?.languageCode == 'km';
    if (event.startDateTime != null) {
      final d = event.formatLocalizedDateRange(isKhmer);
      final t = event.formatLocalizedTimeRange(isKhmer);
      if (d.isNotEmpty && t.isNotEmpty) {
        return '$d · $t';
      } else if (d.isNotEmpty) {
        return d;
      }
    }

    String dateStr = event.dateString.trim();
    String timeStr = event.timeString.trim();

    if (dateStr.isEmpty) return '';

    String localizedDate = dateStr;
    final kmMonths = 'date.months'.tr.split(',');
    const enMonths = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    if (kmMonths.length == 12 && 'date.months'.tr != 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec') {
      for (int i = 0; i < enMonths.length; i++) {
        final regex = RegExp(enMonths[i], caseSensitive: false);
        if (regex.hasMatch(localizedDate)) {
          localizedDate = localizedDate.replaceFirst(regex, kmMonths[i].trim());
          break;
        }
      }
    }

    if (timeStr.isNotEmpty) {
      return '$localizedDate · $timeStr';
    }
    return localizedDate;
  }

  Widget _buildAttachedEventCard(BuildContext context, EventModel event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final ctaBg = isDark ? Colors.white : Colors.black;
    final ctaText = isDark ? Colors.black : Colors.white;

    final isRsvped = event.isRsvped;

    // Handle deleted/unavailable event fallback gracefully
    if ((event.id.isEmpty && event.title.isEmpty) || event.title.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(Icons.event_busy_outlined, color: textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'community.eventUnavailable'.tr.isNotEmpty &&
                          'community.eventUnavailable'.tr != 'community.eventUnavailable'
                      ? 'community.eventUnavailable'.tr
                      : 'Event details currently unavailable',
                  style: TextStyle(color: textSecondary, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasLocalCover = event.coverImageFile != null;
    final hasNetworkCover = event.imageUrl.isNotEmpty;

    final isOnline = event.isOnline;
    final String onlineLabel = 'community.onlineEvent'.tr.isNotEmpty &&
            'community.onlineEvent'.tr != 'community.onlineEvent'
        ? 'community.onlineEvent'.tr
        : 'Online Event';
    final String inPersonLabel = 'community.inPerson'.tr.isNotEmpty &&
            'community.inPerson'.tr != 'community.inPerson'
        ? 'community.inPerson'.tr
        : 'In person';

    // In feed: do not expose raw meeting URL; use friendly online/in-person label
    final locationText = isOnline
        ? onlineLabel
        : (event.effectiveLocationName.isNotEmpty
            ? event.effectiveLocationName
            : (event.location.isNotEmpty ? event.location : inPersonLabel));

    final locationIcon = isOnline ? Icons.videocam_outlined : Icons.location_on_outlined;

    final dateTimeDisplay = _formatEventDate(event);

    final rawCat = event.category.isNotEmpty ? event.category : 'Event';
    final catKey = 'community.${rawCat.toLowerCase()}';
    final categoryDisplay = catKey.tr.isNotEmpty && catKey.tr != catKey ? catKey.tr : rawCat;

    final String joinedLabel = 'community.joined'.tr.isNotEmpty &&
            'community.joined'.tr != 'community.joined'
        ? 'community.joined'.tr
        : 'joined';
    final String newEventBadgeText = 'community.newEvent'.tr.isNotEmpty &&
            'community.newEvent'.tr != 'community.newEvent'
        ? 'community.newEvent'.tr
        : 'New Event';
    final isKhmer = Get.locale?.languageCode == 'km';
    final isAnnouncement = widget.post.isAnnouncementPost ||
        widget.post.postType?.toLowerCase() == 'announcement';
    final String eventBadgeText = isAnnouncement
        ? (isKhmer
            ? ('community.eventAnnouncementBadge'.tr.isNotEmpty &&
                    'community.eventAnnouncementBadge'.tr != 'community.eventAnnouncementBadge'
                ? 'community.eventAnnouncementBadge'.tr
                : 'សេចក្ដីប្រកាសព្រឹត្តិការណ៍')
            : 'EVENT ANNOUNCEMENT')
        : newEventBadgeText;
    final String viewEventLabel = 'community.viewEvent'.tr.isNotEmpty &&
            'community.viewEvent'.tr != 'community.viewEvent'
        ? 'community.viewEvent'.tr
        : 'View Event';

    void navigateToDetail() {
      Get.to(
        () => EventDetailsScreen(
          event: event,
          heroTag: 'post-event-${event.id}-${widget.post.id}',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderSubtle.withValues(alpha: 0.6), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: navigateToDetail,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLocalCover || hasNetworkCover)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Hero(
                        tag: 'post-event-${event.id}-${widget.post.id}',
                        child: hasLocalCover
                            ? Image.file(event.coverImageFile!, fit: BoxFit.cover)
                            : Image.network(
                                event.imageUrl,
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildMonochromeEventPlaceholder(isDark, textSecondary),
                              ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: borderSubtle.withValues(alpha: 0.8),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                eventBadgeText,
                                style: TextStyle(
                                  color: isDark ? Colors.white : textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: borderSubtle.withValues(alpha: 0.6),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                categoryDisplay.toUpperCase(),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (event.isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: borderSubtle.withValues(alpha: 0.5),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  'community.paid'.tr.isNotEmpty &&
                                          'community.paid'.tr != 'community.paid'
                                      ? 'community.paid'.tr.toUpperCase()
                                      : 'PAID',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

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

                        if (dateTimeDisplay.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
                        ],

                        if (locationText.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                        ],

                        if (event.description.trim().isNotEmpty &&
                            event.description.trim() != event.title &&
                            widget.post.content.trim() != event.description.trim()) ...[
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

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            if (event.attendeesCount > 0)
                              Expanded(
                                child: Text(
                                  '👥 ${event.attendeesCount} $joinedLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: navigateToDetail,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isRsvped
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.08))
                                      : ctaBg,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: isRsvped
                                      ? Border.all(
                                          color: borderSubtle,
                                          width: 0.8,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isRsvped) ...[
                                      Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      isRsvped
                                          ? ('community.joinedChecked'.tr.isNotEmpty &&
                                                  'community.joinedChecked'.tr !=
                                                      'community.joinedChecked'
                                              ? 'community.joinedChecked'.tr
                                              : 'Joined ✓')
                                          : viewEventLabel,
                                      style: TextStyle(
                                        color: isRsvped
                                            ? (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary)
                                            : ctaText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
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

// ─── Step 3B-Frontend: Feed video player ──────────────────────────────────────
/// Renders a network video inside a PostCard.
/// Lazy-initialized — controller created on first build, disposed on unmount.
/// Gated in PostCardWidget: only shown when [CommunityPostModel.isVideoPost] == true.
///
/// Integration note (Step 3B-Backend):
///   When backend starts returning videoUrl, [CommunityPostModel.videoUrl] will be
///   non-null and this widget will auto-render without any further PostCard changes.
class VideoPostMedia extends StatefulWidget {
  const VideoPostMedia({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoPostMedia> createState() => _VideoPostMediaState();
}

class _VideoPostMediaState extends State<VideoPostMedia> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final isNetwork = widget.videoUrl.startsWith('http://') ||
          widget.videoUrl.startsWith('https://');
      final ctrl = isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.file(File(widget.videoUrl));
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _ctrl = ctrl;
        _initialized = true;
      });
    } catch (e) {
      debugPrint('[VideoPostMedia] init error: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = _ctrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        child: AspectRatio(
          aspectRatio: (ctrl != null && _initialized) ? ctrl.value.aspectRatio : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video or background
              if (ctrl != null && _initialized)
                VideoPlayer(ctrl)
              else
                Container(
                  color: isDark ? const Color(0xFF0C0E12) : const Color(0xFFE0E0E0),
                ),

              // Loading
              if (!_initialized && !_error)
                const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),

              // Error
              if (_error)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'community.videoLoadError'.tr != 'community.videoLoadError'
                          ? 'community.videoLoadError'.tr
                          : 'Unable to play video',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ),

              // Play / pause overlay
              if (ctrl != null && _initialized)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                    }),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: ctrl.value.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0x88000000),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            ctrl.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// ──────────────────────────────────────────────────────────────────────────────
