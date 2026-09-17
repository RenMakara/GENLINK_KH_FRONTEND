enum NotificationCategory {
  all,
  social,
  finance,
  events,
  reminders,
  updates,
}

enum NotificationType {
  like,
  comment,
  reply,
  mention,
  friendRequest,
  follow,
  group,
  budgetWarning,
  budgetExceeded,
  savingGoal,
  financeUpdate,
  eventReminder,
  eventUpdate,
  eventRsvp,
  event,
  habitReminder,
  taskReminder,
  goalReminder,
  streakMilestone,
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
      if (key.contains('like')) return NotificationType.like;
      if (key.contains('reply')) return NotificationType.reply;
      if (key.contains('comment')) return NotificationType.comment;
      if (key.contains('mention')) return NotificationType.mention;
      if (key.contains('friendrequest') || key.contains('followrequest')) {
        return NotificationType.friendRequest;
      }
      if (key.contains('follow')) return NotificationType.follow;
      if (key.contains('group')) return NotificationType.group;
      if (key.contains('budgetwarning') || key.contains('budgetalert')) {
        return NotificationType.budgetWarning;
      }
      if (key.contains('budgetexceeded')) return NotificationType.budgetExceeded;
      if (key.contains('savinggoal') || key.contains('goal')) {
        return NotificationType.savingGoal;
      }
      if (key.contains('finance')) return NotificationType.financeUpdate;
      if (key.contains('eventreminder')) return NotificationType.eventReminder;
      if (key.contains('eventupdate')) return NotificationType.eventUpdate;
      if (key.contains('eventrsvp') || key.contains('rsvp')) {
        return NotificationType.eventRsvp;
      }
      if (key.contains('event')) return NotificationType.event;
      if (key.contains('habitreminder') || key.contains('habit')) {
        return NotificationType.habitReminder;
      }
      if (key.contains('taskreminder') || key.contains('task')) {
        return NotificationType.taskReminder;
      }
      if (key.contains('goalreminder')) return NotificationType.goalReminder;
      if (key.contains('streakmilestone') || key.contains('streak')) {
        return NotificationType.streakMilestone;
      }
      if (key.contains('quizresult') || key.contains('quiz')) {
        return NotificationType.quizResult;
      }
      if (key.contains('achievement')) return NotificationType.achievement;
      return NotificationType.system;
    }

    NotificationCategory? parseCategory(String? raw) {
      switch (raw?.toLowerCase()) {
        case 'social':
        case 'community':
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
        case 'security':
          return NotificationCategory.updates;
        case 'all':
          return NotificationCategory.all;
        default:
          return null;
      }
    }

    final parsedType = parseType(json['type'] as String? ?? json['notificationType'] as String?);
    final parsedCategory = parseCategory(json['category'] as String?) ??
        _resolveCategory(parsedType);

    final rawTimestamp = json['timestamp'] ?? json['createdAt'];
    final DateTime parsedTimestamp = rawTimestamp != null
        ? DateTime.tryParse(rawTimestamp.toString()) ?? DateTime.now()
        : DateTime.now();

    final isReadVal = json['isRead'] ?? json['readStatus'];
    final bool parsedIsRead = isReadVal is bool
        ? isReadVal
        : (isReadVal == 'READ' || isReadVal == true);

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
      timestamp: parsedTimestamp,
      isRead: parsedIsRead,
      targetId: (json['targetId'] ?? json['referenceId'])?.toString(),
      targetType: (json['targetType'] ?? json['referenceType'])?.toString(),
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
