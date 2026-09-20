import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../../shared/utils/current_user.dart';

class AuthorRow extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final bool isAnonymous;

  const AuthorRow({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    this.isAnonymous = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = isAnonymous ? null : CurrentUser.avatarUrl;
    final String realName = CurrentUser.name;

    final String displayName = isAnonymous
        ? ('community.anonymous'.tr.isNotEmpty &&
                'community.anonymous'.tr != 'community.anonymous'
            ? 'community.anonymous'.tr
            : 'Anonymous')
        : realName;

    final String identityLabel = isAnonymous
        ? ('community.hideIdentity'.tr.isNotEmpty &&
                'community.hideIdentity'.tr != 'community.hideIdentity'
            ? 'community.hideIdentity'.tr
            : 'Hide User Identity')
        : ('community.public'.tr.isNotEmpty &&
                'community.public'.tr != 'community.public'
            ? 'community.public'.tr
            : 'Public');

    final IconData identityIcon =
        isAnonymous ? Icons.visibility_off_outlined : Icons.public;

    return Row(
      children: [
        if (isAnonymous)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.visibility_off_outlined,
                color: textMuted,
                size: 20,
              ),
            ),
          )
        else
          AppAvatar(
            imageUrl: avatarUrl,
            name: realName,
            size: 40,
          ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
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
                Icon(identityIcon, color: textMuted, size: 13),
                const SizedBox(width: 4),
                Text(
                  identityLabel,
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
