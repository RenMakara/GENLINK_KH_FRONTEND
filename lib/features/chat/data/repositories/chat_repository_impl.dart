import '../../domain/models/chat_models.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource? localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  Future<List<ChatConversationModel>> getConversations() async {
    try {
      final list = await remoteDataSource.fetchConversations();
      await localDataSource?.saveConversations(list);
      return list;
    } catch (_) {
      final cached = await localDataSource?.getConversations();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<ChatConversationModel> openPrivateChat(String userId) async {
    final conv = await remoteDataSource.openPrivateChat(userId);
    final existing = await localDataSource?.getConversations() ?? [];
    final idx = existing.indexWhere((c) => c.id == conv.id);
    if (idx != -1) {
      existing[idx] = conv;
    } else {
      existing.insert(0, conv);
    }
    await localDataSource?.saveConversations(existing);
    return conv;
  }

  Future<ChatConversationModel> createGroup(
    String name,
    List<String> memberUserIds,
  ) async {
    final conv = await remoteDataSource.createGroup(name, memberUserIds);
    final existing = await localDataSource?.getConversations() ?? [];
    existing.insert(0, conv);
    await localDataSource?.saveConversations(existing);
    return conv;
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    try {
      final messages = await remoteDataSource.fetchMessages(conversationId);
      await localDataSource?.saveMessages(conversationId, messages);
      return messages;
    } catch (_) {
      final cached = await localDataSource?.getMessages(conversationId);
      return cached ?? [];
    }
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
  }) async {
    final msg = await remoteDataSource.sendMessage(
      conversationId,
      content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyTo: replyTo,
    );
    await localDataSource?.saveMessage(conversationId, msg);
    return msg;
  }

  Future<bool> markConversationRead(String conversationId) {
    return remoteDataSource.markConversationRead(conversationId);
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    final ok = await remoteDataSource.deleteMessage(conversationId, messageId);
    if (ok) {
      await localDataSource?.deleteMessage(conversationId, messageId);
    }
    return ok;
  }

  Future<bool> deleteConversation(String conversationId) async {
    final ok = await remoteDataSource.deleteConversation(conversationId);
    if (ok) {
      await localDataSource?.deleteConversation(conversationId);
    }
    return ok;
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

  Future<ChatConversationModel> getRoom(String roomId) {
    return remoteDataSource.getRoom(roomId);
  }

  Future<int> getUnreadCount() {
    return remoteDataSource.fetchUnreadCount();
  }
}
