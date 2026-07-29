class EventModel {
  final String id;
  final String title;
  final String organizerName;
  final String location;
  final String dateString;
  final String timeString;
  final bool isPaid;
  final double priceKhr;
  final String imageUrl;
  final int attendeesCount;
  bool isRsvped;

  EventModel({
    required this.id,
    required this.title,
    required this.organizerName,
    required this.location,
    required this.dateString,
    required this.timeString,
    this.isPaid = false,
    this.priceKhr = 0.0,
    required this.imageUrl,
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
