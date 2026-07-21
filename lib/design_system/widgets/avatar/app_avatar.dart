import 'package:flutter/material.dart';

/// User, community, and organization avatar.
///
/// Falls back to initials when [imageUrl] is null or fails to load, so a
/// missing avatar never renders as a broken image.
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
    final url = imageUrl;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage:
          url != null && url.isNotEmpty ? NetworkImage(url) : null,
      // Shown when there is no image, and when the network image errors.
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
