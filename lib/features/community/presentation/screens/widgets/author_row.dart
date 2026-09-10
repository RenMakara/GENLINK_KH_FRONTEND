import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../../shared/utils/current_user.dart';

class AuthorRow extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const AuthorRow({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = CurrentUser.avatarUrl;
    final String name = CurrentUser.name;

    final String publicLabel = 'community.public'.tr.isNotEmpty &&
            'community.public'.tr != 'community.public'
        ? 'community.public'.tr
        : 'Public';

    return Row(
      children: [
        AppAvatar(
          imageUrl: avatarUrl,
          name: name,
          size: 40,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, color: textMuted, size: 13),
                const SizedBox(width: 4),
                Text(
                  publicLabel,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
