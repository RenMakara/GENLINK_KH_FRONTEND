import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';
import '../../../../features/quiz/presentation/widgets/quiz_icon_container.dart';
import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';

class LeaderboardHomeScreen extends GetView<LeaderboardController> {
  const LeaderboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'quiz.leaderboard'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_events_outlined, color: scheme.primary),
            onPressed: () => Get.toNamed('/leaderboard/achievements'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        }

        final users = controller.activeUsers;
        final isGlobal = controller.selectedTab.value == LeaderboardTab.global;
        final isFriends =
            controller.selectedTab.value == LeaderboardTab.friends;
        final isCountry =
            controller.selectedTab.value == LeaderboardTab.country;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildSegmentedTabs(scheme),
              const SizedBox(height: 20),
              if (isCountry) _buildCountryHeader(scheme),
              if (isGlobal) _buildPodium(users, scheme),
              const SizedBox(height: 20),
              _buildRankedList(users, scheme),
              if (isFriends) _buildInviteBanner(scheme),
              if (isCountry) _buildCountryBanner(scheme),
              const SizedBox(height: 16),
              if (isGlobal) _buildFullLeaderboardButton(),
              _buildBottomBanner(isGlobal, isCountry, scheme),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSegmentedTabs(ColorScheme scheme) {
    final tabs = controller.selectedTab.value;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _buildTab(
            'leaderboard.global'.tr,
            LeaderboardTab.global,
            tabs,
            scheme,
          ),
          _buildTab(
            'leaderboard.friends'.tr,
            LeaderboardTab.friends,
            tabs,
            scheme,
          ),
          _buildTab(
            'leaderboard.country'.tr,
            LeaderboardTab.country,
            tabs,
            scheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label,
    LeaderboardTab tab,
    LeaderboardTab active,
    ColorScheme scheme,
  ) {
    final isActive = tab == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = tab,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryHeader(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🇰🇭', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'leaderboard.cambodiaRanking'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardUser> users, ColorScheme scheme) {
    if (users.length < 3) return const SizedBox.shrink();

    final first = users[0];
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurface(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: SizedBox(
          height: 230,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildPodiumItem(
                  second!,
                  2,
                  _silverGradient,
                  const Color(0xFF9CA3AF),
                  scheme,
                ),
              ),
              Expanded(
                child: _buildPodiumItem(
                  first,
                  1,
                  _goldGradient,
                  const Color(0xFFFFC107),
                  scheme,
                ),
              ),
              Expanded(
                child: _buildPodiumItem(
                  third!,
                  3,
                  _bronzeGradient,
                  const Color(0xFFD97706),
                  scheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardUser user,
    int rank,
    LinearGradient gradient,
    Color accent,
    ColorScheme scheme,
  ) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 72.0 : 56.0;
    final crownSize = isFirst ? 20.0 : 14.0;

    return GestureDetector(
      onTap: () => Get.toNamed('/leaderboard/profile', arguments: user),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉'),
            style: TextStyle(fontSize: crownSize),
          ),
          const SizedBox(height: 4),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: accent, width: 2),
            ),
            child: Icon(Icons.person, color: scheme.onPrimary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${user.xp} XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankedList(List<LeaderboardUser> users, ColorScheme scheme) {
    final listUsers = users.length > 3 ? users.sublist(3) : <LeaderboardUser>[];

    return Column(
      children: [
        if (users.length <= 3)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'leaderboard.noMoreUsers'.tr,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ...listUsers.map((user) => _buildRankRow(user, scheme)),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardUser user, ColorScheme scheme) {
    final isMe = user.isCurrentUser;
    return GestureDetector(
      onTap: () => Get.toNamed('/leaderboard/profile', arguments: user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? scheme.primary : scheme.outlineVariant,
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: isMe ? [] : _cardShadow(scheme),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMe ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${user.rank}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isMe ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _primaryGradient(scheme),
              ),
              child: Icon(Icons.person, color: scheme.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                      color: isMe ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    '${user.xp} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'quiz.you'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteBanner(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: _cardShadow(scheme),
      ),
      child: Row(
        children: [
          QuizIconContainer(
            icon: Icons.celebration,
            accentColor: scheme.primary,
            size: 48,
            iconSize: 26,
            borderRadius: AppRadius.lg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leaderboard.inviteFriends'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'leaderboard.competeOnLeaderboard'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'leaderboard.invite'.tr,
            expanded: false,
            height: 44,
            radius: AppRadius.pill,
            onPressed: () => Get.toNamed('/leaderboard/invite'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryBanner(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🇰🇭', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leaderboard.yourCountryRank'.trParams({'rank': '3'}),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.countryRankPercent,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }

  Widget _buildFullLeaderboardButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: AppButton(
        label: 'leaderboard.viewFull'.tr,
        height: 52,
        radius: AppRadius.pill,
        onPressed: () => Get.toNamed('/leaderboard/ranking'),
      ),
    );
  }

  Widget _buildBottomBanner(bool isGlobal, bool isCountry, ColorScheme scheme) {
    String text;
    if (isCountry) {
      text = 'leaderboard.yourRankBanner'.trParams({
        'rank': '3',
        'percent': controller.countryRankPercent,
      });
    } else {
      text = 'leaderboard.yourRankBanner'.trParams({
        'rank': '${controller.currentUserRank}',
        'percent': controller.rankPercent,
      });
    }

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: scheme.primary, size: 14),
        ],
      ),
    );
  }

  LinearGradient _primaryGradient(ColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<BoxShadow> _cardShadow(ColorScheme scheme) {
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _silverGradient = LinearGradient(
    colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _bronzeGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
