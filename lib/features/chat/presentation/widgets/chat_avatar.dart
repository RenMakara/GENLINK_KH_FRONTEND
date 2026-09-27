import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/core/storage/genlink_image_cache_manager.dart';
import 'package:genlink_frontend/core/utils/media_url_resolver.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ChatAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final double radius;
  final bool isOnline;
  final bool isEventChat;
  final bool showBadge;
  final VoidCallback? onTap;

  const ChatAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 24,
    this.isOnline = false,
    this.isEventChat = false,
    this.showBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final avatarBgColor = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.chatPrimary.withValues(alpha: 0.12);
    final textInitialColor = isDark
        ? AppColors.chatPrimaryLight
        : AppColors.chatPrimary;

    ImageProvider? imageProvider;
    final resolvedUrl = MediaUrlResolver.resolve(avatarUrl);
    if (resolvedUrl.isNotEmpty) {
      if (MediaUrlResolver.isRemoteUrl(resolvedUrl)) {
        final decodedWidth = (radius * 2 * 3).round().clamp(64, 512);
        imageProvider = CachedNetworkImageProvider(
          resolvedUrl,
          cacheManager: GenLinkImageCacheManager(),
          maxWidth: decodedWidth,
          maxHeight: decodedWidth,
        );
      } else if (MediaUrlResolver.isAsset(resolvedUrl)) {
        imageProvider = AssetImage(resolvedUrl);
      } else {
        try {
          final cleanPath = resolvedUrl.startsWith('file://')
              ? resolvedUrl.replaceFirst('file://', '')
              : resolvedUrl;
          final file = File(cleanPath);
          if (file.existsSync()) {
            imageProvider = FileImage(file);
          }
        } catch (_) {
          imageProvider = null;
        }
      }
    }

    Widget avatarContent = CircleAvatar(
      radius: radius,
      backgroundColor: avatarBgColor,
      foregroundImage: imageProvider,
      onForegroundImageError: imageProvider != null
          ? (exception, stackTrace) {
            }
          : null,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: textInitialColor,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );

    if (onTap != null) {
      avatarContent = GestureDetector(
        onTap: onTap,
        child: avatarContent,
      );
    }

    if (!showBadge || (!isOnline && !isEventChat)) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: avatarContent,
      );
    }

    final badgeSize = (radius * 0.44).clamp(10.0, 16.0);
    final badgeBorderWidth = (radius * 0.08).clamp(1.5, 2.5);

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarContent,
          if (isEventChat)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize + 2,
                height: badgeSize + 2,
                decoration: BoxDecoration(
                  color: AppColors.chatPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: surfaceColor,
                    width: badgeBorderWidth,
                  ),
                ),
                child: Icon(
                  Icons.event,
                  size: badgeSize * 0.65,
                  color: Colors.white,
                ),
              ),
            )
          else if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: surfaceColor,
                    width: badgeBorderWidth,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
