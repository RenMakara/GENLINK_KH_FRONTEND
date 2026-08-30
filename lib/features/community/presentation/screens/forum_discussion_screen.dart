import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';

class ForumDiscussionScreen extends StatefulWidget {
  final ForumTopicModel discussion;

  const ForumDiscussionScreen({super.key, required this.discussion});

  @override
  State<ForumDiscussionScreen> createState() => _ForumDiscussionScreenState();
}

class _ForumDiscussionScreenState extends State<ForumDiscussionScreen> {
  late final CommunityController _controller;
  late final TextEditingController _commentController;
  late int _repliesCount;
  late int _upvotes;
  late bool _isLiked;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _repliesCount = widget.discussion.repliesCount;
    _upvotes = widget.discussion.upvotes;
    _isLiked = widget.discussion.isLiked;
    _commentController = TextEditingController();
    _commentController.addListener(_onTextChanged);

    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
    } else {
      _controller = Get.put(CommunityController());
    }

    _controller.fetchDiscussionComments(widget.discussion.id);
  }

  void _handleLikeTap() {
    setState(() {
      _isLiked = !_isLiked;
      _upvotes += _isLiked ? 1 : -1;
    });
    _controller.toggleDiscussionLike(widget.discussion.id);
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
        widget.discussion.id,
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
          'Discussion',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                          widget.discussion.authorName.isNotEmpty
                              ? (widget.discussion.authorName.startsWith('@') &&
                                      widget.discussion.authorName.length > 1
                                  ? widget.discussion.authorName
                                      .substring(1, 2)
                                      .toUpperCase()
                                  : widget.discussion.authorName
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
                              widget.discussion.authorName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.discussion.timeAgo,
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
                          widget.discussion.category,
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
                    widget.discussion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.discussion.content,
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
