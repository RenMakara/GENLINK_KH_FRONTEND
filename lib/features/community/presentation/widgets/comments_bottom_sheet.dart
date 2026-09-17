import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final CommunityController controller;
  CommentModel? _replyingToComment;
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommunityController>();
    controller.fetchComments(widget.postId);
    _commentController.addListener(_onTextChanged);
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
    _focusNode.dispose();
    super.dispose();
  }

  void _onReplyTo(CommentModel comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
  }

  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final parentId = _replyingToComment?.id;
    try {
      final newComment = await controller.addComment(
        widget.postId,
        text,
        parentCommentId: parentId,
      );
      if (newComment != null && mounted) {
        _commentController.clear();
        setState(() {
          _replyingToComment = null;
          _hasText = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'community.comments'.tr.isNotEmpty &&
                  'community.comments'.tr != 'community.comments'
              ? 'community.comments'.tr
              : 'Comments',
          message: e is AppError
              ? e.message
              : 'Failed to post comment. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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
                        final success = await controller.deleteComment(
                          widget.postId,
                          comment.id,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (success && mounted) {
                          if (_replyingToComment?.id == comment.id) {
                            setState(() {
                              _replyingToComment = null;
                            });
                          }
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

  @override
  Widget build(BuildContext context) {
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
    final surfacePrimary = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final canSend = _hasText && !_isSending;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBorderStrong
                  : AppColors.lightBorderStrong,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'community.comments'.tr.isNotEmpty &&
                          'community.comments'.tr != 'community.comments'
                      ? 'community.comments'.tr
                      : 'Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderSubtle),

          Expanded(
            child: Obx(() {
              if (controller.isLoadingComments.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.communityAccent,
                  ),
                );
              }
              if (controller.activeComments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'community.noCommentsYet'.tr.isNotEmpty &&
                                  'community.noCommentsYet'.tr != 'community.noCommentsYet'
                              ? 'community.noCommentsYet'.tr
                              : 'No comments yet. Be the first to start the discussion!',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Top-level comments and nested replies
              final allComments = controller.activeComments;
              final topLevelComments = allComments.where((c) {
                if (c.parentCommentId == null || c.parentCommentId!.isEmpty) return true;
                final hasParent = allComments.any((p) => p.id == c.parentCommentId);
                return !hasParent;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: topLevelComments.length,
                itemBuilder: (context, index) {
                  final comment = topLevelComments[index];
                  final directReplies = allComments
                      .where((c) => c.parentCommentId == comment.id)
                      .toList();
                  final combinedReplies = [
                    ...comment.replies,
                    ...directReplies.where(
                      (dr) => !comment.replies.any((r) => r.id == dr.id),
                    ),
                  ];

                  return _buildCommentItem(
                    context,
                    comment,
                    combinedReplies,
                    surfaceSecondary,
                    borderSubtle,
                    textPrimary,
                    textSecondary,
                    textMuted,
                  );
                },
              );
            }),
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
                                        ? '${'community.replyingTo'.tr.replaceAll('@user', '').trim()} '
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
                            onTap: _cancelReply,
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
                            focusNode: _focusNode,
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
                                  : ('community.writeCommentHint'.tr.isNotEmpty &&
                                          'community.writeCommentHint'.tr != 'community.writeCommentHint'
                                      ? 'community.writeCommentHint'.tr
                                      : 'Write a comment...'),
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
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: _isSending
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
                        ),
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

  Widget _buildCommentItem(
    BuildContext context,
    CommentModel comment,
    List<CommentModel> replies,
    Color surfaceSecondary,
    Color borderSubtle,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final hasAvatar = comment.userAvatar.isNotEmpty;
    final currentUserId = controller.currentUserId ??
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
                            onTap: () => controller.toggleCommentLike(
                              widget.postId,
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
                            onTap: () => _onReplyTo(comment),
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
          if (replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Column(
                children: replies
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
    final currentUserId = controller.currentUserId ??
        (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    final isReplyOwner = reply.checkIsOwner(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                                size: 14,
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
                        onTap: () => controller.toggleCommentLike(
                          widget.postId,
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
                        onTap: () => _onReplyTo(parentComment),
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
        if (reply.replies.isNotEmpty) ...[
          Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Column(
                children: reply.replies
                    .map((nested) => _buildReplyItem(
                          context,
                          nested,
                          parentComment,
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
}
