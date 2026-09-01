enum NotificationType { like, comment, mention, follow, group, event, system }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String senderName;
  final String? senderAvatar;
  final String timeAgo;
  final DateTime timestamp;
  bool isRead;
  final String? targetId;
  final String? targetType;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.senderName,
    this.senderAvatar,
    required this.timeAgo,
    required this.timestamp,
    this.isRead = false,
    this.targetId,
    this.targetType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? raw) {
      switch (raw?.toLowerCase()) {
        case 'like':
          return NotificationType.like;
        case 'comment':
          return NotificationType.comment;
        case 'mention':
          return NotificationType.mention;
        case 'follow':
          return NotificationType.follow;
        case 'group':
          return NotificationType.group;
        case 'event':
          return NotificationType.event;
        case 'system':
        default:
          return NotificationType.system;
      }
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: parseType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'GenLink KH',
      senderAvatar: json['senderAvatar'] as String?,
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timeAgo': timeAgo,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'targetId': targetId,
      'targetType': targetType,
    };
  }
}
