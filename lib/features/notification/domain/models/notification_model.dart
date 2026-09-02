enum NotificationCategory {
  all,
  social,
  finance,
  events,
  reminders,
  updates,
}

enum NotificationType {
  // Social
  like,
  comment,
  reply,
  mention,
  friendRequest,
  follow,
  group,
  // Finance
  budgetWarning,
  budgetExceeded,
  savingGoal,
  financeUpdate,
  // Events
  eventReminder,
  eventUpdate,
  eventRsvp,
  event,
  // Reminders
  habitReminder,
  taskReminder,
  goalReminder,
  streakMilestone,
  // Updates
  quizResult,
  achievement,
  system,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get tabName {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.social:
        return 'Social';
      case NotificationCategory.finance:
        return 'Finance';
      case NotificationCategory.events:
        return 'Events';
      case NotificationCategory.reminders:
        return 'Reminders';
      case NotificationCategory.updates:
        return 'Updates';
    }
  }

  String get translationKey {
    switch (this) {
      case NotificationCategory.all:
        return 'notification.categoryAll';
      case NotificationCategory.social:
        return 'notification.categorySocial';
      case NotificationCategory.finance:
        return 'notification.categoryFinance';
      case NotificationCategory.events:
        return 'notification.categoryEvents';
      case NotificationCategory.reminders:
        return 'notification.categoryReminders';
      case NotificationCategory.updates:
        return 'notification.categoryUpdates';
    }
  }
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String body;
  final String? contextText;
  final String senderName;
  final String? senderAvatar;
  final String timeAgo;
  final DateTime timestamp;
  bool isRead;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    NotificationCategory? category,
    required this.title,
    required this.body,
    this.contextText,
    required this.senderName,
    this.senderAvatar,
    required this.timeAgo,
    required this.timestamp,
    this.isRead = false,
    this.targetId,
    this.targetType,
    this.metadata,
  }) : category = category ?? _resolveCategory(type);

  static NotificationCategory _resolveCategory(NotificationType type) {
    switch (type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.reply:
      case NotificationType.mention:
      case NotificationType.friendRequest:
      case NotificationType.follow:
      case NotificationType.group:
        return NotificationCategory.social;
      case NotificationType.budgetWarning:
      case NotificationType.budgetExceeded:
      case NotificationType.savingGoal:
      case NotificationType.financeUpdate:
        return NotificationCategory.finance;
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventRsvp:
      case NotificationType.event:
        return NotificationCategory.events;
      case NotificationType.habitReminder:
      case NotificationType.taskReminder:
      case NotificationType.goalReminder:
      case NotificationType.streakMilestone:
        return NotificationCategory.reminders;
      case NotificationType.quizResult:
      case NotificationType.achievement:
      case NotificationType.system:
        return NotificationCategory.updates;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? raw) {
      final key = raw?.toLowerCase().replaceAll('_', '').replaceAll('-', '') ?? '';
      switch (key) {
        case 'like':
          return NotificationType.like;
        case 'comment':
          return NotificationType.comment;
        case 'reply':
          return NotificationType.reply;
        case 'mention':
          return NotificationType.mention;
        case 'friendrequest':
        case 'friend':
          return NotificationType.friendRequest;
        case 'follow':
          return NotificationType.follow;
        case 'group':
          return NotificationType.group;
        case 'budgetwarning':
        case 'budgetalert':
          return NotificationType.budgetWarning;
        case 'budgetexceeded':
          return NotificationType.budgetExceeded;
        case 'savinggoal':
        case 'goal':
          return NotificationType.savingGoal;
        case 'finance':
        case 'financeupdate':
          return NotificationType.financeUpdate;
        case 'eventreminder':
          return NotificationType.eventReminder;
        case 'eventupdate':
          return NotificationType.eventUpdate;
        case 'eventrsvp':
        case 'rsvp':
          return NotificationType.eventRsvp;
        case 'event':
          return NotificationType.event;
        case 'habitreminder':
        case 'habit':
          return NotificationType.habitReminder;
        case 'taskreminder':
        case 'task':
          return NotificationType.taskReminder;
        case 'goalreminder':
          return NotificationType.goalReminder;
        case 'streakmilestone':
        case 'streak':
          return NotificationType.streakMilestone;
        case 'quizresult':
        case 'quiz':
          return NotificationType.quizResult;
        case 'achievement':
          return NotificationType.achievement;
        case 'system':
        default:
          return NotificationType.system;
      }
    }

    NotificationCategory? parseCategory(String? raw) {
      switch (raw?.toLowerCase()) {
        case 'social':
          return NotificationCategory.social;
        case 'finance':
          return NotificationCategory.finance;
        case 'events':
        case 'event':
          return NotificationCategory.events;
        case 'reminders':
        case 'reminder':
          return NotificationCategory.reminders;
        case 'updates':
        case 'update':
          return NotificationCategory.updates;
        case 'all':
          return NotificationCategory.all;
        default:
          return null;
      }
    }

    final parsedType = parseType(json['type'] as String?);
    final parsedCategory = parseCategory(json['category'] as String?) ??
        _resolveCategory(parsedType);

    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: parsedType,
      category: parsedCategory,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      contextText: json['contextText'] as String? ?? json['context'] as String? ?? json['subtitle'] as String?,
      senderName: json['senderName'] as String? ?? 'GenLink KH',
      senderAvatar: json['senderAvatar'] as String?,
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'title': title,
      'body': body,
      'contextText': contextText,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timeAgo': timeAgo,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? body,
    String? contextText,
    String? senderName,
    String? senderAvatar,
    String? timeAgo,
    DateTime? timestamp,
    bool? isRead,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      contextText: contextText ?? this.contextText,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      metadata: metadata ?? this.metadata,
    );
  }
}
