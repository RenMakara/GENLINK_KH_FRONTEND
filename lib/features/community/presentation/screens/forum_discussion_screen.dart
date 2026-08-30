import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';
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
  }

  void _handleLikeTap() {
    setState(() {
      _isLiked = !_isLiked;
      _upvotes += _isLiked ? 1 : -1;
    });
    _controller.toggleDiscussionLike(_discussion.id);
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
    super.dispose();
  }

  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _controller.isSendingDiscussionComment.value) return;

    try {
      final newComment = await _controller.addDiscussionComment(
        _discussion.id,
        text,
      );

      if (newComment != null) {
        _commentController.clear();
        setState(() {
          _repliesCount++;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to post comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showOptionsSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2228) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white70 : AppColors.lightTextSecondary;
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
                  color: isDark ? Colors.white24 : Colors.black12,
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
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
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
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.communityAccent.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
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
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _discussion.authorName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _discussion.timeAgo,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Text(
                          _discussion.category,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title & Content
                  Text(
                    _discussion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _discussion.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textPrimary.withValues(alpha: 0.9),
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Actions (Like & Comment Counts)
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
                                      ? AppColors.danger
                                      : textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_repliesCount',
                              style: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: AppSpacing.lg),

                  // Comments Section
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() {
                    final comments = _controller
                        .getCommentsForDiscussion(widget.discussion.id);
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
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to start the discussion!',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
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
                          )).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Reply Input
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                border: Border(top: BorderSide(color: borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendComment(),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a reply...',
                        hintStyle:
                            TextStyle(color: textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.communityAccent,
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

                    return IconButton(
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: canSend
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              size: 20,
                            ),
                      onPressed: canSend ? _handleSendComment : null,
                    );
                  }),
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
    Color surfaceSecondary,
    Color borderSubtle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: surfaceSecondary,
            child: Text(
              comment.userName.isNotEmpty
                  ? (comment.userName.startsWith('@') &&
                          comment.userName.length > 1
                      ? comment.userName.substring(1, 2).toUpperCase()
                      : comment.userName.substring(0, 1).toUpperCase())
                  : 'U',
              style: const TextStyle(
                color: AppColors.communityAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.9),
                      fontSize: 13,
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
}
