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

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    final response = await guardDio(
      () => dio.get<dynamic>('${ApiEndpoints.chats}/$conversationId/messages'),
    );
    final content = _contentOf(response.data);
    return content
        .map(
          (json) => ChatMessageModel.fromJson(
            json.cast<String, dynamic>(),
            conversationId: conversationId,
          ),
        )
        .toList();
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final response = await guardDio(
      () => dio.post<dynamic>(
        '${ApiEndpoints.chats}/$conversationId/messages',
        data: {
          'type': _toBackendType(messageType),
          'content': content,
          'mediaUrl': mediaUrl,
        },
      ),
    );
    final data = _dataOf(response.data);
    return ChatMessageModel.fromJson(data, conversationId: conversationId);
  }

  Future<bool> markConversationRead(String conversationId) async {
    await guardDio(
      () => dio.post<dynamic>('${ApiEndpoints.chats}/$conversationId/read'),
    );
    return true;
  }

  /// Backend pagination lives inside the ApiResponse envelope as
  /// `data.content`; a plain list is also tolerated for robustness.
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
    return switch (messageType) {
      'image' => 'IMAGE',
      'voice' => 'VOICE',
      _ => 'TEXT',
    };
  }
}
