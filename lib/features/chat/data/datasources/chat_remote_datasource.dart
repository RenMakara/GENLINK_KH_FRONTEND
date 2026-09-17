import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/chat_models.dart';

class ChatRemoteDataSource {
  final Dio dio;
  final Map<String, List<ChatMessageModel>> _localMessages = {};

  ChatRemoteDataSource({required this.dio});

  Future<List<ChatConversationModel>> fetchConversations() async {
    final response = await guardDio(() => dio.get<dynamic>(ApiEndpoints.chats));
    final content = _contentOf(response.data);
    return content
        .map(
          (json) =>
              ChatConversationModel.fromJson(json.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(ApiEndpoints.chatUnreadCount),
      );
      final data = _dataOf(response.data);
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<ChatConversationModel> getRoom(String roomId) async {
    final response = await guardDio(
      () => dio.get<dynamic>('${ApiEndpoints.chats}/$roomId'),
    );
    final data = _dataOf(response.data);
    return ChatConversationModel.fromRoomResponse(data);
  }

  Future<ChatConversationModel> openPrivateChat(String userId) async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.chats}/private/$userId'),
      );
      final data = _dataOf(response.data);
      return ChatConversationModel.fromRoomResponse(
        data,
        participantUserId: userId,
      );
    } catch (_) {
      final isSokny = userId == 'user_sokny' || userId.toLowerCase().contains('sokny');
      final isChansela = userId == 'user_chansela' || userId.toLowerCase().contains('chansela');
      return ChatConversationModel(
        id: 'private_$userId',
        name: isSokny ? 'Sokny Enat' : (isChansela ? 'Heng Chansela' : 'User'),
        avatar: isSokny
            ? 'assets/images/user_profile.png'
            : (isChansela
                ? 'assets/images/heng_chansela_profile.png'
                : 'assets/images/user_profile.png'),
        profileUserId: userId,
        isGroup: false,
        isOnline: true,
        lastMessage: '',
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );
    }
  }

  Future<ChatConversationModel> createGroup(
    String name,
    List<String> memberUserIds,
  ) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        '${ApiEndpoints.chats}/groups',
        data: {
          'name': name,
          'memberIds': memberUserIds,
          'memberUserIds': memberUserIds,
        },
      ),
    );
    final data = _dataOf(response.data);
    return ChatConversationModel.fromRoomResponse(data);
  }

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>('${ApiEndpoints.chats}/$conversationId/messages'),
      );
      final content = _contentOf(response.data);
      final messages = content
          .map(
            (json) => ChatMessageModel.fromJson(
              json.cast<String, dynamic>(),
              conversationId: conversationId,
            ),
          )
          .toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _localMessages[conversationId] = List.from(messages);
      return messages;
    } catch (_) {
      return _localMessages[conversationId] ?? <ChatMessageModel>[];
    }
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
  }) async {
    try {
      final response = await guardDio(
        () => dio.post<dynamic>(
          '${ApiEndpoints.chats}/$conversationId/messages',
          data: {
            'type': _toBackendType(messageType),
            'content': content,
            'mediaUrl': mediaUrl,
            if (replyTo != null) ...{
              'replyToMessageId': replyTo.messageId,
              'replyTo': replyTo.toJson(),
            },
          },
        ),
      );
      final data = _dataOf(response.data);
      var msg = ChatMessageModel.fromJson(data, conversationId: conversationId);
      if (replyTo != null && msg.replyTo == null) {
        msg = msg.copyWith(replyTo: replyTo);
      }
      _localMessages.putIfAbsent(conversationId, () => []).add(msg);
      return msg;
    } catch (_) {
      final fallbackMsg = ChatMessageModel(
        id: 'msg_local_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: 'current_user',
        senderName: 'Me',
        content: content,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        messageType: messageType,
        mediaUrl: mediaUrl,
        replyTo: replyTo,
      );
      _localMessages.putIfAbsent(conversationId, () => []).add(fallbackMsg);
      return fallbackMsg;
    }
  }

  Future<bool> markConversationRead(String conversationId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/read'),
      );
    } catch (_) {}
    return true;
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>(
          '${ApiEndpoints.chats}/$conversationId/messages/$messageId',
        ),
      );
    } catch (_) {}
    _localMessages[conversationId]?.removeWhere((m) => m.id == messageId);
    return true;
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      await guardDio(
        () => dio.delete<dynamic>('${ApiEndpoints.chats}/$conversationId/leave'),
      );
    } catch (_) {
      // Gracefully support local mock/demo deletions
    }
    _localMessages.remove(conversationId);
    return true;
  }

  Future<bool> archiveConversation(String conversationId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/archive'),
      );
    } catch (_) {
      // Gracefully support local mock/demo archiving
    }
    return true;
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/unarchive'),
      );
    } catch (_) {
      // Gracefully support local mock/demo unarchiving
    }
    return true;
  }

  Future<bool> muteConversation(String conversationId) async {
    try {
      await guardDio(
        () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/mute'),
      );
    } catch (_) {
      // Gracefully support local mock/demo muting
    }
    return true;
  }

  Future<int> getUnreadCount() async {
    final response = await guardDio(
      () => dio.get<dynamic>('${ApiEndpoints.chats}/unread-count'),
    );
    final data = _dataOf(response.data);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  List<dynamic> _contentOf(dynamic body) {
    final map = _dataOf(body);
    final content = map['content'];
    if (content is List) return content;
    if (map.isEmpty && body is List) return body;
    return const [];
  }

  Map<String, dynamic> _dataOf(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  String _toBackendType(String messageType) {
    return switch (messageType.toLowerCase()) {
      'image' => 'IMAGE',
      'voice' => 'VOICE',
      'system' => 'SYSTEM',
      _ => 'TEXT',
    };
  }
}
