import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/chat_models.dart';

class ChatRemoteDataSource {
  final Dio dio;

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
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.chatUnreadCount),
    );
    final data = _dataOf(response.data);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<ChatConversationModel> getRoom(String roomId) async {
    final response = await guardDio(
      () => dio.get<dynamic>('${ApiEndpoints.chats}/$roomId'),
    );
    final data = _dataOf(response.data);
    return ChatConversationModel.fromRoomResponse(data, roomId: roomId);
  }

  Future<ChatConversationModel> openPrivateChat(String userId) async {
    final response = await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/private/$userId'),
    );
    final data = _dataOf(response.data);
    return ChatConversationModel.fromRoomResponse(
      data,
      participantUserId: userId,
    );
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
          'memberUserIds': memberUserIds,
        },
      ),
    );
    final data = _dataOf(response.data);
    return ChatConversationModel.fromRoomResponse(data);
  }

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
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
    return messages;
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
  }) async {
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
    if (messageType != 'text' && (msg.messageType == 'text' || msg.messageType.isEmpty)) {
      msg = msg.copyWith(messageType: messageType);
    }
    if (mediaUrl != null && (msg.mediaUrl == null || msg.mediaUrl!.isEmpty)) {
      msg = msg.copyWith(mediaUrl: mediaUrl);
    }
    return msg;
  }

  Future<bool> markConversationRead(String conversationId) async {
    await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/read'),
    );
    return true;
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    await guardDio(
      () => dio.delete<dynamic>(
        '${ApiEndpoints.chats}/$conversationId/messages/$messageId',
      ),
    );
    return true;
  }

  Future<bool> deleteConversation(String conversationId) async {
    await guardDio(
      () => dio.delete<dynamic>('${ApiEndpoints.chats}/$conversationId'),
    );
    return true;
  }

  Future<bool> archiveConversation(String conversationId) async {
    await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/archive'),
    );
    return true;
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/unarchive'),
    );
    return true;
  }

  Future<bool> muteConversation(String conversationId) async {
    await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/mute'),
    );
    return true;
  }

  Future<int> getUnreadCount() async {
    final response = await guardDio(
      () => dio.get<dynamic>(ApiEndpoints.chatUnreadCount),
    );
    final data = _dataOf(response.data);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  List<dynamic> _contentOf(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map) {
        final content = data['content'] ?? data['items'] ?? data['messages'];
        if (content is List) return content;
      }
      final content = body['content'] ?? body['items'] ?? body['messages'];
      if (content is List) return content;
    }
    return const [];
  }

  Map<String, dynamic> _dataOf(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return body.cast<String, dynamic>();
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
