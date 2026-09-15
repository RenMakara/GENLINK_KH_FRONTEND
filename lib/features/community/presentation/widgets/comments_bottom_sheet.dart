import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
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
  String? _replyingToUser;
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommunityController>();
    controller.fetchComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onReplyTo(String userName, {String? commentId}) {
    setState(() {
      _replyingToUser = userName;
      _replyingToCommentId = commentId;
      _commentController.text = "@$userName ";
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToUser = null;
      _replyingToCommentId = null;
      _commentController.clear();
    });
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
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
              borderRadius: BorderRadius.circular(AppRadius.pill),
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
                  'community.comments'.tr,
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textSecondary),
                  onPressed: () => Navigator.pop(context),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: textMuted.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'community.noCommentsYet'.tr.isNotEmpty &&
                                'community.noCommentsYet'.tr != 'community.noCommentsYet'
                            ? 'community.noCommentsYet'.tr
                            : 'No comments yet',
                        style: theme.textTheme.titleSmall?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ) ??
                            TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'community.beFirstComment'.tr.isNotEmpty &&
                                'community.beFirstComment'.tr != 'community.beFirstComment'
                            ? 'community.beFirstComment'.tr
                            : 'Be the first to comment.',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: textMuted,
                              fontSize: 13,
                            ) ??
                            TextStyle(color: textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: controller.activeComments.length,
                itemBuilder: (context, index) {
                  final comment = controller.activeComments[index];
                  final initial = comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : 'U';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.communityAccent.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage:
                              (comment.userAvatar.isNotEmpty &&
                                  comment.userAvatar.startsWith('http'))
                              ? NetworkImage(comment.userAvatar)
                              : null,
                          child:
                              (comment.userAvatar.isEmpty ||
                                  !comment.userAvatar.startsWith('http'))
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppColors.communityAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: surfaceSecondary,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(color: borderSubtle, width: 0.8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final formattedTime =
                                            formatCommunityTimestamp(
                                          comment.createdAt ?? comment.timeAgo,
                                        );
                                        return Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: comment.userName,
                                                style: theme.textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color: textPrimary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ) ??
                                                    TextStyle(
                                                      color: textPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                              if (formattedTime.isNotEmpty)
                                                TextSpan(
                                                  text: ' · $formattedTime',
                                                  style: theme.textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: textMuted,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                          ) ??
                                                      TextStyle(
                                                        color: textMuted,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                            color: textPrimary,
                                            height: 1.4,
                                          ) ??
                                          TextStyle(
                                            color: textPrimary,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 6,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
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
                                                : Icons
                                                      .favorite_outline_rounded,
                                            size: 14,
                                            color: comment.isLiked
                                                ? AppColors.likedAccent
                                                : textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            comment.likesCount > 0
                                                ? "${comment.likesCount}"
                                                : 'community.like'.tr,
                                            style:
                                                theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: comment.isLiked
                                                          ? AppColors
                                                                .likedAccent
                                                          : textMuted,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ) ??
                                                TextStyle(
                                                  color: comment.isLiked
                                                      ? AppColors.likedAccent
                                                      : textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    GestureDetector(
                                      onTap: () => _onReplyTo(
                                        comment.userName,
                                        commentId: comment.id,
                                      ),
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
                                            'community.reply'.tr,
                                            style:
                                                theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: textMuted,
                                                      fontWeight: FontWeight.bold,
                                                    ) ??
                                                TextStyle(
                                                  color: textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (comment.replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: comment.replies.map((reply) {
                                      final replyInitial = reply.userName.isNotEmpty
                                          ? reply.userName[0].toUpperCase()
                                          : 'U';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppColors.communityAccent.withValues(alpha: 0.2),
                                              backgroundImage: (reply.userAvatar.isNotEmpty && reply.userAvatar.startsWith('http'))
                                                  ? NetworkImage(reply.userAvatar)
                                                  : null,
                                              child: (reply.userAvatar.isEmpty || !reply.userAvatar.startsWith('http'))
                                                  ? Text(
                                                      replyInitial,
                                                      style: const TextStyle(
                                                        color: AppColors.communityAccent,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: surfaceSecondary,
                                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                                      border: Border.all(color: borderSubtle, width: 0.8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Builder(
                                                          builder: (context) {
                                                            final formattedTime = formatCommunityTimestamp(
                                                              reply.createdAt ?? reply.timeAgo,
                                                            );
                                                            return Text.rich(
                                                              TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text: reply.userName,
                                                                    style: theme.textTheme.labelMedium?.copyWith(
                                                                          color: textPrimary,
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                        ) ??
                                                                        TextStyle(
                                                                          color: textPrimary,
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                        ),
                                                                  ),
                                                                  if (formattedTime.isNotEmpty)
                                                                    TextSpan(
                                                                      text: ' · $formattedTime',
                                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                                            color: textMuted,
                                                                            fontSize: 10,
                                                                          ) ??
                                                                          TextStyle(color: textMuted, fontSize: 10),
                                                                    ),
                                                                ],
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          reply.text,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                                color: textPrimary,
                                                                height: 1.35,
                                                                fontSize: 12.5,
                                                              ) ??
                                                              TextStyle(
                                                                color: textPrimary,
                                                                fontSize: 12.5,
                                                                height: 1.35,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8, top: 4),
                                                    child: Row(
                                                      children: [
                                                        GestureDetector(
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
                                                                    : Icons.favorite_outline_rounded,
                                                                size: 13,
                                                                color: reply.isLiked
                                                                    ? AppColors.likedAccent
                                                                    : textMuted,
                                                              ),
                                                              const SizedBox(width: 3),
                                                              Text(
                                                                reply.likesCount > 0
                                                                    ? "${reply.likesCount}"
                                                                    : 'community.like'.tr,
                                                                style: theme.textTheme.labelSmall?.copyWith(
                                                                      color: reply.isLiked
                                                                          ? AppColors.likedAccent
                                                                          : textMuted,
                                                                      fontSize: 10.5,
                                                                      fontWeight: FontWeight.bold,
                                                                    ) ??
                                                                    TextStyle(
                                                                      color: reply.isLiked
                                                                          ? AppColors.likedAccent
                                                                          : textMuted,
                                                                      fontSize: 10.5,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        GestureDetector(
                                                          onTap: () => _onReplyTo(
                                                            reply.userName,
                                                            commentId: comment.id,
                                                          ),
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
                                                                'community.reply'.tr,
                                                                style: theme.textTheme.labelSmall?.copyWith(
                                                                      color: textMuted,
                                                                      fontSize: 10.5,
                                                                      fontWeight: FontWeight.bold,
                                                                    ) ??
                                                                    TextStyle(
                                                                      color: textMuted,
                                                                      fontSize: 10.5,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          if (_replyingToUser != null)
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
                  top: BorderSide(color: borderSubtle, width: 0.8),
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
                                    'community.replyingTo'.tr !=
                                        'community.replyingTo'
                                ? '${'community.replyingTo'.tr} '
                                : 'Replying to ',
                          ),
                          TextSpan(
                            text: _replyingToUser!,
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

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: surfacePrimary,
              border: Border(top: BorderSide(color: borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    cursorColor: textPrimary,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'community.writeCommentHint'.tr,
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBgPrimary
                          : AppColors.lightBgSecondary,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.communityAccent,
                  ),
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      controller.addComment(
                        widget.postId,
                        text,
                        parentCommentId: _replyingToCommentId,
                      );
                      _commentController.clear();
                      if (_replyingToUser != null ||
                          _replyingToCommentId != null) {
                        setState(() {
                          _replyingToUser = null;
                          _replyingToCommentId = null;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
