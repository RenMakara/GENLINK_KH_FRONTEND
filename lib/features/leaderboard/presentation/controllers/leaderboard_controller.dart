import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/leaderboard_models.dart';

class LeaderboardController extends GetxController {
  final selectedTab = LeaderboardTab.global.obs;
  final isLoading = false.obs;

  final currentUser = const LeaderboardUser(
    name: 'Thearaa',
    rank: 4,
    xp: 2200,
    level: 12,
    badges: 5,
    totalQuizzes: 48,
    streak: 7,
    country: 'Cambodia',
    countryFlag: '🇰🇭',
    topSubjects: ['Science', 'Technology', 'Math'],
    achievements: [
      Achievement(
        id: 'a1',
        title: 'Quiz Master',
        description: 'Answer 100 quizzes',
        icon: Icons.emoji_events,
        color: Color(0xFFFFD700),
      ),
      Achievement(
        id: 'a2',
        title: 'Speed Learner',
        description: 'Finish quiz < 60s',
        icon: Icons.bolt,
        color: Color(0xFF8B5CF6),
      ),
      Achievement(
        id: 'a3',
        title: 'Perfect Score',
        description: 'Get 100% in a quiz',
        icon: Icons.star,
        color: Color(0xFF10B981),
      ),
      Achievement(
        id: 'a4',
        title: 'Streak 7 Days',
        description: '7-day streak',
        icon: Icons.local_fire_department,
        color: Color(0xFFEF4444),
        isUnlocked: true,
      ),
      Achievement(
        id: 'a5',
        title: 'Knowledge King',
        description: 'Top 10 Global',
        icon: Icons.psychology,
        color: Color(0xFFF59E0B),
      ),
      Achievement(
        id: 'a6',
        title: 'Top 10 Global',
        description: 'Reach top 10',
        icon: Icons.public,
        color: Color(0xFF3B82F6),
      ),
    ],
    isCurrentUser: true,
  );

  late final RxList<LeaderboardUser> globalUsers;
  late final RxList<LeaderboardUser> friendsUsers;
  late final RxList<LeaderboardUser> countryUsers;

  @override
  void onInit() {
    super.onInit();
    _initMockData();
  }

  void _initMockData() {
    globalUsers = <LeaderboardUser>[
      const LeaderboardUser(
        name: 'Emma',
        rank: 1,
        xp: 4250,
        level: 24,
        badges: 28,
        totalQuizzes: 320,
        streak: 21,
        country: 'United States',
        countryFlag: '🇺🇸',
        quote: 'I love learning new things and challenging myself everyday ✨',
        topSubjects: ['Science', 'Math', 'Technology'],
        achievements: [
          Achievement(
            id: 'e1',
            title: 'Quiz Master',
            description: '100 quizzes',
            icon: Icons.emoji_events,
            color: Color(0xFFFFD700),
          ),
          Achievement(
            id: 'e2',
            title: 'Perfect Score',
            description: '100% accuracy',
            icon: Icons.star,
            color: Color(0xFF10B981),
          ),
          Achievement(
            id: 'e3',
            title: 'Streak 21',
            description: '21-day streak',
            icon: Icons.local_fire_department,
            color: Color(0xFFEF4444),
          ),
        ],
      ),
      const LeaderboardUser(
        name: 'Liam',
        rank: 2,
        xp: 3860,
        level: 20,
        badges: 22,
        totalQuizzes: 280,
        streak: 14,
        country: 'United Kingdom',
        countryFlag: '🇬🇧',
        topSubjects: ['History', 'Geography', 'Literature'],
        isFriend: true,
      ),
      const LeaderboardUser(
        name: 'Sophia',
        rank: 3,
        xp: 3430,
        level: 18,
        badges: 19,
        totalQuizzes: 245,
        streak: 10,
        country: 'Australia',
        countryFlag: '🇦🇺',
        topSubjects: ['Science', 'Technology', 'Math'],
        isFriend: true,
      ),
      currentUser,
      const LeaderboardUser(
        name: 'Noah',
        rank: 5,
        xp: 1950,
        level: 15,
        badges: 16,
        totalQuizzes: 180,
        streak: 8,
        country: 'Canada',
        countryFlag: '🇨🇦',
        topSubjects: ['Math', 'Science', 'History'],
      ),
      const LeaderboardUser(
        name: 'Olivia',
        rank: 6,
        xp: 1720,
        level: 14,
        badges: 14,
        totalQuizzes: 155,
        streak: 6,
        country: 'Germany',
        countryFlag: '🇩🇪',
        isFriend: true,
      ),
      const LeaderboardUser(
        name: 'William',
        rank: 7,
        xp: 1580,
        level: 13,
        badges: 12,
        totalQuizzes: 140,
        streak: 5,
        country: 'France',
        countryFlag: '🇫🇷',
        isFriend: true,
      ),
      const LeaderboardUser(
        name: 'James',
        rank: 8,
        xp: 1350,
        level: 12,
        badges: 10,
        totalQuizzes: 120,
        streak: 4,
        country: 'Japan',
        countryFlag: '🇯🇵',
      ),
      const LeaderboardUser(
        name: 'Benjamin',
        rank: 9,
        xp: 1180,
        level: 11,
        badges: 9,
        totalQuizzes: 105,
        streak: 3,
        country: 'South Korea',
        countryFlag: '🇰🇷',
      ),
      const LeaderboardUser(
        name: 'Charlotte',
        rank: 10,
        xp: 1020,
        level: 10,
        badges: 8,
        totalQuizzes: 90,
        streak: 1,
        country: 'Brazil',
        countryFlag: '🇧🇷',
      ),
    ].obs;

    friendsUsers = RxList<LeaderboardUser>(
      globalUsers.where((u) => u.isCurrentUser || u.isFriend).toList(),
    );
    countryUsers = RxList<LeaderboardUser>(
      globalUsers.where((u) => u.country == 'Cambodia').toList(),
    );
    if (countryUsers.isEmpty) {
      countryUsers = RxList<LeaderboardUser>([currentUser]);
    }
  }

  List<LeaderboardUser> get activeUsers {
    switch (selectedTab.value) {
      case LeaderboardTab.friends:
        return friendsUsers;
      case LeaderboardTab.country:
        return countryUsers;
      case LeaderboardTab.global:
        return globalUsers;
    }
  }

  LeaderboardUser? get topUser {
    return globalUsers.isNotEmpty ? globalUsers.first : null;
  }

  int get currentUserRank => currentUser.rank;
  int get totalGlobalUsers => 50;

  String get rankPercent {
    final pct = ((currentUser.rank / totalGlobalUsers) * 100).round();
    return 'Top $pct%';
  }

  String get countryRankPercent {
    final total = 15;
    final countryRank = 3;
    final pct = ((countryRank / total) * 100).round();
    return 'Top $pct%';
  }

  List<Achievement> get allAchievements => [
    const Achievement(
      id: 'all1',
      title: 'Quiz Master',
      description: 'Answer 100 quizzes',
      icon: Icons.emoji_events,
      color: Color(0xFFFFD700),
    ),
    const Achievement(
      id: 'all2',
      title: 'Speed Learner',
      description: 'Finish quiz < 60s',
      icon: Icons.bolt,
      color: Color(0xFF8B5CF6),
    ),
    const Achievement(
      id: 'all3',
      title: 'Perfect Score',
      description: 'Get 100% in a quiz',
      icon: Icons.star,
      color: Color(0xFF10B981),
    ),
    const Achievement(
      id: 'all4',
      title: 'Streak 7 Days',
      description: '7-day streak',
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
    ),
    const Achievement(
      id: 'all5',
      title: 'Knowledge King',
      description: 'Top 10 Global',
      icon: Icons.psychology,
      color: Color(0xFFF59E0B),
    ),
    const Achievement(
      id: 'all6',
      title: 'Top 10 Global',
      description: 'Reach top 10',
      icon: Icons.public,
      color: Color(0xFF3B82F6),
      isUnlocked: false,
    ),
    const Achievement(
      id: 'all7',
      title: 'Streak 30 Days',
      description: '30-day streak',
      icon: Icons.whatshot,
      color: Color(0xFFFF6D00),
      isUnlocked: false,
    ),
    const Achievement(
      id: 'all8',
      title: 'Scholar',
      description: 'Complete 500 quizzes',
      icon: Icons.school,
      color: Color(0xFF3B82F6),
      isUnlocked: false,
    ),
  ];
}
