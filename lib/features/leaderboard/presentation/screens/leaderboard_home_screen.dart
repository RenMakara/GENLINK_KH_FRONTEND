import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';

class LeaderboardHomeScreen extends StatelessWidget {
  const LeaderboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _GrowthHeader(colors: colors)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _LevelCard(colors: colors),

                  const SizedBox(height: 12),

                  _DailyChallengeCard(colors: colors),

                  const SizedBox(height: 12),

                  _RecommendedPathCard(colors: colors),

                  const SizedBox(height: 18),

                  _SectionHeader(
                    title: 'Badges',
                    action: 'See all',
                    colors: colors,
                  ),

                  const SizedBox(height: 10),

                  _BadgesSection(colors: colors),

                  const SizedBox(height: 18),

                  _SectionHeader(
                    title: 'Leaderboard',
                    action: 'View all',
                    colors: colors,
                  ),

                  const SizedBox(height: 10),

                  _LeaderboardCard(colors: colors),

                  const SizedBox(height: 18),

                  _SectionHeader(
                    title: 'Short Lessons',
                    action: 'See all',
                    colors: colors,
                  ),

                  const SizedBox(height: 10),

                  _LessonsSection(colors: colors),

                  const SizedBox(height: 18),

                  _SectionHeader(
                    title: 'Recent XP',
                    action: null,
                    colors: colors,
                  ),

                  const SizedBox(height: 10),

                  _RecentXpCard(colors: colors),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  HEADER
class _GrowthHeader extends StatelessWidget {
  final AppSemanticColors colors;

  const _GrowthHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const AppBackButton(),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Growth',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Icon(
            Icons.notifications_none_rounded,
            size: 22,
            color: colors.secondaryText,
          ),
        ],
      ),
    );
  }
}

//  LEVEL CARD
class _LevelCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _LevelCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level Up',
                  style: TextStyle(
                    color: colors.textInverse.withValues(alpha: .7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.growthAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '7 days',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Level 4 - Builder',
            style: TextStyle(
              color: colors.textInverse,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: .68,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .25),
              valueColor: const AlwaysStoppedAnimation(AppColors.growthAccent),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '1,420 / 2,000 XP',
                style: TextStyle(
                  color: colors.textInverse.withValues(alpha: .7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '580 XP',
                style: TextStyle(
                  color: colors.textInverse.withValues(alpha: .7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  DAILY CHALLENGE
class _DailyChallengeCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _DailyChallengeCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Challenge',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Write 3 Financial Goals for This Week',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _Tag(text: 'FINANCE', color: AppColors.financeAccent),
              const SizedBox(width: 7),
              _XpTag(text: '+150 XP'),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textInverse,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Accept Challenge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  RECOMMENDED PATH
class _RecommendedPathCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _RecommendedPathCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Path',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Emergency Fund Fundamentals',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    color: colors.textInverse,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _Tag(text: 'FINANCE', color: AppColors.financeAccent),
              const SizedBox(width: 7),
              const _XpTag(text: '+100 XP'),
            ],
          ),
        ],
      ),
    );
  }
}

//  BADGES
class _BadgesSection extends StatelessWidget {
  final AppSemanticColors colors;

  const _BadgesSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final badges = [
      ('Starter', Icons.emoji_events_rounded),
      ('Creator', Icons.send_rounded),
      ('Builder', Icons.local_fire_department_rounded),
      ('Focus', Icons.lock_outline_rounded),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: badges.map((badge) {
        final locked = badge.$1 == 'Focus';

        return SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked ? colors.surface : colors.primary,
                  border: Border.all(
                    color: locked ? colors.borderStrong : colors.primary,
                  ),
                ),
                child: Icon(
                  badge.$2,
                  size: 20,
                  color: locked ? colors.textMuted : colors.textInverse,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                badge.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

//  LEADERBOARD
class _LeaderboardCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _LeaderboardCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final users = [
      ('#1', 'Kosal K.', '3,420 XP'),
      ('#2', 'Sora P.', '3,190 XP'),
      ('#3', 'Sela T.', '2,790 XP'),
    ];

    return _WhiteCard(
      colors: colors,
      padding: EdgeInsets.zero,
      child: Column(
        children: users.map((user) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    user.$1,
                    style: const TextStyle(
                      color: AppColors.growthAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.backgroundSecondary,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    user.$2,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.growthAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.$3,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

//  SHORT LESSONS
class _LessonsSection extends StatelessWidget {
  final AppSemanticColors colors;

  const _LessonsSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _LessonCard(
            colors: colors,
            title: '5 Habits of High Achievers',
            duration: '3 min',
          ),
          const SizedBox(width: 12),
          _LessonCard(
            colors: colors,
            title: 'Mastering Positive Thinking',
            duration: '4 min',
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final AppSemanticColors colors;
  final String title;
  final String duration;

  const _LessonCard({
    required this.colors,
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 225,
      child: _WhiteCard(
        colors: colors,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .18),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 11, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(color: colors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//  RECENT XP
class _RecentXpCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _RecentXpCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Completed Finance Quiz', '+100 XP'),
      ('Daily Challenge Done', '+150 XP'),
      ('7 Day Streak Bonus', '+50 XP'),
    ];

    return _WhiteCard(
      colors: colors,
      padding: EdgeInsets.zero,
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.backgroundSecondary,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: colors.secondaryText,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Today',
                        style: TextStyle(color: colors.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ),

                Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppColors.growthAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

//  COMMON WIDGETS
class _WhiteCard extends StatelessWidget {
  final Widget child;
  final AppSemanticColors colors;
  final EdgeInsetsGeometry padding;

  const _WhiteCard({
    required this.child,
    required this.colors,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: colors.cardShadow,
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final AppSemanticColors colors;

  const _SectionHeader({
    required this.title,
    required this.colors,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _XpTag extends StatelessWidget {
  final String text;

  const _XpTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.growthAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
