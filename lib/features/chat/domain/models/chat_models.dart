class StoryReference {
  final String? storyId;
  final String? mediaUrl;
  final bool isExpired;

  const StoryReference({
    this.storyId,
    this.mediaUrl,
    this.isExpired = false,
  });

  factory StoryReference.fromJson(Map<String, dynamic> json) {
    return StoryReference(
      storyId: json['storyId']?.toString(),
      mediaUrl: json['mediaUrl'] as String?,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (storyId != null) 'storyId': storyId,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        'isExpired': isExpired,
      };
}

class ChatFinanceTransaction {
  final String transactionId;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String? note;
  final DateTime timestamp;

  const ChatFinanceTransaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    this.status = 'completed',
    this.note,
    required this.timestamp,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isSend => type == 'send';

  factory ChatFinanceTransaction.fromJson(Map<String, dynamic> json) {
    return ChatFinanceTransaction(
      transactionId: (json['transactionId'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'send',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'USD',
      status: (json['status'] as String?) ?? 'completed',
      note: json['note'] as String?,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'status': status,
        if (note != null) 'note': note,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ChatReplyReference {
  final String messageId;
  final String senderName;
  final String content;
  final String messageType;
  final String? mediaUrl;

  const ChatReplyReference({
    required this.messageId,
    required this.senderName,
    required this.content,
    this.messageType = 'text',
    this.mediaUrl,
  });

  factory ChatReplyReference.fromJson(Map<String, dynamic> json) {
    return ChatReplyReference(
      messageId: json['messageId']?.toString() ?? '',
      senderName: (json['senderName'] as String?) ?? 'User',
      content: (json['content'] as String?) ?? (json['snippet'] as String?) ?? '',
      messageType: (json['messageType'] as String?) ??
          (json['type'] as String?)?.toLowerCase() ??
          'text',
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderName': senderName,
        'content': content,
        'messageType': messageType,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      };
}

class ChatReactionModel {
  final String emoji;
  final int count;
  final bool hasReacted;

  const ChatReactionModel({
    required this.emoji,
    this.count = 1,
    this.hasReacted = false,
  });

  ChatReactionModel copyWith({
    String? emoji,
    int? count,
    bool? hasReacted,
  }) {
    return ChatReactionModel(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      hasReacted: hasReacted ?? this.hasReacted,
    );
  }

  factory ChatReactionModel.fromJson(Map<String, dynamic> json) {
    return ChatReactionModel(
      emoji: (json['emoji'] as String?) ?? '👍',
      count: (json['count'] as num?)?.toInt() ?? 1,
      hasReacted: (json['hasReacted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'count': count,
        'hasReacted': hasReacted,
      };
}

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
  final String messageType;
  final String? mediaUrl;
  final StoryReference? storyReference;
  final ChatFinanceTransaction? financeTransaction;
  final int? voiceDurationSeconds;
  final String deliveryStatus;
  final bool isSystemMessage;
  final ChatReplyReference? replyTo;
  final List<ChatReactionModel> reactions;
  final bool isPinned;
  final bool isDeleted;

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
    this.storyReference,
    this.financeTransaction,
    this.voiceDurationSeconds,
    this.deliveryStatus = 'read',
    this.isSystemMessage = false,
    this.replyTo,
    this.reactions = const [],
    this.isPinned = false,
    this.isDeleted = false,
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
      storyReference: json['storyReference'] is Map<String, dynamic>
          ? StoryReference.fromJson(
              json['storyReference'] as Map<String, dynamic>,
            )
          : null,
      financeTransaction: json['financeTransaction'] is Map<String, dynamic>
          ? ChatFinanceTransaction.fromJson(
              json['financeTransaction'] as Map<String, dynamic>,
            )
          : null,
      voiceDurationSeconds: (json['voiceDurationSeconds'] as num?)?.toInt(),
      deliveryStatus: (json['deliveryStatus'] as String?) ?? 'read',
      isSystemMessage: (json['isSystemMessage'] as bool?) ??
          (backendType.toUpperCase() == 'SYSTEM'),
      replyTo: json['replyTo'] is Map<String, dynamic>
          ? ChatReplyReference.fromJson(
              json['replyTo'] as Map<String, dynamic>,
            )
          : null,
      reactions: json['reactions'] is List
          ? (json['reactions'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ChatReactionModel.fromJson)
              .toList()
          : const [],
      isPinned: (json['isPinned'] as bool?) ?? false,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
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
    StoryReference? storyReference,
    ChatFinanceTransaction? financeTransaction,
    int? voiceDurationSeconds,
    String? deliveryStatus,
    bool? isSystemMessage,
    ChatReplyReference? replyTo,
    List<ChatReactionModel>? reactions,
    bool? isPinned,
    bool? isDeleted,
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
      storyReference: storyReference ?? this.storyReference,
      financeTransaction: financeTransaction ?? this.financeTransaction,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
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
      if (storyReference != null) 'storyReference': storyReference!.toJson(),
      if (financeTransaction != null)
        'financeTransaction': financeTransaction!.toJson(),
      if (voiceDurationSeconds != null)
        'voiceDurationSeconds': voiceDurationSeconds,
      'deliveryStatus': deliveryStatus,
      'isSystemMessage': isSystemMessage,
      if (replyTo != null) 'replyTo': replyTo!.toJson(),
      if (reactions.isNotEmpty)
        'reactions': reactions.map((r) => r.toJson()).toList(),
      'isPinned': isPinned,
      'isDeleted': isDeleted,
    };
  }
}

class ChatConversationModel {
  final String id;
  final String name;
  final String avatar;
  final String? profileUserId;
  final String? profileUsername;
  final bool isGroup;
  final bool isOnline;
  String lastMessage;
  String lastMessageTime;
  int unreadCount;
  final int membersCount;
  final bool isEventChat;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final ChatMessageModel? pinnedMessage;

  ChatConversationModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.profileUserId,
    this.profileUsername,
    this.isGroup = false,
    this.isOnline = false,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.membersCount = 2,
    this.isEventChat = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.pinnedMessage,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'PRIVATE';
    final counterpart = json['counterpart'] is Map
        ? (json['counterpart'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map
        ? (json['lastMessage'] as Map).cast<String, dynamic>()
        : null;
    final lastCreatedAt = lastMessage != null
        ? DateTime.tryParse(lastMessage['createdAt']?.toString() ?? '')
        : null;
    final lastActivity =
        DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ??
        lastCreatedAt;
    final lastType = (lastMessage?['type'] as String?) ?? 'TEXT';
    final isGroup = type == 'GROUP' || (json['isGroup'] as bool? ?? false);
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
      profileUserId: isGroup
          ? null
          : (counterpart['userId']?.toString() ??
              json['profileUserId']?.toString()),
      profileUsername: isGroup
          ? null
          : (counterpart['username']?.toString() ??
              json['profileUsername']?.toString()),
      isGroup: isGroup,
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
      isEventChat: (json['isEventChat'] as bool?) ?? (type == 'EVENT'),
      isPinned: (json['isPinned'] as bool?) ?? false,
      isArchived: (json['isArchived'] as bool?) ?? false,
      isMuted: (json['isMuted'] as bool?) ?? false,
    );
  }

  factory ChatConversationModel.fromRoomResponse(
    Map<String, dynamic> json, {
    String? participantUserId,
  }) {
    final type = (json['type'] as String?) ?? 'PRIVATE';
    final isGroup = type == 'GROUP';
    final members = json['members'] is List ? json['members'] as List : const [];

    Map<String, dynamic> counterpart = json['counterpart'] is Map
        ? (json['counterpart'] as Map).cast<String, dynamic>()
        : const {};
    Map<String, dynamic>? firstParticipant;
    final targetUserId = participantUserId?.trim();
    if (counterpart.isEmpty) {
      for (final member in members) {
        if (member is! Map) continue;
        final rawParticipant = member['user'] is Map ? member['user'] : member;
        if (rawParticipant is! Map) continue;
        final participant = rawParticipant.cast<String, dynamic>();
        firstParticipant ??= participant;
        final userId =
            participant['userId']?.toString() ?? participant['id']?.toString();
        if (targetUserId == null || userId == targetUserId) {
          counterpart = participant;
          break;
        }
      }
      counterpart = counterpart.isEmpty
          ? (firstParticipant ?? const {})
          : counterpart;
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
      profileUserId: isGroup
          ? null
          : counterpart['userId']?.toString() ?? counterpart['id']?.toString(),
      profileUsername: isGroup ? null : counterpart['username']?.toString(),
      isGroup: isGroup,
      isOnline: false,
      lastMessage: '',
      lastMessageTime: 'Just now',
      unreadCount: 0,
      membersCount: members.length,
      isEventChat: (json['isEventChat'] as bool?) ?? (type == 'EVENT'),
      isPinned: (json['isPinned'] as bool?) ?? false,
      isArchived: (json['isArchived'] as bool?) ?? false,
      isMuted: (json['isMuted'] as bool?) ?? false,
    );
  }

  ChatConversationModel copyWith({
    String? id,
    String? name,
    String? avatar,
    String? profileUserId,
    String? profileUsername,
    bool? isGroup,
    bool? isOnline,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    int? membersCount,
    bool? isEventChat,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
    ChatMessageModel? pinnedMessage,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      profileUserId: profileUserId ?? this.profileUserId,
      profileUsername: profileUsername ?? this.profileUsername,
      isGroup: isGroup ?? this.isGroup,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      membersCount: membersCount ?? this.membersCount,
      isEventChat: isEventChat ?? this.isEventChat,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      pinnedMessage: pinnedMessage ?? this.pinnedMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      if (profileUserId != null) 'profileUserId': profileUserId,
      if (profileUsername != null) 'profileUsername': profileUsername,
      'isGroup': isGroup,
      'isOnline': isOnline,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'membersCount': membersCount,
      'isEventChat': isEventChat,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isMuted': isMuted,
      if (pinnedMessage != null) 'pinnedMessage': pinnedMessage!.toJson(),
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
