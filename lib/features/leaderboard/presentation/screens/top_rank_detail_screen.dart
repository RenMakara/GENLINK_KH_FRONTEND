import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/leaderboard_models.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final user = Get.arguments as LeaderboardUser?;
    if (user == null) return const SizedBox.shrink();

    final isFirst = user.rank == 1;
    final isMe = user.isCurrentUser;
    final isFriend = user.isFriend;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (isFirst)
                  _buildHeroHeader(user, scheme)
                else
                  _buildStandardHeader(user, scheme),
                _buildMetricCards(user, scheme),
                const SizedBox(height: 16),
                if (isFirst && user.quote != null)
                  _buildAboutSection(user, scheme),
                if (user.topSubjects.isNotEmpty)
                  _buildTopSubjects(user, scheme),
                if (isFirst && user.achievements.isNotEmpty)
                  _buildRecentAchievements(user, scheme),
                if (!isFirst) ...[
                  const SizedBox(height: 16),
                  _buildAchievementsSection(user, scheme),
                ],
                const SizedBox(height: 28),
                if (!isMe) _buildActionButton(user, isFirst, isFriend, scheme),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'leaderboard.backToLeaderboard'.tr,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
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

  Widget _buildStandardHeader(LeaderboardUser user, ColorScheme scheme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: user.isCurrentUser
                ? _primaryGradient(scheme)
                : const LinearGradient(
                    colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
                  ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.person, color: scheme.onPrimary, size: 42),
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            'leaderboard.globalRankWithCountry'.trParams({
              'rank': '${user.rank}',
              'flag': user.countryFlag,
              'country': user.country,
            }),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeroHeader(LeaderboardUser user, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.surface.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: scheme.onSurface),
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
                child: Icon(Icons.person, color: scheme.onPrimary, size: 48),
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
                      Icon(
                        Icons.emoji_events,
                        color: scheme.onPrimary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'quiz.globalRank'.trParams({'rank': '1'}),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
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
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: const Color(0xFFFFC107), size: 16),
              const SizedBox(width: 6),
              Text(
                '${user.xp} XP  ·  ${'leaderboard.levelValue'.trParams({'level': '${user.level}'})}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(LeaderboardUser user, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildMetricItem(
            '${user.totalQuizzes}',
            'quiz.quizzes'.tr,
            scheme.primary,
            scheme,
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '${user.xp} XP',
            'leaderboard.experience'.tr,
            const Color(0xFFFFC107),
            scheme,
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '${user.badges}',
            'quiz.badges'.tr,
            const Color(0xFFF59E0B),
            scheme,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String value,
    String label,
    Color color,
    ColorScheme scheme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: _cardShadow(scheme),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(LeaderboardUser user, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: _cardShadow(scheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'leaderboard.about'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.quote!,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSubjects(LeaderboardUser user, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'leaderboard.topSubjects'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
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

  Widget _buildRecentAchievements(LeaderboardUser user, ColorScheme scheme) {
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
            child: Text(
              'leaderboard.recentAchievements'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: _cardShadow(scheme),
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
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

  Widget _buildAchievementsSection(LeaderboardUser user, ColorScheme scheme) {
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
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: _cardShadow(scheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quiz.achievements'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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

  Widget _buildActionButton(
    LeaderboardUser user,
    bool isFirst,
    bool isFriend,
    ColorScheme scheme,
  ) {
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
                : _primaryGradient(scheme),
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
                      color: scheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFirst
                          ? 'leaderboard.challengeUser'.trParams({
                              'name': user.name,
                            })
                          : (isFriend
                                ? 'leaderboard.message'.tr
                                : 'leaderboard.addFriend'.tr),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary,
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
}
