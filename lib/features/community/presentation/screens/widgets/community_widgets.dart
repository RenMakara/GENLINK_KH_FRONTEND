import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/utils/date_formatter.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import 'package:genlink_frontend/design_system/widgets/avatar/app_avatar.dart';
import '../../widgets/community_design_tokens.dart';
import '../../widgets/forum_liked_by_sheet.dart';
import '../../widgets/forum_repost_dialog.dart';
import '../../widgets/forum_share_to_chat_sheet.dart';
import '../../../domain/models/community_models.dart';
import '../../controllers/community_controller.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../community_search_screen.dart';

class ForumCategoryCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;
  final Color? accent;
  final bool isSelected;
  final VoidCallback? onTap;

  const ForumCategoryCard({
    super.key,
    required this.title,
    required this.count,
    this.icon,
    this.accent,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isSelected
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary);

    final cardBorder = isSelected
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark
            ? AppColors.darkBorderSubtle.withValues(alpha: 0.60)
            : AppColors.lightBorderSubtle);

    final titleColor = isSelected
        ? (isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final countColor = isSelected
        ? (isDark
            ? AppColors.darkTextInverse.withValues(alpha: 0.75)
            : AppColors.lightTextInverse.withValues(alpha: 0.75))
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final iconBoxBg = isSelected
        ? (isDark
            ? AppColors.darkTextInverse.withValues(alpha: 0.12)
            : AppColors.lightTextInverse.withValues(alpha: 0.10))
        : (isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.lightBgSecondary);
    final iconColor = isSelected
        ? (isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: countColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForumLikedByPreview extends StatelessWidget {
  final int likesCount;
  final List<ForumLikerModel> likers;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isOwner;

  const ForumLikedByPreview({
    super.key,
    required this.likesCount,
    this.likers = const [],
    this.onTap,
    required this.isDark,
    this.isOwner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOwner || likesCount <= 0) return const SizedBox.shrink();

    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    final displayLikers = likers.take(3).toList();

    String likedByText = '';
    final likedByLabel = 'community.likedBy'.tr.isNotEmpty &&
            'community.likedBy'.tr != 'community.likedBy'
        ? 'community.likedBy'.tr
        : 'Liked by';

    if (displayLikers.isNotEmpty) {
      if (displayLikers.length == 1) {
        if (likesCount > 1) {
          likedByText = '$likedByLabel ${displayLikers[0].fullName} +${likesCount - 1}';
        } else {
          likedByText = '$likedByLabel ${displayLikers[0].fullName}';
        }
      } else if (displayLikers.length == 2) {
        if (likesCount > 2) {
          likedByText =
              '$likedByLabel ${displayLikers[0].fullName}, ${displayLikers[1].fullName} +${likesCount - 2}';
        } else {
          likedByText =
              '$likedByLabel ${displayLikers[0].fullName}, ${displayLikers[1].fullName}';
        }
      } else {
        if (likesCount > 3) {
          likedByText =
              '$likedByLabel ${displayLikers[0].fullName}, ${displayLikers[1].fullName} +${likesCount - 2}';
        } else {
          likedByText =
              '$likedByLabel ${displayLikers[0].fullName}, ${displayLikers[1].fullName}, ${displayLikers[2].fullName}';
        }
      }
    } else {
      likedByText = '$likedByLabel $likesCount ${likesCount == 1 ? 'person' : 'people'}';
    }

    return InkWell(
      key: const Key('forum_liked_by_preview'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (displayLikers.isNotEmpty) ...[
              SizedBox(
                height: 20,
                width: 14.0 * (displayLikers.length - 1) + 20.0,
                child: Stack(
                  children: List.generate(displayLikers.length, (i) {
                    final l = displayLikers[i];
                    return Positioned(
                      left: i * 14.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: surface, width: 1.5),
                        ),
                        child: AppAvatar(
                          imageUrl: l.avatarUrl,
                          name: l.fullName,
                          size: 18,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.communityAccent.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 11,
                    color: AppColors.communityAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                likedByText,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForumThreadCard extends StatefulWidget {
  final String title;
  final String author;
  final String? avatarUrl;
  final String timeAgo;
  final DateTime? createdAt;
  final String? content;
  final String category;
  final int replies;
  final int likes;
  final bool isPinned;
  final bool isLiked;
  final List<ForumLikerModel> likers;
  final String? discussionId;
  final bool isOwner;
  final bool isAnonymous;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikedByTap;
  final VoidCallback? onRepostTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareToChatTap;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onMoreTap;

  const ForumThreadCard({
    super.key,
    required this.title,
    required this.author,
    this.avatarUrl,
    required this.timeAgo,
    this.createdAt,
    this.content,
    required this.category,
    required this.replies,
    required this.likes,
    this.isPinned = false,
    this.isLiked = false,
    this.isAnonymous = false,
    this.isBookmarked = false,
    this.likers = const [],
    this.discussionId,
    this.isOwner = false,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onLikedByTap,
    this.onRepostTap,
    this.onSaveTap,
    this.onShareToChatTap,
    this.onCategoryTap,
    this.onAuthorTap,
    this.onMoreTap,
  });

  bool get mine => isOwner;

  @override
  State<ForumThreadCard> createState() => _ForumThreadCardState();
}

class _ForumThreadCardState extends State<ForumThreadCard>
    with TickerProviderStateMixin {
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
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_likeAnimController);

    _bookmarkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _bookmarkScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_bookmarkAnimController);
  }

  @override
  void didUpdateWidget(covariant ForumThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBookmarked != widget.isBookmarked && widget.isBookmarked) {
      _bookmarkAnimController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    _bookmarkAnimController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeAnimController.forward(from: 0.0);
    widget.onLikeTap?.call();
  }

  void _handleSave() {
    _bookmarkAnimController.forward(from: 0.0);
    if (widget.onSaveTap != null) {
      widget.onSaveTap!();
    } else if (widget.discussionId != null && widget.discussionId!.isNotEmpty) {
      if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>()
            .toggleDiscussionBookmark(widget.discussionId!);
      }
    }
  }

  void _handleShareToChat(BuildContext context) {
    if (widget.onShareToChatTap != null) {
      widget.onShareToChatTap!();
    } else {
      final bool isAnon = widget.isAnonymous ||
          widget.author.trim().toLowerCase() == 'anonymous' ||
          ('community.anonymous'.tr.isNotEmpty &&
              widget.author.trim().toLowerCase() ==
                  'community.anonymous'.tr.toLowerCase());
      final topic = ForumTopicModel(
        id: widget.discussionId ?? '',
        title: widget.title,
        authorName: isAnon ? 'Anonymous' : widget.author,
        authorAvatar: isAnon ? '' : (widget.avatarUrl ?? ''),
        category: widget.category,
        content: widget.content ?? '',
        timeAgo: widget.timeAgo,
        createdAt: widget.createdAt,
        isLiked: widget.isLiked,
        upvotes: widget.likes,
        repliesCount: widget.replies,
        isBookmarked: widget.isBookmarked,
        isAnonymous: isAnon,
        likers: widget.likers,
      );
      ForumShareToChatSheet.show(context, topic: topic);
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

    final formattedTime =
        formatCommunityTimestamp(widget.createdAt ?? widget.timeAgo);

    final bool effectiveAnonymous = widget.isAnonymous ||
        widget.author.trim().toLowerCase() == 'anonymous' ||
        ('community.anonymous'.tr.isNotEmpty &&
            widget.author.trim().toLowerCase() ==
                'community.anonymous'.tr.toLowerCase());
    final String displayAuthor = effectiveAnonymous
        ? ('community.anonymous'.tr.isNotEmpty &&
                'community.anonymous'.tr != 'community.anonymous'
            ? 'community.anonymous'.tr
            : 'Anonymous')
        : widget.author;
    final VoidCallback? effectiveAuthorTap =
        effectiveAnonymous ? null : widget.onAuthorTap;

    return Container(
      margin: const EdgeInsets.only(bottom: CommunityCardStyle.cardBottomMargin),
      decoration: CommunityCardStyle.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CommunityCardStyle.cardRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(CommunityCardStyle.cardRadius),
          child: Padding(
            padding: CommunityCardStyle.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: effectiveAuthorTap,
                      child: effectiveAnonymous
                          ? CircleAvatar(
                              radius: 19,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightBgSecondary,
                              child: Icon(
                                Icons.person_outline,
                                size: 20,
                                color: textMuted,
                              ),
                            )
                          : AppAvatar(
                              imageUrl: widget.avatarUrl,
                              name: widget.author,
                              size: 38,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: effectiveAuthorTap,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: displayAuthor,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          letterSpacing: -0.2,
                                        ) ??
                                        TextStyle(
                                          color: textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                  if (formattedTime.isNotEmpty) ...[
                                    TextSpan(
                                      text: " · ",
                                      style: TextStyle(
                                        color: textMuted.withValues(alpha: 0.65),
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextSpan(
                                      text: formattedTime,
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 3),
                          CommunityCategoryBadge(
                            label: widget.category,
                            onTap: widget.onCategoryTap,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onMoreTap != null) ...[
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: widget.onMoreTap,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        fontSize: 16.0,
                        letterSpacing: -0.2,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                ),
                if (widget.content != null &&
                    widget.content!.trim().isNotEmpty &&
                    widget.content!.trim() != widget.title.trim()) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.content!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                          fontSize: 14.0,
                          height: 1.45,
                        ) ??
                        TextStyle(
                          color: textSecondary,
                          fontSize: 14.0,
                          height: 1.45,
                        ),
                  ),
                ],
                if (widget.isOwner && widget.likes > 0) ...[
                  const SizedBox(height: 6),
                  ForumLikedByPreview(
                    likesCount: widget.likes,
                    likers: widget.likers,
                    isDark: isDark,
                    isOwner: widget.isOwner,
                    onTap: () => _handleLikedByTap(context),
                  ),
                ],
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 320;
                    final hPad = isCompact ? 4.0 : 6.0;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Like (icon + real count)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: InkWell(
                              onTap: _handleLike,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ScaleTransition(
                                      scale: _likeScaleAnim,
                                      child: Icon(
                                        widget.isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: widget.isLiked
                                            ? AppColors.likedAccent
                                            : textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${widget.likes}",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                            color: widget.isLiked
                                                ? AppColors.likedAccent
                                                : textSecondary,
                                            fontWeight: widget.isLiked
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            fontSize: 12.5,
                                          ) ??
                                          TextStyle(
                                            color: widget.isLiked
                                                ? AppColors.likedAccent
                                                : textSecondary,
                                            fontSize: 12.5,
                                            fontWeight: widget.isLiked
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 2. Comment (icon + real count, no text)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: InkWell(
                              onTap: widget.onCommentTap ?? widget.onTap,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${widget.replies}",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                            color: textSecondary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ) ??
                                          TextStyle(
                                            color: textSecondary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 3. Repost (icon only, matching Feed style)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: InkWell(
                              key: const Key('forum_card_repost_button'),
                              onTap: widget.onRepostTap ?? () => _handleRepost(context),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hPad,
                                  vertical: 4,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.repeat_rounded,
                                    color: textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Alignment: Spacer pushes Save & Share to the far right, matching Feed
                        const Spacer(),

                        // 4. Save (icon only, right-aligned)
                        Tooltip(
                          message: widget.isBookmarked
                              ? 'community.removeBookmark'.tr
                              : 'community.saveBookmark'.tr,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: InkWell(
                                key: const Key('forum_card_save_button'),
                                onTap: _handleSave,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hPad,
                                      vertical: 4,
                                    ),
                                    child: ScaleTransition(
                                      scale: _bookmarkScaleAnim,
                                      child: Icon(
                                        widget.isBookmarked
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        color: widget.isBookmarked
                                            ? AppColors.warning
                                            : textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 5. Share to Chat (icon only, right-aligned)
                        Tooltip(
                          message: 'community.shareToChat'.tr.isNotEmpty &&
                                  'community.shareToChat'.tr != 'community.shareToChat'
                              ? 'community.shareToChat'.tr
                              : 'Share',
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              child: InkWell(
                                key: const Key('forum_card_share_to_chat_button'),
                                onTap: () => _handleShareToChat(context),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hPad,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.ios_share_rounded,
                                      color: textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLikedByTap(BuildContext context) {
    if (!widget.isOwner || widget.likes <= 0) return;
    if (widget.onLikedByTap != null) {
      widget.onLikedByTap!();
      return;
    }
    if (widget.discussionId != null && widget.discussionId!.trim().isNotEmpty) {
      ForumLikedBySheet.show(
        context,
        discussionId: widget.discussionId!,
        initialLikers: widget.likers,
        isOwner: widget.isOwner,
      );
    }
  }

  void _handleRepost(BuildContext context) {
    if (widget.isOwner) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'Cannot Repost',
        message: 'community.cannotRepostOwnPost'.tr.isNotEmpty &&
                'community.cannotRepostOwnPost'.tr !=
                    'community.cannotRepostOwnPost'
            ? 'community.cannotRepostOwnPost'.tr
            : 'You cannot repost your own discussion.',
      );
      return;
    }
    final bool isAnon = widget.isAnonymous ||
        widget.author.trim().toLowerCase() == 'anonymous' ||
        ('community.anonymous'.tr.isNotEmpty &&
            widget.author.trim().toLowerCase() ==
                'community.anonymous'.tr.toLowerCase());
    final topic = ForumTopicModel(
      id: widget.discussionId ?? '',
      authorName: isAnon ? 'Anonymous' : widget.author,
      authorAvatar: isAnon ? '' : (widget.avatarUrl ?? ''),
      title: widget.title,
      category: widget.category,
      content: widget.content ?? '',
      timeAgo: widget.timeAgo,
      createdAt: widget.createdAt,
      isLiked: widget.isLiked,
      upvotes: widget.likes,
      repliesCount: widget.replies,
      isBookmarked: widget.isBookmarked,
      isAnonymous: isAnon,
      likers: widget.likers,
      isOwner: widget.isOwner,
    );
    ForumRepostDialog.show(context, topic: topic);
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String type;
  final String salary;
  final Color logoColor;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.type,
    required this.salary,
    required this.logoColor,
  });

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
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return InkWell(
      onTap: () =>
          Get.to(() => const CommunitySearchScreen(activeTab: 'Career')),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.business_rounded, color: textPrimary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company,
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ) ??
                        TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: textPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        salary,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.bold,
                            ) ??
                            TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
    );
  }
}

class MentorCard extends StatelessWidget {
  final String name;
  final String role;
  final String avatarUrl;

  const MentorCard({
    super.key,
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

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
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return InkWell(
      onTap: () =>
          Get.to(() => const CommunitySearchScreen(activeTab: 'Career')),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.sm + 4),
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          children: [
            AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: 52,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.titleSmall?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 10,
                  ) ??
                  TextStyle(color: textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class CareerTabView extends StatelessWidget {
  const CareerTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Get.to(
                () => const CommunitySearchScreen(activeTab: 'Career'),
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'community.searchJobs'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textMuted) ??
                          TextStyle(color: textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'community.recommendedOpportunities'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const JobCard(
              title: "Junior Flutter Developer",
              company: "ABA Bank • Phnom Penh",
              type: "Full-Time",
              salary: "\$600 - \$900 / mo",
              logoColor: AppColors.brandPrimary,
            ),
            const JobCard(
              title: "UI/UX Design Intern",
              company: "Smart Axiata • Phnom Penh",
              type: "Internship",
              salary: "\$250 - \$350 / mo",
              logoColor: AppColors.danger,
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'community.campusAlumniMentors'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MentorCard(
                    name: "Sokha Kim",
                    role: "Senior Tech Lead @ Wing",
                    avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                  ),
                  MentorCard(
                    name: "Bopha V.",
                    role: "Lead UX Designer @ ABA",
                    avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
                  ),
                  MentorCard(
                    name: "Dara N.",
                    role: "Mobile Architect @ Chip Mong",
                    avatarUrl: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

