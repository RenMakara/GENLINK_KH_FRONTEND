import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import 'package:genlink_frontend/design_system/widgets/avatar/app_avatar.dart';
import 'package:genlink_frontend/design_system/widgets/images/app_cached_image.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';

/// Lightweight, read-only preview of an original post for reposting.
///
/// Accurately renders the original author, avatar, relative timestamp, audience,
/// post caption text, and actual media preview (single/multiple images with counter
/// and dots, video poster with play overlay, or compact text-only layout).
class OriginalPostPreview extends StatelessWidget {
  final CommunityPostModel post;

  const OriginalPostPreview({
    super.key,
    required this.post,
  });



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final cardBorder = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Detect media items
    final mediaList = post.mediaItems;
    final hasMedia = mediaList.isNotEmpty || post.imageUrls.isNotEmpty || (post.videoUrl != null && post.videoUrl!.isNotEmpty);

    return Semantics(
      label: 'Original post preview',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cardBorder, width: 0.9),
        ),
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Author Header ───────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(
                  imageUrl: post.authorAvatar,
                  name: post.authorName,
                  size: 38,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                // Name & Audience / Timestamp
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, color: textSecondary, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.community.isNotEmpty ? post.community : "All GenLink"} · ${post.timeAgo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative option dots
                Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),

            // ── Post Content Text ───────────────────────────────────────────
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  height: 1.45,
                  letterSpacing: 0.1,
                  fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                ),
              ),
            ],

            // ── Media Preview ───────────────────────────────────────────────
            if (hasMedia) ...[
              const SizedBox(height: 10),
              _buildMediaPreview(context, mediaList, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(
    BuildContext context,
    List<PostMediaItem> mediaList,
    bool isDark,
  ) {
    final count = mediaList.isNotEmpty
        ? mediaList.length
        : (post.imageUrls.isNotEmpty ? post.imageUrls.length : 1);

    final firstItem = mediaList.isNotEmpty ? mediaList.first : null;
    final isVideo = firstItem?.isVideo ??
        (post.videoUrl != null && post.videoUrl!.trim().isNotEmpty);

    final mediaUrl = firstItem?.url ??
        (post.imageUrls.isNotEmpty
            ? post.imageUrls.first
            : (post.videoUrl ?? ''));

    final surfacePlaceholder = isDark
        ? AppColors.darkBgSecondary
        : AppColors.lightBgPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base background / Image
                if (mediaUrl.isNotEmpty && !isVideo)
                  AppCachedImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 720,
                    errorWidget: Container(
                      color: surfacePlaceholder,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 32,
                      ),
                    ),
                  )
                else
                  // Video surface or fallback poster
                  Container(
                    color: surfacePlaceholder,
                    child: (post.imageUrls.isNotEmpty)
                        ? AppCachedImage(
                            imageUrl: post.imageUrls.first,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            errorWidget: const SizedBox.shrink(),
                          )
                        : null,
                  ),

                // Video play overlay
                if (isVideo)
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                // Top right count indicator badge (e.g. 1/4)
                if (count > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVideo
                                ? Icons.video_library_outlined
                                : Icons.photo_library_outlined,
                            size: 11.5,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1/$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom pagination dots indicator if multiple items
        if (count > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count.clamp(1, 6), (idx) {
              final isFirst = idx == 0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isFirst ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isFirst
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : (isDark
                          ? AppColors.darkBorderStrong
                          : AppColors.lightBorderStrong),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
