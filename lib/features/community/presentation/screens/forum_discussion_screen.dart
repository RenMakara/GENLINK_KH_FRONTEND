import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_design_tokens.dart';
import 'create_discussion_screen.dart';

class ForumDiscussionScreen extends StatefulWidget {
  final ForumTopicModel discussion;

  const ForumDiscussionScreen({super.key, required this.discussion});

  @override
  State<ForumDiscussionScreen> createState() => _ForumDiscussionScreenState();
}

class _ForumDiscussionScreenState extends State<ForumDiscussionScreen> {
  late final CommunityController _controller;
  late final TextEditingController _commentController;
  final FocusNode _commentFocusNode = FocusNode();
  CommentModel? _replyingToComment;
  late ForumTopicModel _discussion;
  late int _repliesCount;
  late int _upvotes;
  late bool _isLiked;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _discussion = widget.discussion;
    _repliesCount = _discussion.repliesCount;
    _upvotes = _discussion.upvotes;
    _isLiked = _discussion.isLiked;
    _commentController = TextEditingController();
    _commentController.addListener(_onTextChanged);

    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
    } else {
      _controller = Get.put(CommunityController());
    }

    _controller.fetchDiscussionComments(_discussion.id);
    _loadDiscussionDetail();
  }

  Future<void> _loadDiscussionDetail() async {
    final detail = await _controller.fetchDiscussionDetails(_discussion.id);
    if (detail != null && mounted) {
      setState(() {
        _discussion = detail;
        _repliesCount = detail.repliesCount;
        _upvotes = detail.upvotes;
        _isLiked = detail.isLiked;
      });
    }
  }

  void _handleLikeTap() async {
    if (_controller.inFlightDiscussionLikes.contains(_discussion.id)) return;
    setState(() {
      _isLiked = !_isLiked;
      _upvotes += _isLiked ? 1 : -1;
    });
    final success = await _controller.toggleDiscussionLike(_discussion.id);
    if (!success && mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _upvotes += _isLiked ? 1 : -1;
      });
      AppNotificationBanner.showError(
        context: context,
        title: 'Error',
        message: 'Failed to update reaction. Please try again.',
      );
    }
  }

  void _onTextChanged() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _controller.isSendingDiscussionComment.value) return;

    final parentId = _replyingToComment?.id;

    try {
      final newComment = await _controller.addDiscussionComment(
        _discussion.id,
        text,
        parentCommentId: parentId,
      );

      if (newComment != null && mounted) {
        _commentController.clear();
        setState(() {
          _replyingToComment = null;
          _repliesCount++;
        });
      } else if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'Error',
          message: 'Failed to post comment. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'Error',
          message: 'Failed to post comment. Please try again.',
        );
      }
    }
  }

  void _showOptionsSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final isOwner = _discussion.checkIsOwner(_controller.currentUserId);

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
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isOwner) ...[
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
                  onTap: () async {
                    Get.back();
                    final updated = await Get.to(() => CreateDiscussionScreen(
                          initialDiscussion: _discussion,
                        ));
                    if (updated == true && mounted) {
                      final refreshed =
                          _controller.getDiscussionById(_discussion.id);
                      if (refreshed != null) {
                        setState(() {
                          _discussion = refreshed;
                        });
                      } else {
                        await _loadDiscussionDetail();
                      }
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
                    _showDeleteDialog();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.bookmark_border_rounded,
                      color: textPrimary, size: 22),
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
                  leading: const Icon(Icons.report_outlined,
                      color: AppColors.danger, size: 22),
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
                    final ok = await _controller.reportDiscussion(_discussion.id);
                    if (mounted && context.mounted) {
                      if (ok) {
                        AppNotificationBanner.showSuccess(
                          context: context,
                          title: 'community.reported'.tr.isNotEmpty &&
                                  'community.reported'.tr != 'community.reported'
                              ? 'community.reported'.tr
                              : 'Reported',
                          message:
                              'Thank you for reporting. Our team will review it.',
                        );
                      } else {
                        AppNotificationBanner.showError(
                          context: context,
                          title: 'Error',
                          message: 'Failed to report discussion. Please try again.',
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
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

  void _showDeleteDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
              try {
                final success = await _controller.deleteDiscussion(_discussion.id);
                if (success) {
                  Get.back();
                  if (Get.context != null) {
                    AppNotificationBanner.showSuccess(
                      context: Get.context!,
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
                } else if (mounted && context.mounted) {
                  AppNotificationBanner.showError(
                    context: context,
                    title: 'Error',
                    message: 'Failed to delete discussion. Please try again.',
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  String errorMsg = 'Failed to delete discussion. Please try again.';
                  if (e is AppError) {
                    if (e.isForbidden) {
                      errorMsg = 'You do not have permission to delete this discussion.';
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
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 72,
        title: Text(
          'community.discussion'.tr.isNotEmpty &&
                  'community.discussion'.tr != 'community.discussion'
              ? 'community.discussion'.tr
              : 'Discussion',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: textPrimary),
            onPressed: _showOptionsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (_discussion.authorAvatar.isNotEmpty)
                            ? (_discussion.authorAvatar.startsWith('assets/')
                                ? AssetImage(_discussion.authorAvatar) as ImageProvider
                                : NetworkImage(_discussion.authorAvatar))
                            : null,
                        backgroundColor: AppColors.communityAccent.withValues(
                          alpha: 0.15,
                        ),
                        child: _discussion.authorAvatar.isEmpty
                            ? Text(
                                _discussion.authorName.isNotEmpty
                                    ? (_discussion.authorName.startsWith('@') &&
                                            _discussion.authorName.length > 1
                                        ? _discussion.authorName
                                            .substring(1, 2)
                                            .toUpperCase()
                                        : _discussion.authorName
                                            .substring(0, 1)
                                            .toUpperCase())
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.communityAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _discussion.authorName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ) ??
                                  TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              formatCommunityTimestamp(
                                  _discussion.createdAt ?? _discussion.timeAgo),
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: textMuted,
                                    fontSize: 11.5,
                                  ) ??
                                  TextStyle(
                                    color: textMuted,
                                    fontSize: 11.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      CommunityCategoryBadge(
                        label: _discussion.category,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md + 2),

                  Text(
                    _discussion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.5,
                      height: 1.35,
                    ) ?? TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.5,
                      height: 1.35,
                    ),
                  ),
                  if (_discussion.content.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    Text(
                      _discussion.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.55,
                        fontSize: 14.5,
                      ) ?? TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.55,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: InkWell(
                          onTap: _handleLikeTap,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: _isLiked
                                      ? AppColors.likedAccent
                                      : textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$_upvotes',
                                  style: TextStyle(
                                    color: _isLiked
                                        ? (isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary)
                                        : textSecondary,
                                    fontWeight: _isLiked
                                        ? FontWeight.w700
                                        : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$_repliesCount',
                              style: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: AppSpacing.md + 2),

                  Text(
                    'community.comments'.tr.isNotEmpty &&
                            'community.comments'.tr != 'community.comments'
                        ? 'community.comments'.tr
                        : 'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ) ?? TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Obx(() {
                    final comments = _controller
                        .getCommentsForDiscussion(_discussion.id);
                    final isLoading =
                        _controller.isLoadingDiscussionComments.value;

                    if (isLoading && comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.communityAccent,
                          ),
                        ),
                      );
                    }

                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: textMuted.withValues(alpha: 0.5),
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'community.noCommentsYet'.tr.isNotEmpty &&
                                        'community.noCommentsYet'.tr != 'community.noCommentsYet'
                                    ? 'community.noCommentsYet'.tr
                                    : 'No comments yet',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'community.firstToStartDiscussion'.tr.isNotEmpty &&
                                        'community.firstToStartDiscussion'.tr != 'community.firstToStartDiscussion'
                                    ? 'community.firstToStartDiscussion'.tr
                                    : 'Be the first to start the discussion!',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: comments.map((c) => _buildCommentItem(
                            context,
                            c,
                            surfaceSecondary,
                            borderSubtle,
                            textPrimary,
                            textSecondary,
                            textMuted,
                          )).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceSecondary,
                border: Border(top: BorderSide(color: borderSubtle, width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToComment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.lightBgSecondary,
                        border: Border(
                          bottom: BorderSide(color: borderSubtle, width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: AppColors.communityAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'community.replyingTo'.tr.isNotEmpty &&
                                            'community.replyingTo'.tr != 'community.replyingTo'
                                        ? '${'community.replyingTo'.tr} '
                                        : 'Replying to ',
                                  ),
                                  TextSpan(
                                    text: _replyingToComment!.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            key: const Key('cancel_reply_button'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _replyingToComment = null;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? AppSpacing.sm
                          : AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _commentFocusNode,
                            controller: _commentController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSendComment(),
                            onChanged: (_) => _onTextChanged(),
                            cursorColor: textPrimary,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14.5,
                              height: 1.3,
                            ),
                            decoration: InputDecoration(
                              hintText: _replyingToComment != null
                                  ? ('community.reply'.tr.isNotEmpty &&
                                          'community.reply'.tr != 'community.reply'
                                      ? '${'community.reply'.tr} ${_replyingToComment!.userName}...'
                                      : 'Reply to ${_replyingToComment!.userName}...')
                                  : ('community.addReply'.tr.isNotEmpty &&
                                          'community.addReply'.tr != 'community.addReply'
                                      ? 'community.addReply'.tr
                                      : 'Add a reply...'),
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 14.5,
                                height: 1.3,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkBgPrimary
                                  : AppColors.lightBgSecondary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(color: borderSubtle, width: 0.8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(color: borderSubtle, width: 0.8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorderStrong
                                      : AppColors.lightBorderStrong,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final isSending =
                              _controller.isSendingDiscussionComment.value;
                          final canSend = _hasText && !isSending;

                          return SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              icon: isSending
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: textPrimary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: canSend ? textPrimary : textMuted,
                                      size: 21,
                                    ),
                              onPressed: canSend ? _handleSendComment : null,
                              tooltip: 'community.send'.tr.isNotEmpty &&
                                      'community.send'.tr != 'community.send'
                                  ? 'community.send'.tr
                                  : 'Send',
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(CommentModel comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'community.deleteComment'.tr.isNotEmpty &&
                    'community.deleteComment'.tr != 'community.deleteComment'
                ? '${'community.deleteComment'.tr}?'
                : 'Delete Comment?',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'community.deleteCommentConfirm'.tr.isNotEmpty &&
                    'community.deleteCommentConfirm'.tr !=
                        'community.deleteCommentConfirm'
                ? 'community.deleteCommentConfirm'.tr
                : 'Are you sure you want to delete this comment? This action cannot be undone.',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text(
                'common.cancel'.tr.isNotEmpty &&
                        'common.cancel'.tr != 'common.cancel'
                    ? 'common.cancel'.tr
                    : 'Cancel',
                style: TextStyle(
                  color: isDeleting
                      ? textSecondary.withValues(alpha: 0.5)
                      : textSecondary,
                ),
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
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() {
                        isDeleting = true;
                      });
                      try {
                        final success =
                            await _controller.deleteDiscussionComment(
                          _discussion.id,
                          comment.id,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (success && mounted) {
                          setState(() {
                            if (_repliesCount > 0) _repliesCount--;
                          });
                          AppNotificationBanner.showSuccess(
                            context: context,
                            title: 'community.commentDeleted'.tr.isNotEmpty &&
                                    'community.commentDeleted'.tr !=
                                        'community.commentDeleted'
                                ? 'community.commentDeleted'.tr
                                : 'Deleted',
                            message: 'Comment deleted successfully.',
                          );
                        } else if (mounted) {
                          AppNotificationBanner.showError(
                            context: context,
                            title: 'Error',
                            message:
                                'Failed to delete comment. Please try again.',
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          String errorMsg =
                              'Failed to delete comment. Please try again.';
                          if (e is AppError && e.isForbidden) {
                            errorMsg = 'community.commentPermissionError'.tr.isNotEmpty &&
                                    'community.commentPermissionError'.tr !=
                                        'community.commentPermissionError'
                                ? 'community.commentPermissionError'.tr
                                : 'You do not have permission to modify this comment.';
                          } else if (e is AppError && e.message.isNotEmpty) {
                            errorMsg = e.message;
                          }
                          AppNotificationBanner.showError(
                            context: context,
                            title: 'Error',
                            message: errorMsg,
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'common.delete'.tr.isNotEmpty &&
                              'common.delete'.tr != 'common.delete'
                          ? 'common.delete'.tr
                          : 'Delete',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCommentDialog(CommentModel comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final primaryBtnBg =
        isDark ? Colors.white : AppColors.lightTextPrimary;
    final primaryBtnFg =
        isDark ? Colors.black : Colors.white;

    final textController = TextEditingController(text: comment.text);
    bool isSaving = false;
    String? validationError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'community.editComment'.tr.isNotEmpty &&
                    'community.editComment'.tr != 'community.editComment'
                ? 'community.editComment'.tr
                : 'Edit Comment',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                enabled: !isSaving,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'community.editCommentHint'.tr.isNotEmpty &&
                          'community.editCommentHint'.tr !=
                              'community.editCommentHint'
                      ? 'community.editCommentHint'.tr
                      : 'Write a comment...',
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() {
                      validationError = null;
                    });
                  }
                },
              ),
              if (validationError != null) ...[
                const SizedBox(height: 6),
                Text(
                  validationError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(
                'common.cancel'.tr.isNotEmpty &&
                        'common.cancel'.tr != 'common.cancel'
                    ? 'common.cancel'.tr
                    : 'Cancel',
                style: TextStyle(
                  color: isSaving
                      ? textSecondary.withValues(alpha: 0.5)
                      : textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnBg,
                foregroundColor: primaryBtnFg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final newText = textController.text.trim();
                      if (newText.isEmpty) {
                        setDialogState(() {
                          validationError = 'common.required'.tr.isNotEmpty &&
                                  'common.required'.tr != 'common.required'
                              ? 'common.required'.tr
                              : 'This field is required';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                        validationError = null;
                      });

                      try {
                        final updated =
                            await _controller.updateDiscussionComment(
                          _discussion.id,
                          comment.id,
                          newText,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (updated != null && mounted) {
                          setState(() {});
                          AppNotificationBanner.showSuccess(
                            context: context,
                            title: 'community.commentEdited'.tr.isNotEmpty &&
                                    'community.commentEdited'.tr !=
                                        'community.commentEdited'
                                ? 'community.commentEdited'.tr
                                : 'Comment updated',
                            message: 'Comment updated successfully.',
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                        });
                        if (mounted) {
                          String errorMsg =
                              'Failed to update comment. Please try again.';
                          if (e is AppError && e.isForbidden) {
                            errorMsg = 'community.commentPermissionError'.tr.isNotEmpty &&
                                    'community.commentPermissionError'.tr !=
                                        'community.commentPermissionError'
                                ? 'community.commentPermissionError'.tr
                                : 'You do not have permission to modify this comment.';
                          } else if (e is AppError && e.message.isNotEmpty) {
                            errorMsg = e.message;
                          }
                          AppNotificationBanner.showError(
                            context: context,
                            title: 'Error',
                            message: errorMsg,
                          );
                        }
                      }
                    },
              child: isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryBtnFg,
                      ),
                    )
                  : Text(
                      'common.save'.tr.isNotEmpty &&
                              'common.save'.tr != 'common.save'
                          ? 'common.save'.tr
                          : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentOptions(CommentModel comment, bool isCommentOwner) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isCommentOwner) ...[
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: const Key('comment_option_edit'),
                    leading: Icon(Icons.edit_outlined, color: textPrimary),
                    title: Text(
                      'common.edit'.tr.isNotEmpty &&
                              'common.edit'.tr != 'common.edit'
                          ? 'common.edit'.tr
                          : 'Edit',
                      style: TextStyle(
                          color: textPrimary, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditCommentDialog(comment);
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: const Key('comment_option_delete'),
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                    title: Text(
                      'common.delete'.tr.isNotEmpty &&
                              'common.delete'.tr != 'common.delete'
                          ? 'common.delete'.tr
                          : 'Delete',
                      style: const TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDeleteCommentDialog(comment);
                    },
                  ),
                ),
              ] else ...[
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: const Key('comment_option_report'),
                    leading: Icon(Icons.flag_outlined, color: textPrimary),
                    title: Text(
                      'community.reportComment'.tr.isNotEmpty &&
                              'community.reportComment'.tr !=
                                  'community.reportComment'
                          ? 'community.reportComment'.tr
                          : 'Report',
                      style: TextStyle(
                          color: textPrimary, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      AppNotificationBanner.showInfo(
                        context: context,
                        title: 'community.reportCommentSuccess'.tr.isNotEmpty &&
                                'community.reportCommentSuccess'.tr !=
                                    'community.reportCommentSuccess'
                            ? 'community.reportCommentSuccess'.tr
                            : 'Reported',
                        message: 'Thank you for reporting this comment.',
                        icon: Icons.flag_rounded,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentModel comment,
    Color surfaceSecondary,
    Color borderSubtle,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final hasAvatar = comment.userAvatar.isNotEmpty;
    final currentUserId = _controller.currentUserId ??
        (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    final isCommentOwner = comment.checkIsOwner(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: hasAvatar
                    ? (comment.userAvatar.startsWith('assets/')
                        ? AssetImage(comment.userAvatar) as ImageProvider
                        : NetworkImage(comment.userAvatar))
                    : null,
                backgroundColor: AppColors.communityAccent.withValues(alpha: 0.15),
                child: !hasAvatar
                    ? Text(
                        comment.userName.isNotEmpty
                            ? (comment.userName.startsWith('@') &&
                                    comment.userName.length > 1
                                ? comment.userName.substring(1, 2).toUpperCase()
                                : comment.userName.substring(0, 1).toUpperCase())
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.communityAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderSubtle, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              comment.userName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCommunityTimestamp(
                                    comment.createdAt ?? comment.timeAgo),
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              if (comment.isEdited) ...[
                                Text(
                                  ' · ${'community.edited'.tr.isNotEmpty && 'community.edited'.tr != 'community.edited' ? 'community.edited'.tr : 'Edited'}',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              GestureDetector(
                                key: Key('comment_more_${comment.id}'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    _showCommentOptions(comment, isCommentOwner),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.more_horiz_rounded,
                                    size: 16,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        comment.text,
                        style: TextStyle(
                          color: textPrimary.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _controller.toggleDiscussionCommentLike(
                              _discussion.id,
                              comment.id,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  comment.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 14,
                                  color: comment.isLiked
                                      ? AppColors.likedAccent
                                      : textMuted,
                                ),
                                if (comment.likesCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.likesCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: comment.isLiked
                                          ? AppColors.likedAccent
                                          : textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            key: Key('comment_reply_${comment.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _replyingToComment = comment;
                              });
                              _commentFocusNode.requestFocus();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 14,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'community.reply'.tr.isNotEmpty &&
                                          'community.reply'.tr != 'community.reply'
                                      ? 'community.reply'.tr
                                      : 'Reply',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildReplyItem(
                          context,
                          reply,
                          comment,
                          surfaceSecondary,
                          borderSubtle,
                          textPrimary,
                          textSecondary,
                          textMuted,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(
    BuildContext context,
    CommentModel reply,
    CommentModel parentComment,
    Color surfaceSecondary,
    Color borderSubtle,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final hasAvatar = reply.userAvatar.isNotEmpty;
    final currentUserId = _controller.currentUserId ??
        (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    final isReplyOwner = reply.checkIsOwner(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: hasAvatar
                ? (reply.userAvatar.startsWith('assets/')
                    ? AssetImage(reply.userAvatar) as ImageProvider
                    : NetworkImage(reply.userAvatar))
                : null,
            backgroundColor: AppColors.communityAccent.withValues(alpha: 0.15),
            child: !hasAvatar
                ? Text(
                    reply.userName.isNotEmpty
                        ? (reply.userName.startsWith('@') &&
                                reply.userName.length > 1
                            ? reply.userName.substring(1, 2).toUpperCase()
                            : reply.userName.substring(0, 1).toUpperCase())
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.communityAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm - 2),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          reply.userName,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCommunityTimestamp(
                                reply.createdAt ?? reply.timeAgo),
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                          if (reply.isEdited) ...[
                            Text(
                              ' · ${'community.edited'.tr.isNotEmpty && 'community.edited'.tr != 'community.edited' ? 'community.edited'.tr : 'Edited'}',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          GestureDetector(
                            key: Key('comment_more_${reply.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _showCommentOptions(reply, isReplyOwner),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 15,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reply.text,
                    style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _controller.toggleDiscussionCommentLike(
                          _discussion.id,
                          reply.id,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              reply.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 13,
                              color: reply.isLiked
                                  ? AppColors.likedAccent
                                  : textMuted,
                            ),
                            if (reply.likesCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${reply.likesCount}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: reply.isLiked
                                      ? AppColors.likedAccent
                                      : textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        key: Key('comment_reply_${reply.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _replyingToComment = parentComment;
                          });
                          _commentFocusNode.requestFocus();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 13,
                              color: textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'community.reply'.tr.isNotEmpty &&
                                      'community.reply'.tr != 'community.reply'
                                  ? 'community.reply'.tr
                                  : 'Reply',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
