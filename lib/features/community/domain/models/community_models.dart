// ignore: depend_on_referenced_packages
import 'dart:io';

import '../../../finance/domain/entities/finance_entities.dart';

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

  /// Backend event contract. The legacy dateString/timeString fields remain
  /// for the existing cards, while these values are used for API writes.
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final double? latitude;
  final double? longitude;

  final String dateString;
  final String timeString;
  final String description;
  final String category;
  final bool isPaid;
  final double price;
  final FinanceCurrency currency;

  /// Network URL or empty string for placeholder
  final String imageUrl;

  /// Local gallery file — used immediately after creation before any upload
  final File? coverImageFile;

  int attendeesCount;
  bool isRsvped;
  bool isBookmarked;
  final List<String> attendeeAvatars;

  EventModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.organizerName,
    this.eventType = 'In person',
    this.location = '',
    this.onlineLink = '',
    this.startDateTime,
    this.endDateTime,
    this.latitude,
    this.longitude,
    required this.dateString,
    required this.timeString,
    this.description = '',
    this.category = '',
    this.isPaid = false,
    this.price = 0.0,
    this.currency = FinanceCurrency.usd,
    this.imageUrl = '',
    this.coverImageFile,
    this.attendeesCount = 0,
    this.isRsvped = false,
    this.isBookmarked = false,
    this.attendeeAvatars = const [],
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? organizerName,
    String? eventType,
    String? location,
    String? onlineLink,
    DateTime? startDateTime,
    DateTime? endDateTime,
    double? latitude,
    double? longitude,
    String? dateString,
    String? timeString,
    String? description,
    String? category,
    bool? isPaid,
    double? price,
    FinanceCurrency? currency,
    String? imageUrl,
    File? coverImageFile,
    int? attendeesCount,
    bool? isRsvped,
    bool? isBookmarked,
    List<String>? attendeeAvatars,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      organizerName: organizerName ?? this.organizerName,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      onlineLink: onlineLink ?? this.onlineLink,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateString: dateString ?? this.dateString,
      timeString: timeString ?? this.timeString,
      description: description ?? this.description,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImageFile: coverImageFile ?? this.coverImageFile,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      isRsvped: isRsvped ?? this.isRsvped,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
    );
  }
}

/// Payload used by the event creation API. Keeping it in the domain layer
/// prevents screens from depending on JSON field names.
class EventCreateInput {
  final String title;
  final String description;
  final String category;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String eventType;
  final String? meetingUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool paid;
  final double? price;
  final FinanceCurrency? currency;
  final int? attendeeLimit;

  const EventCreateInput({
    required this.title,
    this.description = '',
    this.category = '',
    required this.startDateTime,
    required this.endDateTime,
    required this.eventType,
    this.meetingUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.paid = false,
    this.price,
    this.currency,
    this.attendeeLimit,
  });
}

/// Payload used by the full event registration form.
class EventRegistrationInput {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String university;
  final String faculty;
  final String studyYear;
  final bool termsAccepted;

  const EventRegistrationInput({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.university,
    required this.faculty,
    required this.studyYear,
    required this.termsAccepted,
  });
}

class EventRsvpResult {
  final String eventId;
  final String status;
  final int attendeeCount;
  final int xpAwarded;
  final double? chargedAmount;
  final bool paymentSimulated;

  const EventRsvpResult({
    required this.eventId,
    required this.status,
    required this.attendeeCount,
    required this.xpAwarded,
    this.chargedAmount,
    required this.paymentSimulated,
  });
}

class ForumTopicModel {
  final String id;
  final String? authorId;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String category;
  final String content;
  int upvotes;
  int repliesCount;
  final String timeAgo;
  bool isLiked;
  final bool isPinned;
  final bool isOwner;

  ForumTopicModel({
    required this.id,
    this.authorId,
    required this.title,
    required this.authorName,
    this.authorAvatar = 'assets/images/user_profile.png',
    required this.category,
    required this.content,
    this.upvotes = 0,
    this.repliesCount = 0,
    required this.timeAgo,
    this.isLiked = false,
    this.isPinned = false,
    this.isOwner = false,
  });

  /// Evaluates whether the given user ID matches this discussion's author ID.
  /// Uses stable author ID comparison when available, and respects session ownership.
  bool checkIsOwner(String? currentUserId) {
    if (authorId != null && authorId!.isNotEmpty) {
      if (currentUserId != null && currentUserId.isNotEmpty) {
        if (authorId == currentUserId) return true;
      }
      if (authorId == 'user_me' ||
          authorId == 'current_user' ||
          authorId == 'demo_user_1') {
        return true;
      }
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          authorId != currentUserId) {
        return false;
      }
    }
    return isOwner;
  }

  ForumTopicModel copyWith({
    String? id,
    String? authorId,
    String? title,
    String? authorName,
    String? authorAvatar,
    String? category,
    String? content,
    int? upvotes,
    int? repliesCount,
    String? timeAgo,
    bool? isLiked,
    bool? isPinned,
    bool? isOwner,
  }) {
    return ForumTopicModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      content: content ?? this.content,
      upvotes: upvotes ?? this.upvotes,
      repliesCount: repliesCount ?? this.repliesCount,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      isPinned: isPinned ?? this.isPinned,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
    final authorObj = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;
    final authorName =
        authorObj?['fullName'] as String? ??
        json['authorName'] as String? ??
        json['username'] as String? ??
        'User';
    final authorAvatar =
        authorObj?['avatarUrl'] as String? ??
        json['authorAvatar'] as String? ??
        'assets/images/user_profile.png';
    final authorId =
        authorObj?['userId'] as String? ??
        json['authorId'] as String? ??
        json['userId'] as String?;

    return ForumTopicModel(
      id: json['discussionId'] as String? ?? json['id'] as String? ?? '',
      authorId: authorId,
      title: json['title'] as String? ?? '',
      authorName: authorName,
      authorAvatar: authorAvatar.isNotEmpty
          ? authorAvatar
          : 'assets/images/user_profile.png',
      category: json['category'] as String? ?? 'General',
      content: json['content'] as String? ?? '',
      upvotes:
          json['reactionCount'] as int? ??
          json['upvotes'] as int? ??
          json['likesCount'] as int? ??
          0,
      repliesCount:
          json['commentCount'] as int? ??
          json['repliesCount'] as int? ??
          json['commentsCount'] as int? ??
          0,
      timeAgo:
          json['timeAgo'] as String? ??
          json['createdAt'] as String? ??
          'Just now',
      isLiked:
          json['reactedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isOwner: json['mine'] as bool? ?? json['isOwner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussionId': id,
      'authorId': authorId,
      'title': title,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'category': category,
      'content': content,
      'upvotes': upvotes,
      'repliesCount': repliesCount,
      'timeAgo': timeAgo,
      'isLiked': isLiked,
      'isPinned': isPinned,
      'isOwner': isOwner,
    };
  }
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
