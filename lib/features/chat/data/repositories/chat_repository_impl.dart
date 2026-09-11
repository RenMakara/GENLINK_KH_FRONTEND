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
    ChatReplyReference? replyTo,
  }) {
    return remoteDataSource.sendMessage(
      conversationId,
      content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyTo: replyTo,
    );
  }

  Future<bool> markConversationRead(String conversationId) {
    return remoteDataSource.markConversationRead(conversationId);
  }

  Future<bool> deleteMessage(String conversationId, String messageId) {
    return remoteDataSource.deleteMessage(conversationId, messageId);
  }

  Future<bool> deleteConversation(String conversationId) {
    return remoteDataSource.deleteConversation(conversationId);
  }

  Future<bool> archiveConversation(String conversationId) {
    return remoteDataSource.archiveConversation(conversationId);
  }

  Future<bool> unarchiveConversation(String conversationId) {
    return remoteDataSource.unarchiveConversation(conversationId);
  }

  Future<bool> muteConversation(String conversationId) {
    return remoteDataSource.muteConversation(conversationId);
  }

  Future<bool> pinMessage(String conversationId, String messageId) {
    return remoteDataSource.pinMessage(conversationId, messageId);
  }

  Future<bool> unpinMessage(String conversationId) {
    return remoteDataSource.unpinMessage(conversationId);
  }

  Future<bool> renameGroup(String conversationId, String newName) {
    return remoteDataSource.renameGroup(conversationId, newName);
  }

  Future<bool> addGroupMembers(String conversationId, List<String> userIds) {
    return remoteDataSource.addGroupMembers(conversationId, userIds);
  }

  Future<bool> removeGroupMember(String conversationId, String userId) {
    return remoteDataSource.removeGroupMember(conversationId, userId);
  }

  Future<bool> changeMemberRole(String conversationId, String userId, String role) {
    return remoteDataSource.changeMemberRole(conversationId, userId, role);
  }

  Future<bool> leaveGroup(String conversationId) {
    return remoteDataSource.leaveGroup(conversationId);
  }

  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }
}
