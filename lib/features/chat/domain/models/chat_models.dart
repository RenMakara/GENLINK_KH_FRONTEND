class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final String timeAgo;
  final bool isMine;
  final bool isRead;
  final String messageType; // 'text', 'image', 'voice', 'story_reply'
  final String? mediaUrl;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.timeAgo,
    required this.isMine,
    this.isRead = true,
    this.messageType = 'text',
    this.mediaUrl,
  });

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String conversationId,
  }) {
    final sender = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final backendType = (json['type'] as String?) ?? 'TEXT';
    return ChatMessageModel(
      id: json['messageId']?.toString() ?? json['id']?.toString() ?? '',
      conversationId: conversationId,
      senderId: sender['userId']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName:
          (sender['fullName'] as String?) ??
          (sender['username'] as String?) ??
          (json['senderName'] as String?) ??
          'User',
      senderAvatar: (sender['avatarUrl'] as String?) ?? (json['senderAvatar'] as String?),
      content: json['content'] as String? ?? '',
      timestamp: createdAt,
      timeAgo: _timeAgo(createdAt),
      isMine: json['mine'] as bool? ?? json['isMine'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? true,
      messageType: backendType.toLowerCase(),
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    String? timeAgo,
    bool? isMine,
    bool? isRead,
    String? messageType,
    String? mediaUrl,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      timeAgo: timeAgo ?? this.timeAgo,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'timeAgo': timeAgo,
      'isMine': isMine,
      'isRead': isRead,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
    };
  }
}

class ChatConversationModel {
  final String id;
  final String name;
  final String avatar;
  final bool isGroup;
  final bool isOnline;
  String lastMessage;
  String lastMessageTime;
  int unreadCount;
  final int membersCount;

  ChatConversationModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.isGroup = false,
    this.isOnline = false,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.membersCount = 2,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'PRIVATE';
    final counterpart = json['counterpart'] is Map<String, dynamic>
        ? json['counterpart'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map<String, dynamic>
        ? json['lastMessage'] as Map<String, dynamic>
        : null;
    final lastCreatedAt = lastMessage != null
        ? DateTime.tryParse(lastMessage['createdAt']?.toString() ?? '')
        : null;
    final lastActivity =
        DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ??
        lastCreatedAt;
    final lastType = (lastMessage?['type'] as String?) ?? 'TEXT';
    return ChatConversationModel(
      id: json['roomId']?.toString() ?? json['id']?.toString() ?? '',
      name:
          (json['title'] as String?) ??
          (counterpart['fullName'] as String?) ??
          (counterpart['username'] as String?) ??
          (json['name'] as String?) ??
          'Chat',
      avatar:
          counterpart['avatarUrl'] as String? ??
          (json['avatar'] as String?) ??
          'assets/images/user_profile.png',
      isGroup: type == 'GROUP' || (json['isGroup'] as bool? ?? false),
      isOnline: json['isOnline'] as bool? ?? false,
      lastMessage: lastMessage == null
          ? (json['lastMessage'] as String? ?? '')
          : lastType == 'IMAGE'
          ? '[image]'
          : lastType == 'VOICE'
          ? '[voice message]'
          : (lastMessage['content'] as String? ?? ''),
      lastMessageTime: lastActivity == null
          ? (json['lastMessageTime'] as String? ?? '')
          : _timeAgo(lastActivity),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      membersCount: (json['membersCount'] as num?)?.toInt() ?? 2,
    );
  }

  factory ChatConversationModel.fromRoomResponse(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'PRIVATE';
    final isGroup = type == 'GROUP';
    final members = json['members'] is List ? json['members'] as List : const [];
    
    Map<String, dynamic> counterpart = const {};
    if (members.isNotEmpty) {
      for (final m in members) {
        if (m is Map) {
          counterpart = m.cast<String, dynamic>();
          break;
        }
      }
    }

    final name = (json['name'] as String?) ??
        (counterpart['fullName'] as String?) ??
        (counterpart['username'] as String?) ??
        'Chat';
    final avatar = (counterpart['avatarUrl'] as String?) ??
        'assets/images/user_profile.png';

    return ChatConversationModel(
      id: json['roomId']?.toString() ?? json['id']?.toString() ?? '',
      name: name,
      avatar: avatar,
      isGroup: isGroup,
      isOnline: false,
      lastMessage: '',
      lastMessageTime: 'Just now',
      unreadCount: 0,
      membersCount: members.length,
    );
  }

  ChatConversationModel copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isGroup,
    bool? isOnline,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    int? membersCount,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGroup: isGroup ?? this.isGroup,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      membersCount: membersCount ?? this.membersCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isGroup': isGroup,
      'isOnline': isOnline,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'membersCount': membersCount,
    };
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return time.toLocal().toString().substring(0, 10);
}
