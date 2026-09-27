import '../../../../core/utils/date_formatter.dart';

enum NotificationCategory { all, social, finance, events, reminders, updates }

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
  challengeReward,
  badgeAwarded,
  levelUp,
  goalMilestone,
  achievement,
  system,
  chat,
  security,
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

  /// Returns the comment ID associated with this notification if available.
  String? get commentId {
    if (metadata != null && metadata!['commentId'] != null) {
      return metadata!['commentId']?.toString();
    }
    final dedupe = metadata?['dedupeKey']?.toString() ?? '';
    if (dedupe.startsWith('post-comment:') || dedupe.startsWith('comment-reply:')) {
      final parts = dedupe.split(':');
      if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
    }
    return null;
  }

  /// Returns the parent comment ID if this notification is a reply.
  String? get parentCommentId {
    if (metadata != null && metadata!['parentCommentId'] != null) {
      return metadata!['parentCommentId']?.toString();
    }
    final dedupe = metadata?['dedupeKey']?.toString() ?? '';
    if (dedupe.startsWith('comment-reply:')) {
      final parts = dedupe.split(':');
      if (parts.length >= 3 && parts[2].isNotEmpty) return parts[2];
    }
    return null;
  }

  /// Returns the post ID associated with this notification if available.
  String? get postId {
    if (metadata != null && metadata!['postId'] != null) {
      return metadata!['postId']?.toString();
    }
    if (targetType?.toUpperCase() == 'POST' && targetId != null && targetId!.isNotEmpty) {
      return targetId;
    }
    return null;
  }

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
      case NotificationType.chat:
        return NotificationCategory.social;
      case NotificationType.challengeReward:
      case NotificationType.badgeAwarded:
      case NotificationType.levelUp:
      case NotificationType.achievement:
        return NotificationCategory.updates;
      case NotificationType.goalMilestone:
        return NotificationCategory.reminders;
      case NotificationType.security:
      case NotificationType.system:
        return NotificationCategory.updates;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? raw) {
      final key =
          raw?.toLowerCase().replaceAll('_', '').replaceAll('-', '') ?? '';
      if (key.contains('chat') || key.contains('message')) {
        return NotificationType.chat;
      }
      if (key.contains('security') ||
          key.contains('login') ||
          key.contains('auth')) {
        return NotificationType.security;
      }
      if (key.contains('challenge')) return NotificationType.challengeReward;
      if (key.contains('badge')) return NotificationType.badgeAwarded;
      if (key.contains('levelup') || key.contains('level')) {
        return NotificationType.levelUp;
      }
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
      if (key.contains('budgetexceeded')) {
        return NotificationType.budgetExceeded;
      }
      if (key.contains('goalmilestone') || key == 'productivitygoal') {
        return NotificationType.goalMilestone;
      }
      if (key.contains('savinggoal')) {
        return NotificationType.savingGoal;
      }
      if (key.contains('finance')) return NotificationType.financeUpdate;
      if (key.contains('eventreminder')) return NotificationType.eventReminder;
      if (key.contains('eventupdate')) return NotificationType.eventUpdate;
      if (key.contains('eventrsvp') || key.contains('rsvp')) {
        return NotificationType.eventRsvp;
      }
      if (key.contains('event')) return NotificationType.event;
      if (key == 'productivityhabit' ||
          key.contains('streakmilestone') ||
          key.contains('streak')) {
        return NotificationType.streakMilestone;
      }
      if (key.contains('habitreminder') || key.contains('habit')) {
        return NotificationType.habitReminder;
      }
      if (key.contains('taskreminder') || key.contains('task')) {
        return NotificationType.taskReminder;
      }
      if (key.contains('goalreminder') || key.contains('goal')) {
        return NotificationType.goalReminder;
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

    final templateKey = (json['templateKey'] ?? json['template'])?.toString().toLowerCase() ?? '';
    final dedupeKeyStr = json['dedupeKey']?.toString().toLowerCase() ?? '';

    NotificationType parsedType = parseType(
      json['type'] as String? ?? json['notificationType'] as String?,
    );
    if (parsedType == NotificationType.system) {
      if (templateKey.contains('reply') || dedupeKeyStr.contains('reply')) {
        parsedType = NotificationType.reply;
      } else if (templateKey.contains('comment') || dedupeKeyStr.contains('comment')) {
        parsedType = NotificationType.comment;
      } else if (templateKey.contains('like') || dedupeKeyStr.contains('like')) {
        parsedType = NotificationType.like;
      }
    }
    final parsedCategory =
        parseCategory(json['category'] as String?) ??
        _resolveCategory(parsedType);

    final rawTimestamp = json['timestamp'] ?? json['createdAt'];
    final DateTime parsedTimestamp =
        CommunityDateFormatter.parseToUtc(rawTimestamp)?.toLocal() ??
        (rawTimestamp != null
            ? DateTime.tryParse(rawTimestamp.toString())?.toLocal() ??
                  DateTime.now()
            : DateTime.now());

    final computedTimeAgo = (json['timeAgo'] as String?)?.trim();
    final effectiveTimeAgo =
        (computedTimeAgo != null && computedTimeAgo.isNotEmpty)
        ? computedTimeAgo
        : (rawTimestamp != null
              ? formatCommunityTimestamp(parsedTimestamp)
              : 'Just now');

    final isReadVal = json['isRead'] ?? json['readStatus'];
    final bool parsedIsRead = isReadVal is bool
        ? isReadVal
        : (isReadVal == 'READ' || isReadVal == true);

    final titleStr = json['title'] as String? ?? '';
    final bodyStr = json['body'] as String? ?? json['message'] as String? ?? '';
    final explicitSender = (json['senderName'] as String?)?.trim();
    final explicitActor = (json['actorName'] as String?)?.trim();

    String resolvedSenderName;
    if (explicitSender != null &&
        explicitSender.isNotEmpty &&
        explicitSender != 'GenLink KH') {
      resolvedSenderName = explicitSender;
    } else if (explicitActor != null && explicitActor.isNotEmpty) {
      resolvedSenderName = explicitActor;
    } else {
      final extracted = _extractActorName(titleStr, bodyStr);
      resolvedSenderName =
          extracted ??
          (explicitSender ??
              (parsedCategory == NotificationCategory.social
                  ? 'Community Member'
                  : 'GenLink KH'));
    }

    final rawAvatar =
        (json['senderAvatar'] ??
                json['actorAvatar'] ??
                json['avatarUrl'] ??
                json['userAvatar'] ??
                (json['actor'] is Map ? json['actor']['avatarUrl'] : null))
            ?.toString()
            .trim();

    final metadata = <String, dynamic>{
      if (json['metadata'] is Map)
        ...Map<String, dynamic>.from(json['metadata'] as Map),
      if (json['parameters'] is Map)
        ...Map<String, dynamic>.from(json['parameters'] as Map),
      if (json['deliveryId'] != null) 'deliveryId': json['deliveryId'],
      if (json['dedupeKey'] != null) 'dedupeKey': json['dedupeKey'],
      if (json['commentId'] != null) 'commentId': json['commentId'],
      if (json['parentCommentId'] != null)
        'parentCommentId': json['parentCommentId'],
      if (json['postId'] != null) 'postId': json['postId'],
    };
    final stableId =
        (json['id'] ??
                json['notificationId'] ??
                json['deliveryId'] ??
                json['dedupeKey'])
            ?.toString() ??
        '';

    return NotificationModel(
      id: stableId,
      type: parsedType,
      category: parsedCategory,
      title: titleStr,
      body: bodyStr,
      contextText:
          json['contextText'] as String? ??
          json['context'] as String? ??
          json['subtitle'] as String?,
      senderName: resolvedSenderName,
      senderAvatar: (rawAvatar != null && rawAvatar.isNotEmpty)
          ? rawAvatar
          : null,
      timeAgo: effectiveTimeAgo,
      timestamp: parsedTimestamp,
      isRead: parsedIsRead,
      targetId: (json['targetId'] ?? json['referenceId'])?.toString(),
      targetType: (json['targetType'] ?? json['referenceType'])?.toString(),
      metadata: metadata.isEmpty ? null : metadata,
    );
  }

  static String? _extractActorName(String title, String body) {
    String? matchText(String text) {
      if (text.isEmpty) return null;
      final match = RegExp(
        r'^([A-Z\u1780-\u17FF][\w\u1780-\u17FF\s]{0,30}?)\s+(?:liked|commented|replied|started following|wants to follow|accepted your follow request|shared|sent you a message|sent you a friend request)',
        caseSensitive: false,
      ).firstMatch(text.trim());
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.isNotEmpty &&
            name.toLowerCase() != 'someone') {
          return name;
        }
      }
      return null;
    }

    return matchText(title) ?? matchText(body);
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

class NotificationPage {
  final List<NotificationModel> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  const NotificationPage({
    required this.items,
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 1,
    this.hasNext = false,
  });

  factory NotificationPage.empty() => const NotificationPage(
    items: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    hasNext: false,
  );

  factory NotificationPage.fromPageResponse(
    Map<String, dynamic> json,
    List<NotificationModel> items,
  ) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as num?)?.toInt() ?? items.length;
    final totalElements =
        (json['totalElements'] as num?)?.toInt() ?? items.length;
    final totalPages =
        (json['totalPages'] as num?)?.toInt() ??
        (totalElements > 0
            ? (totalElements / (size > 0 ? size : 20)).ceil()
            : 0);
    final hasNext = json['hasNext'] as bool? ?? (page + 1 < totalPages);

    return NotificationPage(
      items: items,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      hasNext: hasNext,
    );
  }
}
