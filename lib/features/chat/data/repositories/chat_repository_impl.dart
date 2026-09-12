import 'package:get/get.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/chat_models.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final SecureStorage? secureStorage;
  String? currentUserIdOverride;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    ChatLocalDataSource? localDataSource,
    SecureStorage? secureStorage,
    this.currentUserIdOverride,
  })  : localDataSource = localDataSource ?? ChatLocalDataSource(),
        secureStorage = secureStorage ??
            (Get.isRegistered<SecureStorage>() ? Get.find<SecureStorage>() : null);

  /// Resolves the current user's ID for user-isolated local caching.
  Future<String> getCurrentUserId() async {
    if (currentUserIdOverride != null && currentUserIdOverride!.isNotEmpty) {
      return currentUserIdOverride!;
    }
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final u = auth.currentUser.value;
      if (u != null && u.id.isNotEmpty) {
        return u.id;
      }
    }
    if (secureStorage != null) {
      try {
        final stored = await secureStorage!.readUserId();
        if (stored != null && stored.isNotEmpty) {
          return stored;
        }
      } catch (_) {}
    }
    return 'user_sokny';
  }

  /// Retrieves conversations: returns cached conversations on offline/demo mode,
  /// or merges remote conversations into the local persistent store when online.
  Future<List<ChatConversationModel>> getConversations() async {
    final userId = await getCurrentUserId();
    final localList = await localDataSource.getConversations(userId);

    try {
      final remoteList = await remoteDataSource.fetchConversations();
      // Merge remote list with any local conversations (e.g. newly created demo rooms)
      final merged = <ChatConversationModel>[...remoteList];
      for (final local in localList) {
        final exists = merged.any((r) =>
            r.id == local.id ||
            (!r.isGroup &&
                !local.isGroup &&
                r.name.trim().toLowerCase() == local.name.trim().toLowerCase()));
        if (!exists) {
          merged.add(local);
        }
      }
      await localDataSource.saveConversations(userId, merged);
      return merged;
    } catch (_) {
      // Offline, demo mode, or network failure: reliably return persisted local list
      return localList;
    }
  }

  /// Opens or creates a 1:1 chat room, persisting to local storage.
  Future<ChatConversationModel> openPrivateChat(String userId) async {
    final currentUserId = await getCurrentUserId();
    final localList = await localDataSource.getConversations(currentUserId);
    final existing = localList.firstWhereOrNull((c) =>
        c.id == userId ||
        c.id == 'private_$userId' ||
        c.id == 'room_$userId');
    if (existing != null) {
      return existing;
    }

    ChatConversationModel conv;
    try {
      conv = await remoteDataSource.openPrivateChat(userId);
    } catch (_) {
      final isSokny =
          userId == 'user_sokny' || userId.toLowerCase().contains('sokny');
      final isChansela =
          userId == 'user_chansela' || userId.toLowerCase().contains('chansela');
      conv = ChatConversationModel(
        id: 'private_$userId',
        name: isSokny ? 'Sokny Enat' : (isChansela ? 'Heng Chansela' : 'User'),
        avatar: isSokny
            ? 'assets/images/user_profile.png'
            : (isChansela
                ? 'assets/images/heng_chansela_profile.png'
                : 'assets/images/user_profile.png'),
        isGroup: false,
        isOnline: true,
        lastMessage: '',
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );
    }
    await localDataSource.saveConversation(currentUserId, conv);
    return conv;
  }

  /// Creates a group conversation and stores it locally for demo/offline resilience.
  Future<ChatConversationModel> createGroup(
    String name,
    List<String> memberUserIds,
  ) async {
    final currentUserId = await getCurrentUserId();
    ChatConversationModel group;
    try {
      group = await remoteDataSource.createGroup(name, memberUserIds);
    } catch (_) {
      final fallbackId = 'group_${DateTime.now().millisecondsSinceEpoch}';
      group = ChatConversationModel(
        id: fallbackId,
        name: name,
        avatar: 'assets/images/heng_chansela_profile.png',
        isGroup: true,
        isOnline: true,
        lastMessage: 'Group created',
        lastMessageTime: 'Just now',
        unreadCount: 0,
        membersCount: memberUserIds.length + 1,
      );
      final welcomeMsg = ChatMessageModel(
        id: 'msg_welcome_$fallbackId',
        conversationId: fallbackId,
        senderId: 'system',
        senderName: 'GenLink',
        content: 'You created group "$name"',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
        isSystemMessage: true,
        messageType: 'system',
      );
      await localDataSource.saveMessage(currentUserId, fallbackId, welcomeMsg);
    }
    await localDataSource.saveConversation(currentUserId, group);
    return group;
  }

  /// Retrieves messages for a conversation: returns cached history on offline/demo mode,
  /// or merges remote messages into local persistent store when online.
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    final localMessages =
        await localDataSource.getMessages(currentUserId, conversationId);

    try {
      final remoteMessages =
          await remoteDataSource.fetchMessages(conversationId);
      final merged = <ChatMessageModel>[...remoteMessages];
      for (final l in localMessages) {
        final exists = merged.any((r) =>
            r.id == l.id ||
            (r.content == l.content &&
                r.timestamp.difference(l.timestamp).abs().inSeconds < 120));
        if (!exists) {
          merged.add(l);
        }
      }
      merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await localDataSource.saveMessages(currentUserId, conversationId, merged);
      return merged;
    } catch (_) {
      return localMessages;
    }
  }

  /// Sends a message, persisting it immediately into local storage.
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
    StoryReference? storyReference,
  }) async {
    final currentUserId = await getCurrentUserId();
    ChatMessageModel msg;
    try {
      msg = await remoteDataSource.sendMessage(
        conversationId,
        content,
        messageType: messageType,
        mediaUrl: mediaUrl,
        replyTo: replyTo,
        storyReference: storyReference,
      );
    } catch (_) {
      msg = ChatMessageModel(
        id: 'msg_local_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: currentUserId,
        senderName: currentUserId == 'user_sokny' ? 'Sokny Enat' : 'Me',
        content: content,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        messageType: messageType,
        mediaUrl: mediaUrl,
        replyTo: replyTo,
        storyReference: storyReference,
      );
    }
    await localDataSource.saveMessage(currentUserId, conversationId, msg);
    return msg;
  }

  Future<bool> markConversationRead(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.markConversationRead(conversationId);
    } catch (_) {}
    final convs = await localDataSource.getConversations(currentUserId);
    final idx = convs.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      convs[idx].unreadCount = 0;
      await localDataSource.saveConversations(currentUserId, convs);
    }
    return true;
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.deleteMessage(conversationId, messageId);
    } catch (_) {}
    await localDataSource.deleteMessage(currentUserId, conversationId, messageId);
    return true;
  }

  Future<bool> deleteConversation(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.deleteConversation(conversationId);
    } catch (_) {}
    await localDataSource.deleteConversation(currentUserId, conversationId);
    return true;
  }

  Future<bool> archiveConversation(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.archiveConversation(conversationId);
    } catch (_) {}
    final convs = await localDataSource.getConversations(currentUserId);
    final idx = convs.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      convs[idx] = convs[idx].copyWith(isArchived: true);
      await localDataSource.saveConversations(currentUserId, convs);
    }
    return true;
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.unarchiveConversation(conversationId);
    } catch (_) {}
    final convs = await localDataSource.getConversations(currentUserId);
    final idx = convs.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      convs[idx] = convs[idx].copyWith(isArchived: false);
      await localDataSource.saveConversations(currentUserId, convs);
    }
    return true;
  }

  Future<bool> muteConversation(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.muteConversation(conversationId);
    } catch (_) {}
    final convs = await localDataSource.getConversations(currentUserId);
    final idx = convs.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      convs[idx] = convs[idx].copyWith(isMuted: !convs[idx].isMuted);
      await localDataSource.saveConversations(currentUserId, convs);
    }
    return true;
  }

  Future<bool> pinMessage(String conversationId, String messageId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.pinMessage(conversationId, messageId);
    } catch (_) {}
    final msgs =
        await localDataSource.getMessages(currentUserId, conversationId);
    final mIdx = msgs.indexWhere((m) => m.id == messageId);
    ChatMessageModel? pinned;
    if (mIdx != -1) {
      pinned = msgs[mIdx].copyWith(isPinned: true);
      msgs[mIdx] = pinned;
      await localDataSource.saveMessages(currentUserId, conversationId, msgs);
    }
    await localDataSource.updateConversationPinStatus(
      currentUserId,
      conversationId,
      pinned,
    );
    return true;
  }

  Future<bool> unpinMessage(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.unpinMessage(conversationId);
    } catch (_) {}
    final msgs =
        await localDataSource.getMessages(currentUserId, conversationId);
    for (var i = 0; i < msgs.length; i++) {
      if (msgs[i].isPinned) {
        msgs[i] = msgs[i].copyWith(isPinned: false);
      }
    }
    await localDataSource.saveMessages(currentUserId, conversationId, msgs);
    await localDataSource.updateConversationPinStatus(
      currentUserId,
      conversationId,
      null,
    );
    return true;
  }

  Future<bool> renameGroup(String conversationId, String newName) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.renameGroup(conversationId, newName);
    } catch (_) {}
    final convs = await localDataSource.getConversations(currentUserId);
    final idx = convs.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      convs[idx] = convs[idx].copyWith(name: newName);
      await localDataSource.saveConversations(currentUserId, convs);
    }
    return true;
  }

  Future<bool> addGroupMembers(
    String conversationId,
    List<String> userIds,
  ) async {
    return remoteDataSource.addGroupMembers(conversationId, userIds);
  }

  Future<bool> removeGroupMember(
    String conversationId,
    String userId,
  ) async {
    return remoteDataSource.removeGroupMember(conversationId, userId);
  }

  Future<bool> changeMemberRole(
    String conversationId,
    String userId,
    String role,
  ) async {
    return remoteDataSource.changeMemberRole(conversationId, userId, role);
  }

  Future<bool> leaveGroup(String conversationId) async {
    final currentUserId = await getCurrentUserId();
    try {
      await remoteDataSource.leaveGroup(conversationId);
    } catch (_) {}
    await localDataSource.deleteConversation(currentUserId, conversationId);
    return true;
  }

  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }
}
