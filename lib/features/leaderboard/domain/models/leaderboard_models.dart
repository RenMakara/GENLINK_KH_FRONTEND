import 'package:flutter/material.dart';

enum LeaderboardTab { global, friends, country }

class LeaderboardUser {
  final String name;
  final String avatarUrl;
  final int rank;
  final int xp;
  final int level;
  final int badges;
  final int totalQuizzes;
  final int streak;
  final String country;
  final String countryFlag;
  final String? quote;
  final List<String> topSubjects;
  final List<Achievement> achievements;
  final bool isCurrentUser;
  final bool isFriend;

  const LeaderboardUser({
    required this.name,
    this.avatarUrl = '',
    required this.rank,
    required this.xp,
    this.level = 1,
    this.badges = 0,
    this.totalQuizzes = 0,
    this.streak = 0,
    this.country = '',
    this.countryFlag = '',
    this.quote,
    this.topSubjects = const [],
    this.achievements = const [],
    this.isCurrentUser = false,
    this.isFriend = false,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = true,
    this.color = const Color(0xFF6C5CE7),
  });
}
