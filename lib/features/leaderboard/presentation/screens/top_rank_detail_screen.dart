import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/leaderboard_models.dart';
import '../../../quiz/presentation/quiz_colors.dart';

class TopRankDetailScreen extends StatefulWidget {
  const TopRankDetailScreen({super.key});

  @override
  State<TopRankDetailScreen> createState() => _TopRankDetailScreenState();
}

class _TopRankDetailScreenState extends State<TopRankDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.arguments as LeaderboardUser?;
    if (user == null) return const SizedBox.shrink();

    final isFirst = user.rank == 1;
    final isMe = user.isCurrentUser;
    final isFriend = user.isFriend;

    return Scaffold(
      backgroundColor: QuizColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (isFirst)
                  _buildHeroHeader(user)
                else
                  _buildStandardHeader(user),
                _buildMetricCards(user),
                const SizedBox(height: 16),
                if (isFirst && user.quote != null) _buildAboutSection(user),
                if (user.topSubjects.isNotEmpty) _buildTopSubjects(user),
                if (isFirst && user.achievements.isNotEmpty)
                  _buildRecentAchievements(user),
                if (!isFirst) ...[
                  const SizedBox(height: 16),
                  _buildAchievementsSection(user),
                ],
                const SizedBox(height: 28),
                if (!isMe) _buildActionButton(user, isFirst, isFriend),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Get.back(),
<<<<<<< Updated upstream
                  child: const Text(
                    'Back to Leaderboard',
                    style: TextStyle(
=======
                  child: Text(
                    'leaderboard.backToLeaderboard'.tr,
                    style: const TextStyle(
>>>>>>> Stashed changes
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QuizColors.body,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardHeader(LeaderboardUser user) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: user.isCurrentUser
                ? QuizColors.gradient
                : const LinearGradient(
                    colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
                  ),
            boxShadow: [
              BoxShadow(
                color: QuizColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: QuizColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: QuizColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
<<<<<<< Updated upstream
            'Global Rank #${user.rank}  ·  ${user.countryFlag} ${user.country}',
=======
            'leaderboard.globalRankWithCountry'.trParams({
              'rank': '${user.rank}',
              'flag': user.countryFlag,
              'country': user.country,
            }),
>>>>>>> Stashed changes
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: QuizColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeroHeader(LeaderboardUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x306C5CE7), Color(0x00F5F3FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
              onPressed: () => Get.back(),
              padding: const EdgeInsets.only(left: 8),
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 48),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFFA000)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
<<<<<<< Updated upstream
                        'Global Rank #1',
                        style: TextStyle(
=======
                        'quiz.globalRank'.trParams({'rank': '1'}),
                        style: const TextStyle(
>>>>>>> Stashed changes
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: QuizColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: QuizColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
<<<<<<< Updated upstream
                '${user.xp} XP  ·  Lv.${user.level}',
=======
                '${user.xp} XP  ·  ${'leaderboard.levelValue'.trParams({'level': '${user.level}'})}',
>>>>>>> Stashed changes
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: QuizColors.body,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(LeaderboardUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildMetricItem(
            '${user.totalQuizzes}',
<<<<<<< Updated upstream
            'Quizzes',
=======
            'quiz.quizzes'.tr,
>>>>>>> Stashed changes
            QuizColors.primary,
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '${user.xp} XP',
            'leaderboard.experience'.tr,
            QuizColors.gold,
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '${user.badges}',
            'quiz.badges'.tr,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: QuizColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuizColors.border),
          boxShadow: QuizColors.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: QuizColors.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(LeaderboardUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: QuizColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuizColors.border),
          boxShadow: QuizColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            const Text(
              'About',
              style: TextStyle(
=======
            Text(
              'leaderboard.about'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.quote!,
              style: const TextStyle(
                fontSize: 14,
                color: QuizColors.body,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSubjects(LeaderboardUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
<<<<<<< Updated upstream
            child: const Text(
              'Top Subjects',
              style: TextStyle(
=======
            child: Text(
              'leaderboard.topSubjects'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.topSubjects.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: QuizColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: QuizColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: QuizColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(LeaderboardUser user) {
    final achievements = user.achievements.take(3).toList();
    if (achievements.isEmpty) return const SizedBox.shrink();

    final iconColors = const [
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
<<<<<<< Updated upstream
            child: const Text(
              'Recent Achievements',
              style: TextStyle(
=======
            child: Text(
              'leaderboard.recentAchievements'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
          ),
          Row(
            children: List.generate(achievements.length, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < achievements.length - 1 ? 10 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: QuizColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: QuizColors.border),
                    boxShadow: QuizColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconColors[i % iconColors.length].withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          achievements[i].icon,
                          color: iconColors[i % iconColors.length],
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievements[i].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: QuizColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(LeaderboardUser user) {
    final achievements = user.achievements.take(4).toList();
    if (achievements.isEmpty) return const SizedBox.shrink();

    final colors = const [
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: QuizColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuizColors.border),
          boxShadow: QuizColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            const Text(
              'Achievements',
              style: TextStyle(
=======
            Text(
              'quiz.achievements'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: achievements.map((a) {
                final i = achievements.indexOf(a) % colors.length;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < achievements.length - 1 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colors[i].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(a.icon, color: colors[i], size: 24),
                        const SizedBox(height: 6),
                        Text(
                          a.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors[i],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(LeaderboardUser user, bool isFirst, bool isFriend) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Container(
          decoration: BoxDecoration(
            gradient: isFirst
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  )
                : QuizColors.gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFirst
                          ? Icons.bolt
                          : (isFriend
                                ? Icons.message_outlined
                                : Icons.person_add),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFirst
<<<<<<< Updated upstream
                          ? 'Challenge Emma'
                          : (isFriend ? 'Message' : 'Add Friend'),
=======
                          ? 'leaderboard.challengeUser'.trParams({
                              'name': user.name,
                            })
                          : (isFriend
                                ? 'leaderboard.message'.tr
                                : 'leaderboard.addFriend'.tr),
>>>>>>> Stashed changes
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
