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

  void _onReplyTo(String userName) {
    setState(() {
      _replyingToUser = userName;
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
                        color: textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No comments yet. Be the first to start the discussion!",
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                              color: textMuted,
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: surfaceSecondary,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            comment.userName,
                                            style:
                                                theme.textTheme.labelMedium
                                                    ?.copyWith(
                                                      color: textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ) ??
                                                TextStyle(
                                                  color: textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          formatCommunityTimestamp(comment.createdAt ?? comment.timeAgo),
                                          style:
                                              theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: textMuted,
                                                  ) ??
                                              TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
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
                                      onTap: () => _onReplyTo(comment.userName),
                                      child: Text(
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
                },
              );
            }),
          ),

          if (_replyingToUser != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              color: surfaceSecondary,
              child: Row(
                children: [
                  Text(
                    'community.replyingTo'.trParams({'user': _replyingToUser!}),
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.communityAccent,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          color: AppColors.communityAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: textMuted,
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
              color: surfaceSecondary,
              border: Border(top: BorderSide(color: borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                        ) ??
                        TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'community.writeCommentHint'.tr,
                      hintStyle:
                          theme.textTheme.bodyMedium?.copyWith(
                            color: textMuted,
                          ) ??
                          TextStyle(color: textMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.communityAccent,
                  ),
                  onPressed: () {
                    if (_commentController.text.trim().isNotEmpty) {
                      controller.addComment(
                        widget.postId,
                        _commentController.text,
                      );
                      _commentController.clear();
                      if (_replyingToUser != null) {
                        setState(() {
                          _replyingToUser = null;
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
