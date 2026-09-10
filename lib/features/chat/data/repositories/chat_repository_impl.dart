import '../../domain/models/chat_models.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  Future<List<ChatConversationModel>> getConversations() {
    return remoteDataSource.fetchConversations();
  }

  Future<ChatConversationModel> openPrivateChat(String userId) {
    return remoteDataSource.openPrivateChat(userId);
  }

  Future<ChatConversationModel> createGroup(
    String name,
    List<String> memberUserIds,
  ) {
    return remoteDataSource.createGroup(name, memberUserIds);
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

  Future<bool> deleteMessage(String conversationId, String messageId) {
    return remoteDataSource.deleteMessage(conversationId, messageId);
  }

  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }
}
