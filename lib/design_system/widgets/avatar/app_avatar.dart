import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/genlink_image_cache_manager.dart';
import '../../../core/utils/media_url_resolver.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 44,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = MediaUrlResolver.resolve(imageUrl);

    ImageProvider? imageProvider;
    if (resolved.isNotEmpty) {
      if (MediaUrlResolver.isAsset(resolved)) {
        imageProvider = AssetImage(resolved);
      } else if (MediaUrlResolver.isLocalFile(resolved)) {
        final cleanPath = resolved.startsWith('file://')
            ? resolved.replaceFirst('file://', '')
            : resolved;
        final file = File(cleanPath);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      } else {
        // High density decode size limit (3x pixel ratio cap between 64 and 512 px)
        final decodeDimension = (size * 3).round().clamp(64, 512);
        imageProvider = CachedNetworkImageProvider(
          resolved,
          cacheManager: GenLinkImageCacheManager(),
          maxHeight: decodeDimension,
          maxWidth: decodeDimension,
        );
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage: imageProvider,
      onForegroundImageError:
          imageProvider != null ? (exception, stackTrace) {} : null,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
