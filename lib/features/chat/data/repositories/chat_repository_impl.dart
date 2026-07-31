import '../../domain/models/chat_models.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  Future<List<ChatConversationModel>> getConversations() {
    return remoteDataSource.fetchConversations();
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) {
    return remoteDataSource.fetchMessages(conversationId);
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
  }) {
    return remoteDataSource.sendMessage(
      conversationId,
      content,
      messageType: messageType,
      mediaUrl: mediaUrl,
    );
  }

  Future<bool> markConversationRead(String conversationId) {
    return remoteDataSource.markConversationRead(conversationId);
  }
}
