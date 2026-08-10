// ignore: depend_on_referenced_packages
import 'dart:io';

class EventModel {
  final String id;
  final String title;
  final String subtitle;
  final String organizerName;

  /// 'Online' or 'In person'
  final String eventType;

  /// Physical address — used when eventType == 'In person'
  final String location;

  /// URL — used when eventType == 'Online'
  final String onlineLink;

  final String dateString;
  final String timeString;
  final String description;
  final String category;
  final bool isPaid;
  final double priceKhr;

  /// Network URL or empty string for placeholder
  final String imageUrl;

  /// Local gallery file — used immediately after creation before any upload
  final File? coverImageFile;

  int attendeesCount;
  bool isRsvped;

  EventModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.organizerName,
    this.eventType = 'In person',
    this.location = '',
    this.onlineLink = '',
    required this.dateString,
    required this.timeString,
    this.description = '',
    this.category = '',
    this.isPaid = false,
    this.priceKhr = 0.0,
    this.imageUrl = '',
    this.coverImageFile,
    this.attendeesCount = 0,
    this.isRsvped = false,
  });
}

class ForumTopicModel {
  final String id;
  final String title;
  final String authorName;
  final String category;
  final String content;
  final int upvotes;
  final int repliesCount;
  final String timeAgo;

  ForumTopicModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.category,
    required this.content,
    this.upvotes = 0,
    this.repliesCount = 0,
    required this.timeAgo,
  });
}

class SkillTutorialModel {
  final String id;
  final String title;
  final String authorName;
  final String category;
  final String duration;
  final int xpReward;
  final int likesCount;
  final String coverUrl;

  SkillTutorialModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.category,
    required this.duration,
    this.xpReward = 25,
    this.likesCount = 0,
    required this.coverUrl,
  });
}

class CareerGoalModel {
  final String id;
  final String title;
  final String authorName;
  final double progress; // 0.0 to 1.0
  final int cheersCount;
  final String targetDate;

  CareerGoalModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.progress,
    this.cheersCount = 0,
    required this.targetDate,
  });
}
