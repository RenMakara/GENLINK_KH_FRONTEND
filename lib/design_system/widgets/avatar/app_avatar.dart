import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

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
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        imageProvider = AssetImage(url);
      } else {
        String resolved = url;
        if (resolved.contains('.cdn.digitaloceanspaces.com')) {
          resolved = resolved.replaceFirst(
            '.cdn.digitaloceanspaces.com',
            '.digitaloceanspaces.com',
          );
        }
        if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
          imageProvider = NetworkImage(resolved);
        } else {
          final clean = resolved.startsWith('/') ? resolved : '/$resolved';
          imageProvider = NetworkImage('${AppConfig.apiBaseUrl}$clean');
        }
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundImage: imageProvider,
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
