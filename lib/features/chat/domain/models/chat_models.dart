import 'dart:convert';

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

enum SharedContentType {
  post,
  discussion,
  event,
  profile;

  String get label => switch (this) {
        SharedContentType.post => 'Post',
        SharedContentType.discussion => 'Discussion',
        SharedContentType.event => 'Event',
        SharedContentType.profile => 'Profile',
      };
}

class SharedContentModel {
  final SharedContentType type;
  final String id;
  final String title;
  final String? previewText;
  final String? thumbnailUrl;
  final String? authorName;
  final String? authorAvatar;
  final String? subtitle;
  final Map<String, dynamic>? metadata;

  const SharedContentModel({
    required this.type,
    required this.id,
    required this.title,
    this.previewText,
    this.thumbnailUrl,
    this.authorName,
    this.authorAvatar,
    this.subtitle,
    this.metadata,
  });

  factory SharedContentModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['contentType'] ?? '').toString().toUpperCase();
    final type = switch (rawType) {
      'POST' => SharedContentType.post,
      'DISCUSSION' || 'TOPIC' => SharedContentType.discussion,
      'EVENT' => SharedContentType.event,
      'PROFILE' || 'USER' => SharedContentType.profile,
      _ => SharedContentType.post,
    };
    return SharedContentModel(
      type: type,
      id: (json['id'] ?? json['contentId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      previewText: json['previewText']?.toString() ?? json['description']?.toString() ?? json['preview_text']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['imageUrl']?.toString() ?? json['avatarUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      authorName: json['authorName']?.toString() ?? json['author']?.toString() ?? json['displayName']?.toString() ?? json['author_name']?.toString(),
      authorAvatar: json['authorAvatar']?.toString() ?? json['author_avatar']?.toString(),
      subtitle: json['subtitle']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }

  String get deepLink => 'genlink://${type.name}/$id';

  Map<String, dynamic> toJson() => {
        'type': type.name.toUpperCase(),
        'id': id,
        'title': title,
        if (previewText != null) 'previewText': previewText,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (authorName != null) 'authorName': authorName,
        if (authorAvatar != null) 'authorAvatar': authorAvatar,
        if (subtitle != null) 'subtitle': subtitle,
        if (metadata != null) 'metadata': metadata,
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
  final SharedContentModel? sharedContent;
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
    this.sharedContent,
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
    final resolvedConversationId = conversationId.isNotEmpty
        ? conversationId
        : (json['roomId'] ?? json['conversationId'] ?? json['chatRoomId'] ?? '').toString();
    final rawMediaUrl = json['mediaUrl'] as String?;

    final rawShared = json['sharedContent'] ?? json['shared_content'];
    Map<String, dynamic>? decodedShared;
    if (rawShared is Map) {
      decodedShared = rawShared.cast<String, dynamic>();
    } else if (rawShared is String && rawShared.trim().isNotEmpty) {
      try {
        final d = jsonDecode(rawShared);
        if (d is Map) decodedShared = d.cast<String, dynamic>();
      } catch (_) {}
    }

    final isStoryReplyFromShared = decodedShared != null &&
        (decodedShared['type']?.toString().toUpperCase() == 'STORY_REPLY' ||
            decodedShared['storyReference'] != null ||
            decodedShared['storyId'] != null);

    final isStoryReplyFromMedia = backendType.toUpperCase() == 'TEXT' &&
        rawMediaUrl != null &&
        rawMediaUrl.isNotEmpty &&
        (rawMediaUrl.contains('/stories/') || isStoryReplyFromShared);

    final isStoryReply = backendType.toLowerCase() == 'story_reply' ||
        isStoryReplyFromShared ||
        isStoryReplyFromMedia;

    final resolvedMessageType =
        isStoryReply ? 'story_reply' : backendType.toLowerCase();

    final StoryReference? resolvedStoryRef = json['storyReference']
            is Map<String, dynamic>
        ? StoryReference.fromJson(
            json['storyReference'] as Map<String, dynamic>,
          )
        : (isStoryReply
            ? StoryReference(
                storyId: decodedShared?['storyId']?.toString() ??
                    (decodedShared?['storyReference'] is Map
                        ? decodedShared!['storyReference']['storyId']?.toString()
                        : null),
                mediaUrl: decodedShared?['mediaUrl']?.toString() ??
                    (decodedShared?['storyReference'] is Map
                        ? decodedShared!['storyReference']['mediaUrl']?.toString()
                        : null) ??
                    rawMediaUrl,
                isExpired: decodedShared?['isExpired'] == true,
              )
            : null);

    return ChatMessageModel(
      id: json['messageId']?.toString() ?? json['id']?.toString() ?? '',
      conversationId: resolvedConversationId,
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
      messageType: resolvedMessageType,
      mediaUrl: rawMediaUrl ?? resolvedStoryRef?.mediaUrl,
      storyReference: resolvedStoryRef,
      financeTransaction: json['financeTransaction'] is Map<String, dynamic>
          ? ChatFinanceTransaction.fromJson(
              json['financeTransaction'] as Map<String, dynamic>,
            )
          : null,
      sharedContent: () {
        if (isStoryReplyFromShared) return null;
        if (decodedShared != null) {
          return SharedContentModel.fromJson(decodedShared);
        }
        return null;
      }(),
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
    SharedContentModel? sharedContent,
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
      sharedContent: sharedContent ?? this.sharedContent,
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
      'roomId': conversationId,
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
      if (sharedContent != null) ...{
        'sharedContent': sharedContent!.toJson(),
        'shared_content': sharedContent!.toJson(),
      },
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

class ChatMemberModel {
  final String userId;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String role; // 'OWNER', 'ADMIN', 'MEMBER'

  const ChatMemberModel({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.role = 'MEMBER',
  });

  bool get isOwner => role.toUpperCase() == 'OWNER';
  bool get isAdmin => role.toUpperCase() == 'ADMIN' || isOwner;

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] is Map ? json['user'] as Map : json;
    final user = rawUser.cast<String, dynamic>();
    return ChatMemberModel(
      userId: user['userId']?.toString() ?? user['id']?.toString() ?? '',
      fullName: (user['fullName'] as String?) ??
          (user['name'] as String?) ??
          'Student',
      username: (user['username'] as String?) ??
          (user['handle'] as String?) ??
          '',
      avatarUrl: (user['avatarUrl'] as String?) ?? (user['avatar'] as String?),
      role: (json['role'] as String?) ?? 'MEMBER',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'username': username,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'role': role,
      };
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
  final List<ChatMemberModel> members;
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
    this.members = const [],
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
    final rawMembers = json['members'] is List ? json['members'] as List : const [];
    final membersList = rawMembers
        .whereType<Map>()
        .map((m) => ChatMemberModel.fromJson(m.cast<String, dynamic>()))
        .toList();
    final parsedCount = (json['membersCount'] as num?)?.toInt();
    final resolvedCount = parsedCount ??
        (isGroup
            ? (membersList.isNotEmpty ? membersList.length : (json['memberCount'] as num?)?.toInt() ?? 0)
            : 2);
    return ChatConversationModel(
      id: json['roomId']?.toString() ?? json['id']?.toString() ?? '',
      name:
          (json['title'] as String?) ??
          (counterpart['fullName'] as String?) ??
          (counterpart['username'] as String?) ??
          (json['name'] as String?) ??
          'Chat',
      avatar:
          (json['avatarUrl'] as String?) ??
          (counterpart['avatarUrl'] as String?) ??
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
      membersCount: resolvedCount,
      members: membersList,
      isEventChat: (json['isEventChat'] as bool?) ?? (type == 'EVENT'),
      isPinned: (json['isPinned'] as bool?) ?? false,
      isArchived: (json['isArchived'] as bool?) ?? false,
      isMuted: (json['isMuted'] as bool?) ?? false,
    );
  }

  factory ChatConversationModel.fromRoomResponse(
    Map<String, dynamic> json, {
    String? roomId,
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
        final userId =
            participant['userId']?.toString() ?? participant['id']?.toString();
        if (targetUserId != null && userId == targetUserId) {
          counterpart = participant;
          break;
        }
        firstParticipant ??= participant;
        if (targetUserId == null && counterpart.isEmpty) {
          counterpart = participant;
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
    final avatar = (json['avatarUrl'] as String?) ??
        (counterpart['avatarUrl'] as String?) ??
        'assets/images/user_profile.png';

    final resolvedId = json['roomId']?.toString() ??
        json['id']?.toString() ??
        roomId ??
        '';

    final membersRaw = json['members'] is List ? json['members'] as List : const [];
    final membersList = membersRaw
        .whereType<Map>()
        .map((m) => ChatMemberModel.fromJson(m.cast<String, dynamic>()))
        .toList();

    return ChatConversationModel(
      id: resolvedId,
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
      membersCount: membersList.isNotEmpty ? membersList.length : membersRaw.length,
      members: membersList,
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
    List<ChatMemberModel>? members,
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
      members: members ?? this.members,
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
      'members': members.map((m) => m.toJson()).toList(),
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
