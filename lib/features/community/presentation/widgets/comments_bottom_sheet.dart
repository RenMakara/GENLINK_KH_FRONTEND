import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
import '../screens/post_detail_screen.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final CommunityPostModel? post;
  final String? highlightCommentId;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.post,
    this.highlightCommentId,
  });

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

  CommunityPostModel? _post;
  bool _isLoadingPost = false;
  String? _highlightedCommentId;
  bool _hasScrolledToHighlight = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommunityController>();
    controller.fetchComments(widget.postId);
    _commentController.addListener(_onTextChanged);
    _post = widget.post;
    _highlightedCommentId = widget.highlightCommentId;

    if (_post == null) {
      final inMemory = controller.posts.firstWhereOrNull(
        (p) => p.id == widget.postId,
      );
      if (inMemory != null) {
        _post = inMemory;
      } else {
        _isLoadingPost = true;
        controller
            .fetchPostDetails(widget.postId)
            .then((fetched) {
              if (mounted) {
                setState(() {
                  _post = fetched;
                  _isLoadingPost = false;
                });
              }
            })
            .catchError((_) {
              if (mounted) {
                setState(() => _isLoadingPost = false);
              }
            });
      }
    }

    if (_highlightedCommentId != null) {
      _highlightTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          setState(() {
            _highlightedCommentId = null;
          });
        }
      });
    }
  }

  void _scrollToHighlightIfNeeded() {
    if (_highlightedCommentId == null || _hasScrolledToHighlight) return;
    final key = _commentKeys[_highlightedCommentId];
    if (key?.currentContext != null) {
      _hasScrolledToHighlight = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || key?.currentContext == null) return;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      });
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
    _highlightTimer?.cancel();
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
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
          title:
              'community.comments'.tr.isNotEmpty &&
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
    final surface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
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
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isCommentOwner) ...[
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: const Key('comment_option_delete'),
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      'common.delete'.tr.isNotEmpty &&
                              'common.delete'.tr != 'common.delete'
                          ? 'common.delete'.tr
                          : 'Delete',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
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
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      AppNotificationBanner.showInfo(
                        context: context,
                        title:
                            'community.reportCommentSuccess'.tr.isNotEmpty &&
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

  void _showDeleteCommentDialog(CommentModel comment) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title:
          'community.deleteComment'.tr.isNotEmpty &&
              'community.deleteComment'.tr != 'community.deleteComment'
          ? '${'community.deleteComment'.tr}?'
          : 'Delete Comment?',
      message:
          'community.deleteCommentConfirm'.tr.isNotEmpty &&
              'community.deleteCommentConfirm'.tr !=
                  'community.deleteCommentConfirm'
          ? 'community.deleteCommentConfirm'.tr
          : 'Are you sure you want to delete this comment? This action cannot be undone.',
      cancelLabel:
          'common.cancel'.tr.isNotEmpty && 'common.cancel'.tr != 'common.cancel'
          ? 'common.cancel'.tr
          : 'Cancel',
      confirmLabel:
          'common.delete'.tr.isNotEmpty && 'common.delete'.tr != 'common.delete'
          ? 'common.delete'.tr
          : 'Delete',
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await controller.deleteComment(widget.postId, comment.id);
      if (success && mounted) {
        if (_replyingToComment?.id == comment.id) {
          setState(() {
            _replyingToComment = null;
          });
        }
        AppNotificationBanner.showSuccess(
          context: context,
          title:
              'community.commentDeleted'.tr.isNotEmpty &&
                  'community.commentDeleted'.tr != 'community.commentDeleted'
              ? 'community.commentDeleted'.tr
              : 'Deleted',
          message: 'Comment deleted successfully.',
        );
      } else if (mounted) {
        AppNotificationBanner.showError(
          context: context,
          title: 'Error',
          message: 'Failed to delete comment. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to delete comment. Please try again.';
        if (e is AppError && e.isForbidden) {
          errorMsg =
              'community.commentPermissionError'.tr.isNotEmpty &&
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
                  style:
                      theme.textTheme.titleMedium?.copyWith(
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
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderSubtle),
          _buildOriginalPostPreview(
            context,
            isDark,
            textPrimary,
            textSecondary,
            textMuted,
            surfaceSecondary,
            borderSubtle,
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoadingComments.value &&
                  controller.activeComments.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.communityAccent,
                  ),
                );
              }
              if (controller.activeComments.isEmpty) {
                if (controller.commentsErrorMessage.value.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 40,
                            color: textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.commentsErrorMessage.value,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                controller.fetchComments(widget.postId),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
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
                                  'community.noCommentsYet'.tr !=
                                      'community.noCommentsYet'
                              ? 'community.noCommentsYet'.tr
                              : 'No comments yet. Be the first to start the discussion!',
                          style: TextStyle(color: textMuted, fontSize: 13),
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
                if (c.parentCommentId == null || c.parentCommentId!.isEmpty) {
                  return true;
                }
                final hasParent = allComments.any(
                  (p) => p.id == c.parentCommentId,
                );
                return !hasParent;
              }).toList();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToHighlightIfNeeded();
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount:
                    topLevelComments.length +
                    (controller.commentsErrorMessage.value.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (controller.commentsErrorMessage.value.isNotEmpty &&
                      index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.commentsErrorMessage.value,
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                controller.fetchComments(widget.postId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final commentIndex =
                      index -
                      (controller.commentsErrorMessage.value.isNotEmpty
                          ? 1
                          : 0);
                  final comment = topLevelComments[commentIndex];
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
                border: Border(
                  top: BorderSide(color: borderSubtle, width: 0.8),
                ),
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
                                    text:
                                        'community.replyingTo'.tr.isNotEmpty &&
                                            'community.replyingTo'.tr !=
                                                'community.replyingTo'
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
                                            'community.reply'.tr !=
                                                'community.reply'
                                        ? '${'community.reply'.tr} ${_replyingToComment!.userName}...'
                                        : 'Reply to ${_replyingToComment!.userName}...')
                                  : ('community.writeCommentHint'
                                                .tr
                                                .isNotEmpty &&
                                            'community.writeCommentHint'.tr !=
                                                'community.writeCommentHint'
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                borderSide: BorderSide(
                                  color: borderSubtle,
                                  width: 0.8,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                borderSide: BorderSide(
                                  color: borderSubtle,
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
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
                            tooltip:
                                'community.send'.tr.isNotEmpty &&
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
    final currentUserId =
        controller.currentUserId ??
        (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    final isCommentOwner = comment.checkIsOwner(currentUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final commentKey = _commentKeys.putIfAbsent(comment.id, () => GlobalKey());
    final isHighlighted = _highlightedCommentId == comment.id;

    return Padding(
      key: commentKey,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: comment.userAvatar,
                name: comment.userName,
                size: 30,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.communityAccent.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          )
                        : surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isHighlighted
                          ? AppColors.communityAccent
                          : borderSubtle,
                      width: isHighlighted ? 1.5 : 0.8,
                    ),
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
                                  comment.createdAt ?? comment.timeAgo,
                                ),
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
                                onTap: () => _showCommentOptions(
                                  comment,
                                  isCommentOwner,
                                ),
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
                                          'community.reply'.tr !=
                                              'community.reply'
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
                    .map(
                      (reply) => _buildReplyItem(
                        context,
                        reply,
                        comment,
                        surfaceSecondary,
                        borderSubtle,
                        textPrimary,
                        textSecondary,
                        textMuted,
                      ),
                    )
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
    final currentUserId =
        controller.currentUserId ??
        (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    final isReplyOwner = reply.checkIsOwner(currentUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final replyKey = _commentKeys.putIfAbsent(reply.id, () => GlobalKey());
    final isHighlighted = _highlightedCommentId == reply.id;

    return Padding(
      key: replyKey,
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: reply.userAvatar,
                name: reply.userName,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm - 2),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.communityAccent.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          )
                        : surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isHighlighted
                          ? AppColors.communityAccent
                          : borderSubtle,
                      width: isHighlighted ? 1.5 : 0.8,
                    ),
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
                                  reply.createdAt ?? reply.timeAgo,
                                ),
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
                                          'community.reply'.tr !=
                                              'community.reply'
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
                    .map(
                      (nested) => _buildReplyItem(
                        context,
                        nested,
                        parentComment,
                        surfaceSecondary,
                        borderSubtle,
                        textPrimary,
                        textSecondary,
                        textMuted,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalPostPreview(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color surfaceSecondary,
    Color borderSubtle,
  ) {
    final post = _post;
    if (post == null) {
      if (_isLoadingPost) {
        return Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorderSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 160,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorderSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final hasImages = post.imageUrls.isNotEmpty;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    final mediaThumb = hasImages
        ? post.imageUrls.first
        : (hasVideo
              ? post.videoUrl!
              : (post.mediaUrls?.isNotEmpty == true
                    ? post.mediaUrls!.first
                    : null));
    final isVideo =
        hasVideo ||
        (mediaThumb != null && CommunityPostModel.isVideoUrl(mediaThumb));

    return InkWell(
      key: const ValueKey('comments_sheet_original_post_preview'),
      onTap: () {
        Navigator.pop(context);
        if (Get.currentRoute != AppRoutes.postDetail) {
          Get.to<void>(
            () => PostDetailScreen(postId: widget.postId, initialPost: _post),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceSecondary
              : AppColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
            width: 0.9,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(
                  imageUrl: post.authorAvatar,
                  name: post.authorName,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.timeAgo.isNotEmpty) ...[
                            Text(
                              ' · ',
                              style: TextStyle(color: textMuted, fontSize: 11),
                            ),
                            Text(
                              post.timeAgo,
                              style: TextStyle(color: textMuted, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      if (post.authorTag.isNotEmpty)
                        Text(
                          '@${post.authorTag}',
                          style: TextStyle(color: textMuted, fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 11, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'community.originalPost'.tr.isNotEmpty &&
                                'community.originalPost'.tr !=
                                    'community.originalPost'
                            ? 'community.originalPost'.tr
                            : 'Original Post',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.content.isNotEmpty || mediaThumb != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.content.isEmpty
                          ? (mediaThumb != null ? '[Media]' : '')
                          : post.content,
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (mediaThumb != null && mediaThumb.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppCachedImage(
                              imageUrl: mediaThumb,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 20,
                                  color: textMuted,
                                ),
                              ),
                            ),
                            if (isVideo)
                              Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
