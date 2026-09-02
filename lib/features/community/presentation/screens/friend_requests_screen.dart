import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Data class representing a pending friend request.
class FriendRequestItem {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final int mutualFriends;
  final String timeAgo;
  bool isAccepted;

  FriendRequestItem({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.mutualFriends,
    required this.timeAgo,
    this.isAccepted = false,
  });
}

/// GenLink KH — Friend Requests Screen.
///
/// Clean, mobile-first screen for managing social friend requests.
/// Accessed when tapping friend-request notifications from the Unified Notification Center.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final List<FriendRequestItem> _requests = [
    FriendRequestItem(
      id: 'req_lina',
      name: 'Lina',
      username: 'lina.cambodia',
      avatarUrl: 'assets/images/user_profile.png',
      mutualFriends: 2,
      timeAgo: '2h ago',
    ),
    FriendRequestItem(
      id: 'req_sokha',
      name: 'Sokha Rith',
      username: 'sokha_rith',
      avatarUrl: 'assets/images/heng_chansela_profile.png',
      mutualFriends: 5,
      timeAgo: '1d ago',
    ),
    FriendRequestItem(
      id: 'req_bopha',
      name: 'Bopha Pich',
      username: 'bopha_p',
      avatarUrl: 'assets/images/ren_makara_profile.png',
      mutualFriends: 1,
      timeAgo: '2d ago',
    ),
  ];

  void _acceptRequest(FriendRequestItem item) {
    setState(() {
      item.isAccepted = true;
    });
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'friends.accepted'.tr.isNotEmpty &&
              'friends.accepted'.tr != 'friends.accepted'
          ? 'friends.accepted'.tr
          : 'Friend request accepted',
      message: '${item.name} is now your friend.',
    );
  }

  void _declineRequest(FriendRequestItem item) {
    setState(() {
      _requests.removeWhere((r) => r.id == item.id);
    });
    AppNotificationBanner.showInfo(
      context: context,
      title: 'friends.declined'.tr.isNotEmpty &&
              'friends.declined'.tr != 'friends.declined'
          ? 'friends.declined'.tr
          : 'Friend request declined',
      message: 'Request from ${item.name} removed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final pendingCount = _requests.where((r) => !r.isAccepted).length;
    final titleText = 'friends.requests'.tr.isNotEmpty &&
            'friends.requests'.tr != 'friends.requests'
        ? 'friends.requests'.tr
        : 'Friend Requests';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: const Center(child: AppBackButton()),
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE8E8E4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingCount',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: borderSubtle),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _requests.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: _requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      return _buildRequestCard(context, item, isDark);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    FriendRequestItem item,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final cardBorder =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5DF);

    final mutualText = 'friends.mutualFriends'.tr.isNotEmpty &&
            'friends.mutualFriends'.tr != 'friends.mutualFriends'
        ? 'friends.mutualFriends'.trParams({'count': '${item.mutualFriends}'})
        : '${item.mutualFriends} mutual friends';

    final acceptText = 'friends.accept'.tr.isNotEmpty &&
            'friends.accept'.tr != 'friends.accept'
        ? 'friends.accept'.tr
        : 'Accept';

    final declineText = 'friends.decline'.tr.isNotEmpty &&
            'friends.decline'.tr != 'friends.decline'
        ? 'friends.decline'.tr
        : 'Decline';

    final acceptedText = 'friends.accepted'.tr.isNotEmpty &&
            'friends.accepted'.tr != 'friends.accepted'
        ? 'friends.accepted'.tr
        : 'Friends';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Name, Username, Time
          InkWell(
            onTap: () =>
                Get.to(() => ProfileScreen(viewingUsername: item.username)),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4DE),
                  backgroundImage: item.avatarUrl != null
                      ? AssetImage(item.avatarUrl!) as ImageProvider
                      : const AssetImage('assets/images/user_profile.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${item.username}',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.timeAgo,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 2: Mutual friends context
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                mutualText,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Action Buttons
          if (item.isAccepted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF242424)
                    : const Color(0xFFEDEDEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    acceptedText,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF111111),
                        foregroundColor: isDark
                            ? const Color(0xFF111111)
                            : const Color(0xFFFFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        acceptText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => _declineRequest(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFD6D6D0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        declineText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    final title = 'friends.noRequests'.tr.isNotEmpty &&
            'friends.noRequests'.tr != 'friends.noRequests'
        ? 'friends.noRequests'.tr
        : 'No pending friend requests';

    final desc = 'friends.noRequestsDesc'.tr.isNotEmpty &&
            'friends.noRequestsDesc'.tr != 'friends.noRequestsDesc'
        ? 'friends.noRequestsDesc'.tr
        : 'When people send you friend requests, they will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
