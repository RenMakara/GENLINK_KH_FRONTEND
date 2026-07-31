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
  final String messageType; // 'text', 'image', 'post_share'
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

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      isMine: json['isMine'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? true,
      messageType: json['messageType'] as String? ?? 'text',
      mediaUrl: json['mediaUrl'] as String?,
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
    return ChatConversationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      avatar: json['avatar'] as String? ?? 'assets/images/user_profile.png',
      isGroup: json['isGroup'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      membersCount: json['membersCount'] as int? ?? 2,
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
