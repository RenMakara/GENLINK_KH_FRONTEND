import 'package:flutter/material.dart';
import '../../../../../shared/utils/current_user.dart';

/// Shared author identity row for Community creation screens.
///
/// Displays the authenticated user's avatar + fullName.
/// Used in: CreateDiscussionScreen, CreateOpportunityScreen, CreateEventScreen.
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
    final bool hasNetwork = avatarUrl != null && avatarUrl.isNotEmpty;
    final String name = CurrentUser.name;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8),
          backgroundImage: hasNetwork
              ? NetworkImage(avatarUrl) as ImageProvider
              : const AssetImage('assets/images/user_profile.png'),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.public, color: textMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Public',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
