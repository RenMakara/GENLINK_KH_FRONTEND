import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';
import '../../../quiz/presentation/quiz_colors.dart';

class LeaderboardHomeScreen extends GetView<LeaderboardController> {
  const LeaderboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'quiz.leaderboard'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: QuizColors.primary,
            ),
            onPressed: () => Get.toNamed('/leaderboard/achievements'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: QuizColors.primary),
          );
        }

        final users = controller.activeUsers;
        final isGlobal = controller.selectedTab.value == LeaderboardTab.global;
        final isFriends =
            controller.selectedTab.value == LeaderboardTab.friends;
        final isCountry =
            controller.selectedTab.value == LeaderboardTab.country;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildSegmentedTabs(),
              const SizedBox(height: 20),
              if (isCountry) _buildCountryHeader(),
              if (isGlobal) _buildPodium(users),
              const SizedBox(height: 20),
              _buildRankedList(users),
              if (isFriends) _buildInviteBanner(),
              if (isCountry) _buildCountryBanner(),
              const SizedBox(height: 16),
              if (isGlobal) _buildFullLeaderboardButton(),
              _buildBottomBanner(isGlobal, isCountry),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSegmentedTabs() {
    final tabs = controller.selectedTab.value;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAFD),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _buildTab('leaderboard.global'.tr, LeaderboardTab.global, tabs),
          _buildTab('leaderboard.friends'.tr, LeaderboardTab.friends, tabs),
          _buildTab('leaderboard.country'.tr, LeaderboardTab.country, tabs),
        ],
      ),
    );
  }

  Widget _buildTab(String label, LeaderboardTab tab, LeaderboardTab active) {
    final isActive = tab == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = tab,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? QuizColors.primary : Colors.transparent,
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
                color: isActive ? Colors.white : QuizColors.body,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QuizColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🇰🇭', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'leaderboard.cambodiaRanking'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardUser> users) {
    if (users.length < 3) return const SizedBox.shrink();

    final first = users[0];
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return SizedBox(
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
            ),
          ),
          Expanded(
            child: _buildPodiumItem(
              first,
              1,
              _goldGradient,
              const Color(0xFFFFC107),
            ),
          ),
          Expanded(
            child: _buildPodiumItem(
              third!,
              3,
              _bronzeGradient,
              const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardUser user,
    int rank,
    LinearGradient gradient,
    Color accent,
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
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
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

  Widget _buildRankedList(List<LeaderboardUser> users) {
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
                color: QuizColors.body.withValues(alpha: 0.7),
              ),
            ),
          ),
        ...listUsers.map((user) => _buildRankRow(user)),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardUser user) {
    final isMe = user.isCurrentUser;
    return GestureDetector(
      onTap: () => Get.toNamed('/leaderboard/profile', arguments: user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? QuizColors.primaryLight : QuizColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? QuizColors.primary : QuizColors.border,
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: isMe ? [] : QuizColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMe ? QuizColors.primary : QuizColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${user.rank}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white : QuizColors.body,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: QuizColors.gradient,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                      color: isMe ? QuizColors.primary : QuizColors.heading,
                    ),
                  ),
                  Text(
                    '${user.xp} XP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: QuizColors.body,
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
                  color: QuizColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'quiz.you'.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.border),
        boxShadow: QuizColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: QuizColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.celebration,
              color: QuizColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leaderboard.inviteFriends'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: QuizColors.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'leaderboard.competeOnLeaderboard'.tr,
                  style: const TextStyle(fontSize: 13, color: QuizColors.body),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed('/leaderboard/invite'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: QuizColors.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'leaderboard.invite'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: QuizColors.primary.withValues(alpha: 0.15),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: QuizColors.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.countryRankPercent,
                  style: const TextStyle(fontSize: 13, color: QuizColors.body),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: QuizColors.body, size: 22),
        ],
      ),
    );
  }

  Widget _buildFullLeaderboardButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            gradient: QuizColors.gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed('/leaderboard/ranking'),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  'leaderboard.viewFull'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBanner(bool isGlobal, bool isCountry) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.border),
        boxShadow: QuizColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: QuizColors.body,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            color: QuizColors.primary,
            size: 14,
          ),
        ],
      ),
    );
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
