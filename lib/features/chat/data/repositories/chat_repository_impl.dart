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
    List<String> memberUserIds, {
    String? avatarUrl,
  }) async {
    final conv = await remoteDataSource.createGroup(
      name,
      memberUserIds,
      avatarUrl: avatarUrl,
    );
    final existing = await localDataSource?.getConversations() ?? [];
    existing.insert(0, conv);
    await localDataSource?.saveConversations(existing);
    return conv;
  }

  Future<ChatConversationModel> renameGroup(
    String roomId, {
    String? name,
    String? avatarUrl,
  }) async {
    final updated = await remoteDataSource.renameGroup(
      roomId,
      name: name,
      avatarUrl: avatarUrl,
    );
    final existing = await localDataSource?.getConversations() ?? [];
    final idx = existing.indexWhere((c) => c.id == roomId);
    if (idx != -1) {
      existing[idx] = updated;
      await localDataSource?.saveConversations(existing);
    }
    return updated;
  }

  Future<ChatConversationModel> addMembers(
    String roomId,
    List<String> memberIds,
  ) async {
    final updated = await remoteDataSource.addMembers(roomId, memberIds);
    final existing = await localDataSource?.getConversations() ?? [];
    final idx = existing.indexWhere((c) => c.id == roomId);
    if (idx != -1) {
      existing[idx] = updated;
      await localDataSource?.saveConversations(existing);
    }
    return updated;
  }

  Future<bool> leaveGroup(String roomId) async {
    final ok = await remoteDataSource.leaveGroup(roomId);
    if (ok) {
      await localDataSource?.deleteConversation(roomId);
    }
    return ok;
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    try {
      final page = await getMessagesPage(conversationId, page: 0, size: 30);
      return page.content;
    } catch (_) {
      final cached = await localDataSource?.getMessages(conversationId);
      return cached ?? [];
    }
  }

  Future<ChatMessagePageModel> getMessagesPage(
    String conversationId, {
    int page = 0,
    int size = 30,
  }) async {
    try {
      final result = await remoteDataSource.fetchMessagesPage(
        conversationId,
        page: page,
        size: size,
      );
      if (page == 0) {
        await localDataSource?.saveMessages(conversationId, result.content);
      }
      return result;
    } catch (_) {
      if (page != 0) rethrow;
      final cached = await localDataSource?.getMessages(conversationId);
      if (cached != null) {
        return ChatMessagePageModel(
          content: List<ChatMessageModel>.from(cached)
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
          page: 0,
          hasNext: false,
        );
      }
      rethrow;
    }
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
    SharedContentModel? sharedContent,
    StoryReference? storyReference,
  }) async {
    final msg = await remoteDataSource.sendMessage(
      conversationId,
      content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyTo: replyTo,
      sharedContent: sharedContent,
      storyReference: storyReference,
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

  Future<List<Map<String, dynamic>>> searchUsers(String query) {
    return remoteDataSource.searchUsers(query);
  }

  Future<List<Map<String, dynamic>>> getEligibleUsers({String? currentUserId}) {
    return remoteDataSource.getEligibleUsers(currentUserId: currentUserId);
  }
}
