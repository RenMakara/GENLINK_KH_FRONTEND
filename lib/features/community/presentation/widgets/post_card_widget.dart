import 'dart:io';
import 'poll_widget.dart';
import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_post_model.dart';
import '../screens/create_post_screen.dart';
import '../controllers/community_controller.dart';
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

class _PostCardWidgetState extends State<PostCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnim;

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
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  void _onLikeTap() {
    _likeAnimController.forward(from: 0.0);
    widget.controller.toggleLike(widget.post.id);
  }

  void _confirmDeletePost(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Post?",
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this post? This action can be undone briefly.",
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.bookmark_border, color: textThemeColor),
                title: Text(
                  widget.post.isBookmarked ? "Remove Bookmark" : "Save Bookmark",
                  style: TextStyle(color: textThemeColor),
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
                leading: Icon(Icons.repeat_rounded, color: textThemeColor),
                title: Text("Repost", style: TextStyle(color: textThemeColor)),
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
                  leading: const Icon(Icons.edit_outlined, color: AppColors.communityAccent),
                  title: const Text("Edit Post", style: TextStyle(color: AppColors.communityAccent)),
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
                  title: const Text("Delete Post", style: TextStyle(color: AppColors.danger)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
        ),
        title: Text(
          "Repost Content",
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reposting content originally by ${widget.post.authorName}",
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: captionController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Add an optional quote caption...",
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
              "Cancel",
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
              backgroundColor: isDark ? Colors.white : AppColors.lightPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "Repost Now",
              style: TextStyle(
                color: isDark ? Colors.black : AppColors.lightTextInverse,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final actionIconColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repost Header Banner
          if (widget.post.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded, color: AppColors.communityAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.post.repostedBy} reposted",
                    style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Optional Repost Quote Caption
          if (widget.post.repostCaption != null && widget.post.repostCaption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 6, right: 16, bottom: 10),
              child: Text(
                widget.post.repostCaption!,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          // Author Header Tile
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.authorAvatar.startsWith('assets/')
                      ? AssetImage(widget.post.authorAvatar) as ImageProvider
                      : (widget.post.authorAvatar.startsWith('http')
                          ? NetworkImage(widget.post.authorAvatar)
                          : null),
                  backgroundColor: AppColors.communityAccent.withValues(alpha: 0.2),
                  child: (!widget.post.authorAvatar.startsWith('http') && !widget.post.authorAvatar.startsWith('assets/'))
                      ? Text(
                          widget.post.authorAvatar.isNotEmpty ? widget.post.authorAvatar[0] : 'U',
                          style: const TextStyle(color: AppColors.communityAccent, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.post.authorName,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (widget.post.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.communityAccent, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.post.timeAgo,
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.lightBgSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.post.community,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textSecondary, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: actionIconColor, size: 20),
                  onPressed: () => _showMoreMenu(context),
                ),
              ],
            ),
          ),

          // Post Content Text
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.content,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),

          // Location Tag Chip
          if (widget.post.location != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.danger, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.post.location!,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

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

          // Post Action Buttons Bar (Like, Comment, Share, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Animated Like Button
                InkWell(
                  onTap: _onLikeTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeScaleAnim,
                          child: Icon(
                            widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: widget.post.isLiked ? AppColors.danger : actionIconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.likesCount}",
                          style: TextStyle(
                            color: widget.post.isLiked ? AppColors.danger : actionIconColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

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
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: actionIconColor, size: 21),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.commentsCount}",
                          style: TextStyle(color: actionIconColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Repost Button (Replaces Share completely)
                InkWell(
                  onTap: () => _showRepostDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: actionIconColor, size: 21),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.post.repostsCount}",
                          style: TextStyle(color: actionIconColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bookmark Button
                IconButton(
                  onPressed: () => widget.controller.toggleBookmark(widget.post.id),
                  icon: Icon(
                    widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.post.isBookmarked ? AppColors.communityAccent : actionIconColor,
                    size: 22,
                  ),
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

    // Single Image
    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: _buildSingleImage(images[0], index: 0, allImages: images),
          ),
        ),
      );
    }

    // 2 Images Split
    if (count == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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

    // 3 Images (1 Main Left + 2 Stacked Right)
    if (count == 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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

    // 4 or More Images (Quad Grid with +X Overlay)
    final extraCount = count - 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                        color: Colors.black.withValues(alpha: 0.65),
                        alignment: Alignment.center,
                        child: Text(
                          "+$extraCount",
                          style: const TextStyle(
                            color: Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayDomain = domain ?? (url.contains('github.com') ? 'github.com' : 'campuslink.kh');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.link_rounded, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? "CampusLink Resource Link",
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayDomain,
                  style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, color: isDark ? Colors.white38 : AppColors.lightTextMuted, size: 18),
        ],
      ),
    );
  }
}

class _EditPostModalDialog extends StatefulWidget {
  final CommunityPostModel post;
  final CommunityController controller;

  const _EditPostModalDialog({
    required this.post,
    required this.controller,
  });

  @override
  State<_EditPostModalDialog> createState() => _EditPostModalDialogState();
}

class _EditPostModalDialogState extends State<_EditPostModalDialog> {
  late TextEditingController _textController;
  late String _initialContent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialContent = widget.post.content;
    _textController = TextEditingController(text: _initialContent);
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _hasChanged =>
      _textController.text.trim().isNotEmpty &&
      _textController.text.trim() != _initialContent.trim();

  void _saveChanges() async {
    if (!_hasChanged || _isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final newText = _textController.text.trim();
    await widget.controller.editPost(widget.post.id, newText);

    if (!mounted) return;
    Navigator.pop(context);

    AppNotificationBanner.showInfo(
      context: context,
      title: "✓ Post Updated",
      message: "Your changes have been saved successfully.",
      icon: Icons.edit_note_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderSubtle, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Title & Close Icon Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Edit Post",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Minimal Text Editor Field (Auto-expanding, subtle border)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle, width: 1),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _textController,
                minLines: 3,
                maxLines: 6,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: "What would you like to edit?",
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Row: Cancel (Text only) + Save (Solid White/Primary Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel Action Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Save Action Button
                ElevatedButton(
                  onPressed: _hasChanged && !_isSaving ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanged
                        ? (isDark ? Colors.white : AppColors.lightPrimary)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBorderSubtle),
                    disabledBackgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBorderSubtle,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    minimumSize: const Size(80, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: isDark ? Colors.black : AppColors.lightTextInverse,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save",
                          style: TextStyle(
                            color: _hasChanged
                                ? (isDark ? Colors.black : AppColors.lightTextInverse)
                                : (isDark ? Colors.white38 : AppColors.lightTextMuted),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  late List<Map<String, String>> _comments;

  @override
  void initState() {
    super.initState();
    if (widget.postId == 'post_sambo') {
      _comments = [
        {
          'userName': 'Sokny Enat',
          'userAvatar': 'assets/images/user_profile.png',
          'timeAgo': '2h ago',
          'text': 'Great work! Security is essential for every application. 🔒',
        },
        {
          'userName': 'Ren Makara',
          'userAvatar': 'assets/images/ren_makara_profile.png',
          'timeAgo': '1h ago',
          'text': 'Nice! Backend security is always a priority. 👏',
        },
        {
          'userName': 'Chhaeng Sokuntheara',
          'userAvatar': 'assets/images/sokuntheara_profile.png',
          'timeAgo': '30m ago',
          'text': 'Looking forward to seeing more security tips! 🚀',
        },
      ];
    } else if (widget.postId == 'post_sokuntheara') {
      _comments = [
        {
          'userName': 'Sokny Enat',
          'userAvatar': 'assets/images/user_profile.png',
          'timeAgo': '45m ago',
          'text': 'The new UI looks amazing! 🔥',
        },
        {
          'userName': 'Ren Makara',
          'userAvatar': 'assets/images/ren_makara_profile.png',
          'timeAgo': '30m ago',
          'text': 'Can\'t wait to integrate this into the app. 👏',
        },
        {
          'userName': 'Heng Chansela',
          'userAvatar': 'assets/images/heng_chansela_profile.png',
          'timeAgo': '15m ago',
          'text': 'Clean and modern design! 🎨',
        },
      ];
    } else if (widget.postId == 'post_makara') {
      _comments = [
        {
          'userName': 'Sokny Enat',
          'userAvatar': 'assets/images/user_profile.png',
          'timeAgo': '4h ago',
          'text': 'Amazing backend work! 👏',
        },
        {
          'userName': 'Heng Chansela',
          'userAvatar': 'assets/images/heng_chansela_profile.png',
          'timeAgo': '3h ago',
          'text': 'Looks great! Keep it up 🔥',
        },
        {
          'userName': 'Chhaeng Sokuntheara',
          'userAvatar': 'assets/images/sokuntheara_profile.png',
          'timeAgo': '1h ago',
          'text': 'The API performance is impressive 🚀',
        },
      ];
    } else {
      _comments = [
        {
          'userName': 'Sokny Enat',
          'userAvatar': 'assets/images/user_profile.png',
          'timeAgo': '1h ago',
          'text': 'Looking great! 😊',
        },
        {
          'userName': 'Chhaeng Sokuntheara',
          'userAvatar': 'assets/images/sokuntheara_profile.png',
          'timeAgo': '1h ago',
          'text': 'Beautiful couple ❤️',
        },
        {
          'userName': 'Sum Sambo',
          'userAvatar': 'assets/images/sum_sambo_profile.png',
          'timeAgo': '30m ago',
          'text': 'Hope you both had a wonderful day! ☕',
        },
      ];
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add({
        'userName': 'Sokny Enat',
        'userAvatar': 'assets/images/user_profile.png',
        'timeAgo': 'Just now',
        'text': text,
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.lightBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Comments (${_comments.length})",
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white54 : AppColors.lightTextSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _comments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final c = _comments[idx];
                  final avatar = c['userAvatar']!;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: avatar.startsWith('assets/')
                            ? AssetImage(avatar) as ImageProvider
                            : NetworkImage(avatar),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    c['userName']!,
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    c['timeAgo']!,
                                    style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['text']!,
                                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.lightTextMuted, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.communityAccent, size: 22),
                  onPressed: _addComment,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
