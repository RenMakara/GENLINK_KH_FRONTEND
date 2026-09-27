import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/genlink_image_cache_manager.dart';
import '../../../core/utils/media_url_resolver.dart';
import '../../colors/app_colors.dart';

/// Centralized image component for GenLink KH.
///
/// Features:
/// - Automatically resolves URLs via [MediaUrlResolver] (handling CloudFront,
///   DigitalOcean domain fixes, relative backend paths, assets, and local files).
/// - Integrates with [GenLinkImageCacheManager] for persistent disk caching.
/// - Supports memory-budgeted decoding via [memCacheWidth] / [memCacheHeight].
/// - Handles placeholders, loading states, and error states gracefully.
/// - Optional [borderRadius] for clipping.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.placeholder,
    this.placeholderBuilder,
    this.errorWidget,
    this.errorBuilder,
    this.imageBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
    this.color,
    this.colorBlendMode,
    this.fadeInDuration = const Duration(milliseconds: 250),
    this.fadeOutDuration = const Duration(milliseconds: 150),
    this.usePlaceholder = true,
  });

  /// The raw image URL or path (can be null, empty, asset, local file, or remote URL).
  final String? imageUrl;

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;

  /// Static placeholder widget to display while loading.
  final Widget? placeholder;

  /// Custom builder for placeholder / loading state.
  final Widget Function(BuildContext context, String url)? placeholderBuilder;

  /// Static error widget to display on failure.
  final Widget? errorWidget;

  /// Custom builder for error state.
  final Widget Function(BuildContext context, String url, dynamic error)?
      errorBuilder;

  /// Optional builder to customize how the resolved [ImageProvider] is displayed.
  final Widget Function(BuildContext context, ImageProvider imageProvider)?
      imageBuilder;

  /// Optional maximum decoded width in memory (RAM).
  final int? memCacheWidth;

  /// Optional maximum decoded height in memory (RAM).
  final int? memCacheHeight;

  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  /// Whether to show a placeholder while loading. Defaults to true.
  final bool usePlaceholder;

  Widget _resolvePlaceholder(BuildContext context, String url) {
    if (placeholder != null) return placeholder!;
    if (placeholderBuilder != null) return placeholderBuilder!(context, url);
    return _buildDefaultPlaceholder(context);
  }

  Widget _resolveError(BuildContext context, String url, dynamic error) {
    if (errorWidget != null) return errorWidget!;
    if (errorBuilder != null) return errorBuilder!(context, url, error);
    return _buildDefaultError(context, url, error);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrlResolver.resolve(imageUrl);

    Widget content;
    if (resolved.isEmpty) {
      content = _resolveError(context, '', 'empty_url');
    } else if (MediaUrlResolver.isAsset(resolved)) {
      content = _buildAssetImage(context, resolved);
    } else if (MediaUrlResolver.isLocalFile(resolved)) {
      content = _buildLocalFileImage(context, resolved);
    } else {
      content = _buildCachedNetworkImage(context, resolved);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildCachedNetworkImage(BuildContext context, String resolvedUrl) {
    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      cacheManager: GenLinkImageCacheManager(),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      imageBuilder: imageBuilder,
      placeholder: usePlaceholder
          ? (ctx, url) => _resolvePlaceholder(ctx, url)
          : null,
      errorWidget: (ctx, url, error) => _resolveError(ctx, url, error),
    );
  }

  Widget _buildAssetImage(BuildContext context, String assetPath) {
    Widget img = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (ctx, err, stack) => _resolveError(ctx, assetPath, err),
    );
    if (imageBuilder != null) {
      return imageBuilder!(context, AssetImage(assetPath));
    }
    return img;
  }

  Widget _buildLocalFileImage(BuildContext context, String filePath) {
    final cleanPath = filePath.startsWith('file://')
        ? filePath.replaceFirst('file://', '')
        : filePath;
    final file = File(cleanPath);

    if (!file.existsSync()) {
      return _resolveError(context, filePath, 'File not found');
    }

    if (imageBuilder != null) {
      return imageBuilder!(context, FileImage(file));
    }

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (ctx, err, stack) => _resolveError(ctx, filePath, err),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;

    return Container(
      width: width,
      height: height,
      color: bg,
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError(
    BuildContext context,
    String url,
    dynamic error,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final iconColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      width: width,
      height: height,
      color: bg,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: iconColor,
        size: (width != null && width! < 40) || (height != null && height! < 40)
            ? 18
            : 28,
      ),
    );
  }
}
