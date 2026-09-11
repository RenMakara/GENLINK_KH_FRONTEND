import 'dart:io';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.name, this.size = 44});

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = imageUrl?.trim();

    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty && url != 'null' && url != 'undefined') {
      if (url.startsWith('assets/')) {
        imageProvider = AssetImage(url);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        final uri = Uri.tryParse(url);
        if (uri != null && uri.hasScheme) {
          imageProvider = NetworkImage(url);
        }
      } else if (url.startsWith('/') || url.startsWith('file://')) {
        try {
          final filePath = url.startsWith('file://')
              ? Uri.parse(url).toFilePath()
              : url;
          imageProvider = FileImage(File(filePath));
        } catch (_) {}
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage: imageProvider,
      onForegroundImageError: imageProvider != null
          ? (exception, stackTrace) {
              // Fall back gracefully to initials child
            }
          : null,
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
