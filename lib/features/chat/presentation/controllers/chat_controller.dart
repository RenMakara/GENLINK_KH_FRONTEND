import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/datasources/chat_websocket_client.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_models.dart';

class ChatController extends GetxController {
  final ChatRepositoryImpl repository;
  ChatWebSocketClient? webSocketClient;

  ChatController({
    required this.repository,
    this.webSocketClient,
  });

  final conversations = <ChatConversationModel>[].obs;
  final activeMessages = <ChatMessageModel>[].obs;
  final activeConversation = Rxn<ChatConversationModel>();

  final replyingToMessage = Rxn<ChatMessageModel>();
  final pinnedMessage = Rxn<ChatMessageModel>();
  final typingUserName = RxnString();

  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    if (webSocketClient != null) {
      webSocketClient!.connect();
    }
  }

  void initWebSocket({String? token, String? url}) {
    webSocketClient?.disconnect();
    webSocketClient = ChatWebSocketClient(
      onMessageReceived: onMessageReceived,
    );
    webSocketClient!.connect(token: token, url: url);
  }

  @override
  void onClose() {
    webSocketClient?.disconnect();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  int get totalUnreadCount =>
      conversations.fold(0, (sum, item) => sum + item.unreadCount);

  Future<void> fetchConversations() async {
    isLoadingConversations.value = true;
    try {
      final list = await repository.getConversations();
      conversations.assignAll(list);
    } catch (e) {
      Get.snackbar(
        'Chats unavailable',
        'Could not load your chats. Pull to retry.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> openConversation(ChatConversationModel conv) async {
    final isDifferentConv = activeConversation.value?.id != conv.id;
    activeConversation.value = conv;
    replyingToMessage.value = null;
    pinnedMessage.value = conv.pinnedMessage;
    conv.unreadCount = 0;
    conversations.refresh();
    if (isDifferentConv) {
      activeMessages.clear();
    }
    try {
      await repository.markConversationRead(conv.id);
    } catch (_) {}

    isLoadingMessages.value = true;
    try {
      final msgs = await repository.getMessages(conv.id);
      if (msgs.isNotEmpty) {
        final deduped = _deduplicateMessages(msgs);
        activeMessages.assignAll(deduped);
        final pinned = deduped.firstWhereOrNull((m) => m.isPinned);
        if (pinned != null) {
          pinnedMessage.value = pinned;
        }
      }
      _scrollToBottom();
    } catch (e) {
      // Preserve local messages for mock / demo state resilience
      if (activeMessages.isEmpty && conv.lastMessage.isNotEmpty) {
        activeMessages.add(
          ChatMessageModel(
            id: 'msg_last_${conv.id}',
            conversationId: conv.id,
            senderId: 'other',
            senderName: conv.name,
            senderAvatar: conv.avatar,
            content: conv.lastMessage,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            timeAgo: conv.lastMessageTime,
            isMine: false,
          ),
        );
      }
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<ChatConversationModel?> openPrivateChat(
    String userId, {
    String? name,
    String? avatar,
  }) async {
    // 1. Check if conversation already exists locally for this user
    final existingIdx = conversations.indexWhere((c) {
      if (c.id == userId || c.id == 'private_$userId' || c.id == 'room_$userId') {
        return true;
      }
      if (name != null &&
          name.isNotEmpty &&
          c.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return true;
      }
      return false;
    });

    if (existingIdx != -1) {
      final existing = conversations[existingIdx];
      final updated = existing.copyWith(isArchived: false);
      conversations[existingIdx] = updated;
      _moveConversationToTop(updated);
      conversations.refresh();
      await openConversation(updated);
      return updated;
    }

    // 2. Otherwise open via repository or create fallback
    try {
      final conv = await repository.openPrivateChat(userId);
      final backendIdx = conversations.indexWhere((c) => c.id == conv.id);
      if (backendIdx != -1) {
        conversations[backendIdx] = conv.copyWith(isArchived: false);
        _moveConversationToTop(conversations[backendIdx]);
      } else {
        conversations.insert(0, conv);
      }
      conversations.refresh();
      final openedConv = conversations.firstWhere((c) => c.id == conv.id);
      await openConversation(openedConv);
      return openedConv;
    } catch (e) {
      final fallbackConv = ChatConversationModel(
        id: 'private_$userId',
        name: name ?? 'User',
        avatar: avatar ?? 'assets/images/user_profile.png',
        isGroup: false,
        isOnline: true,
        lastMessage: '',
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );
      conversations.insert(0, fallbackConv);
      conversations.refresh();
      await openConversation(fallbackConv);
      return fallbackConv;
    }
  }

  Future<ChatConversationModel?> createGroup(
    String name,
    List<String> memberUserIds,
  ) async {
    try {
      final newGroup = await repository.createGroup(name, memberUserIds);
      conversations.removeWhere((c) => c.id == newGroup.id);
      conversations.insert(0, newGroup);
      conversations.refresh();
      await openConversation(newGroup);
      return newGroup;
    } catch (e) {
      Get.snackbar(
        'chat.groupCreationFailed'.tr.isNotEmpty &&
                'chat.groupCreationFailed'.tr != 'chat.groupCreationFailed'
            ? 'chat.groupCreationFailed'.tr
            : 'Group creation failed',
        'chat.groupCreationFailedDesc'.tr.isNotEmpty &&
                'chat.groupCreationFailedDesc'.tr != 'chat.groupCreationFailedDesc'
            ? 'chat.groupCreationFailedDesc'.tr
            : 'Could not create the group chat.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  void setReplyingTo(ChatMessageModel? message) {
    replyingToMessage.value = message;
  }

  void cancelReply() {
    replyingToMessage.value = null;
  }

  void toggleReaction(String messageId, String emoji) {
    final msgIdx = activeMessages.indexWhere((m) => m.id == messageId);
    if (msgIdx == -1) return;
    final msg = activeMessages[msgIdx];
    final existingReactions = List<ChatReactionModel>.from(msg.reactions);
    final rIdx = existingReactions.indexWhere((r) => r.emoji == emoji);

    if (rIdx != -1) {
      final r = existingReactions[rIdx];
      if (r.hasReacted) {
        if (r.count <= 1) {
          existingReactions.removeAt(rIdx);
        } else {
          existingReactions[rIdx] = r.copyWith(
            count: r.count - 1,
            hasReacted: false,
          );
        }
      } else {
        existingReactions[rIdx] = r.copyWith(
          count: r.count + 1,
          hasReacted: true,
        );
      }
    } else {
      existingReactions.add(ChatReactionModel(
        emoji: emoji,
        count: 1,
        hasReacted: true,
      ));
    }

    activeMessages[msgIdx] = msg.copyWith(reactions: existingReactions);
    activeMessages.refresh();
  }

  void togglePinMessage(ChatMessageModel message) {
    final conv = activeConversation.value;
    if (conv == null) return;

    if (pinnedMessage.value?.id == message.id) {
      pinnedMessage.value = null;
      final idx = activeMessages.indexWhere((m) => m.id == message.id);
      if (idx != -1) {
        activeMessages[idx] = activeMessages[idx].copyWith(isPinned: false);
        activeMessages.refresh();
      }
      activeConversation.value = conv.copyWith(pinnedMessage: null);
      repository.unpinMessage(conv.id);
    } else {
      for (var i = 0; i < activeMessages.length; i++) {
        if (activeMessages[i].isPinned) {
          activeMessages[i] = activeMessages[i].copyWith(isPinned: false);
        }
      }
      final updatedMsg = message.copyWith(isPinned: true);
      final idx = activeMessages.indexWhere((m) => m.id == message.id);
      if (idx != -1) {
        activeMessages[idx] = updatedMsg;
        activeMessages.refresh();
      }
      pinnedMessage.value = updatedMsg;
      activeConversation.value = conv.copyWith(pinnedMessage: updatedMsg);
      repository.pinMessage(conv.id, message.id);
    }
    conversations.refresh();
  }

  void unpinMessage() {
    if (pinnedMessage.value != null) {
      togglePinMessage(pinnedMessage.value!);
    }
  }

  void simulateTyping(String name, {Duration duration = const Duration(seconds: 3)}) {
    typingUserName.value = name;
    Future.delayed(duration, () {
      if (typingUserName.value == name) {
        typingUserName.value = null;
      }
    });
  }

  Future<void> sendMessage({
    String type = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
  }) async {
    final text = textController.text.trim();
    if (text.isEmpty && mediaUrl == null) return;
    if (isSendingMessage.value) return;

    final conv = activeConversation.value;
    if (conv == null) return;

    final messageContent = text.isEmpty
        ? (type == 'image' ? '📷 Photo' : 'Shared attachment')
        : text;

    // Double-tap guard: suppress duplicate send if identical message was sent in last 2 seconds
    if (activeMessages.isNotEmpty) {
      final last = activeMessages.last;
      if (last.isMine &&
          last.content == messageContent &&
          DateTime.now().difference(last.timestamp).inSeconds < 2) {
        return;
      }
    }

    final effectiveReplyTo = replyTo ??
        (replyingToMessage.value != null
            ? ChatReplyReference(
                messageId: replyingToMessage.value!.id,
                senderName: replyingToMessage.value!.senderName,
                content: replyingToMessage.value!.content,
                messageType: replyingToMessage.value!.messageType,
                mediaUrl: replyingToMessage.value!.mediaUrl,
              )
            : null);

    textController.clear();
    replyingToMessage.value = null;
    isSendingMessage.value = true;

    ChatMessageModel newMsg;
    try {
      newMsg = await repository.sendMessage(
        conv.id,
        messageContent,
        messageType: type,
        mediaUrl: mediaUrl,
        replyTo: effectiveReplyTo,
      );
    } catch (_) {
      // Fallback local message for mock / demo / offline state
      newMsg = ChatMessageModel(
        id: 'msg_local_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conv.id,
        senderId: 'current_user',
        senderName: 'Me',
        content: messageContent,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        messageType: type,
        mediaUrl: mediaUrl,
        replyTo: effectiveReplyTo,
      );
    } finally {
      isSendingMessage.value = false;
    }

    _safeAddOrUpdateActiveMessage(newMsg);

    conv.lastMessage = newMsg.content;
    conv.lastMessageTime = 'Just now';
    conv.unreadCount = 0;
    _moveConversationToTop(conv);
    conversations.refresh();
    repository.getCurrentUserId().then((uId) {
      repository.localDataSource.saveConversation(uId, conv);
    });
  }

  Future<bool> deleteMessage(String messageId) async {
    final conv = activeConversation.value;
    if (conv == null) return false;
    try {
      final ok = await repository.deleteMessage(conv.id, messageId);
      if (ok) {
        activeMessages.removeWhere((m) => m.id == messageId);
      }
      return ok;
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        'Could not delete message.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      await repository.deleteConversation(conversationId);
    } catch (_) {}
    conversations.removeWhere((c) => c.id == conversationId);
    if (activeConversation.value?.id == conversationId) {
      activeConversation.value = null;
      activeMessages.clear();
    }
    conversations.refresh();
    return true;
  }

  Future<bool> archiveConversation(String conversationId) async {
    try {
      await repository.archiveConversation(conversationId);
    } catch (_) {}
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final updated = conversations[idx].copyWith(isArchived: true);
      conversations[idx] = updated;
      conversations.refresh();
    }
    return true;
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    try {
      await repository.unarchiveConversation(conversationId);
    } catch (_) {}
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final updated = conversations[idx].copyWith(isArchived: false);
      conversations[idx] = updated;
      conversations.refresh();
    }
    return true;
  }

  Future<bool> muteConversation(String conversationId) async {
    try {
      await repository.muteConversation(conversationId);
    } catch (_) {}
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final current = conversations[idx];
      final updated = current.copyWith(isMuted: !current.isMuted);
      conversations[idx] = updated;
      conversations.refresh();
    }
    return true;
  }

  Future<bool> renameGroup(String conversationId, String newName) async {
    final ok = await repository.renameGroup(conversationId, newName);
    if (ok) {
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        conversations[idx] = conversations[idx].copyWith(name: newName);
        conversations.refresh();
      }
      if (activeConversation.value?.id == conversationId) {
        activeConversation.value = activeConversation.value?.copyWith(name: newName);
      }
    }
    return ok;
  }

  Future<bool> addGroupMembers(String conversationId, List<String> userIds) async {
    return repository.addGroupMembers(conversationId, userIds);
  }

  Future<bool> removeGroupMember(String conversationId, String userId) async {
    return repository.removeGroupMember(conversationId, userId);
  }

  Future<bool> changeMemberRole(String conversationId, String userId, String role) async {
    return repository.changeMemberRole(conversationId, userId, role);
  }

  Future<bool> leaveGroup(String conversationId) async {
    final ok = await repository.leaveGroup(conversationId);
    if (ok) {
      conversations.removeWhere((c) => c.id == conversationId);
      if (activeConversation.value?.id == conversationId) {
        activeConversation.value = null;
        activeMessages.clear();
      }
      conversations.refresh();
    }
    return ok;
  }

  Future<ChatMessageModel> sendStoryReply({
    required String userName,
    required String userAvatar,
    required String message,
    String? mediaUrl,
    String? storyId,
    String? userId,
  }) async {
    // Double-tap guard: suppress duplicate reply if sent in last 2 seconds
    if (activeMessages.isNotEmpty) {
      final last = activeMessages.last;
      if (last.isMine &&
          last.content == message &&
          DateTime.now().difference(last.timestamp).inSeconds < 2) {
        return last;
      }
    }

    // 1. Find existing conversation or create a new one
    var convIndex = conversations.indexWhere((c) {
      if (userId != null && userId.isNotEmpty) {
        if (c.id == userId || c.id == 'private_$userId' || c.id == 'room_$userId') {
          return true;
        }
      }
      return c.name.trim().toLowerCase() == userName.trim().toLowerCase();
    });

    ChatConversationModel conv;

    if (convIndex != -1) {
      conv = conversations.removeAt(convIndex);
    } else {
      final safeId = (userId != null && userId.isNotEmpty)
          ? userId
          : userName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      conv = ChatConversationModel(
        id: 'private_$safeId',
        name: userName,
        avatar: userAvatar,
        isGroup: false,
        isOnline: true,
        lastMessage: message,
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );
    }

    final effectiveStoryRef = StoryReference(
      storyId: storyId,
      mediaUrl: mediaUrl,
      isExpired: false,
    );

    // 2. Call Repository send message API, with resilient fallback for local mock/demo
    ChatMessageModel newMsg;
    try {
      newMsg = await repository.sendMessage(
        conv.id,
        message,
        messageType: 'story_reply',
        mediaUrl: mediaUrl,
        storyReference: effectiveStoryRef,
      );
      if (newMsg.storyReference == null) {
        newMsg = newMsg.copyWith(storyReference: effectiveStoryRef);
      }
    } catch (_) {
      // Fallback local message for mock / demo / offline state
      newMsg = ChatMessageModel(
        id: 'msg_story_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conv.id,
        senderId: 'current_user',
        senderName: 'Me',
        content: message,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        messageType: 'story_reply',
        mediaUrl: mediaUrl,
        storyReference: effectiveStoryRef,
      );
    }

    // 3. Update conversation metadata and place at top of list
    conv.lastMessage = message;
    conv.lastMessageTime = 'Just now';
    conv.unreadCount = 0;
    conversations.insert(0, conv);
    conversations.refresh();
    repository.getCurrentUserId().then((uId) {
      repository.localDataSource.saveConversation(uId, conv);
      repository.localDataSource.saveMessage(uId, conv.id, newMsg);
    });

    // 4. Set as active conversation and switch activeMessages cleanly without leaking prior conversation messages
    if (activeConversation.value?.id != conv.id) {
      activeConversation.value = conv;
      replyingToMessage.value = null;
      pinnedMessage.value = conv.pinnedMessage;
      try {
        final existingMsgs = await repository.getMessages(conv.id);
        activeMessages.assignAll(_deduplicateMessages(existingMsgs));
      } catch (_) {
        activeMessages.clear();
      }
    }
    _safeAddOrUpdateActiveMessage(newMsg);

    return newMsg;
  }

  void onMessageReceived(ChatMessageModel message) {
    var effectiveConvId = message.conversationId;
    if (effectiveConvId.isEmpty) {
      final active = activeConversation.value;
      if (active != null &&
          (active.id == message.senderId ||
              active.id == 'private_${message.senderId}' ||
              active.id == 'room_${message.senderId}' ||
              active.name.trim().toLowerCase() == message.senderName.trim().toLowerCase())) {
        effectiveConvId = active.id;
      } else {
        final matchedConv = conversations.firstWhereOrNull((c) =>
            c.id == message.senderId ||
            c.id == 'private_${message.senderId}' ||
            c.id == 'room_${message.senderId}' ||
            c.name.trim().toLowerCase() == message.senderName.trim().toLowerCase());
        if (matchedConv != null) {
          effectiveConvId = matchedConv.id;
        } else {
          effectiveConvId = 'private_${message.senderId}';
        }
      }
    }

    final resolvedMessage = message.conversationId.isEmpty
        ? message.copyWith(conversationId: effectiveConvId)
        : message;

    if (activeConversation.value?.id == effectiveConvId) {
      _safeAddOrUpdateActiveMessage(resolvedMessage);
      try {
        repository.markConversationRead(effectiveConvId);
      } catch (_) {}
    }

    final idx = conversations.indexWhere((c) => c.id == effectiveConvId);
    if (idx != -1) {
      final conv = conversations[idx];
      conv.lastMessage = resolvedMessage.content;
      conv.lastMessageTime = 'Just now';
      if (activeConversation.value?.id != effectiveConvId) {
        conv.unreadCount += 1;
      }
      _moveConversationToTop(conv);
      conversations.refresh();
    } else {
      // New conversation initiated by other user
      final newConv = ChatConversationModel(
        id: effectiveConvId,
        name: resolvedMessage.senderName,
        avatar: (resolvedMessage.senderAvatar != null && resolvedMessage.senderAvatar!.isNotEmpty)
            ? resolvedMessage.senderAvatar!
            : 'assets/images/user_profile.png',
        isGroup: false,
        isOnline: true,
        lastMessage: resolvedMessage.content,
        lastMessageTime: 'Just now',
        unreadCount: activeConversation.value?.id == effectiveConvId ? 0 : 1,
      );
      conversations.insert(0, newConv);
      conversations.refresh();
    }

    repository.getCurrentUserId().then((uId) {
      repository.localDataSource.saveMessage(uId, effectiveConvId, resolvedMessage);
      final c = conversations.firstWhereOrNull((item) => item.id == effectiveConvId);
      if (c != null) {
        repository.localDataSource.saveConversation(uId, c);
      }
    });
  }

  bool _safeAddOrUpdateActiveMessage(ChatMessageModel incoming) {
    // 1. Check exact match by ID
    final exactIdx = activeMessages.indexWhere((m) => m.id == incoming.id);
    if (exactIdx != -1) {
      activeMessages[exactIdx] = incoming;
      activeMessages.refresh();
      return true;
    }

    // 2. Check if incoming is a server message reconciling an optimistic local message
    final isIncomingReal = !incoming.id.startsWith('msg_local_') &&
        !incoming.id.startsWith('msg_story_') &&
        !incoming.id.startsWith('temp_');

    if (isIncomingReal) {
      final tempIdx = activeMessages.indexWhere((m) =>
          (m.id.startsWith('msg_local_') ||
              m.id.startsWith('msg_story_') ||
              m.id.startsWith('temp_')) &&
          m.content == incoming.content &&
          (m.senderId == incoming.senderId || (m.isMine && incoming.isMine)) &&
          m.timestamp.difference(incoming.timestamp).abs().inSeconds < 120);

      if (tempIdx != -1) {
        activeMessages[tempIdx] = incoming;
        activeMessages.refresh();
        return true;
      }
    }

    // 3. Rapid echo / duplicate suppression (within 4 seconds, same sender & content)
    final isDuplicateEcho = activeMessages.reversed.take(5).any((m) =>
        m.content == incoming.content &&
        (m.senderId == incoming.senderId || (m.isMine && incoming.isMine)) &&
        m.timestamp.difference(incoming.timestamp).abs().inSeconds < 4);

    if (isDuplicateEcho) {
      return false;
    }

    // 4. Safe append
    activeMessages.add(incoming);
    _scrollToBottom();
    return true;
  }

  List<ChatMessageModel> _deduplicateMessages(List<ChatMessageModel> messages) {
    final seenIds = <String>{};
    final result = <ChatMessageModel>[];

    for (final m in messages) {
      if (seenIds.contains(m.id)) {
        continue;
      }

      final isTemp = m.id.startsWith('msg_local_') ||
          m.id.startsWith('msg_story_') ||
          m.id.startsWith('temp_');

      if (isTemp) {
        final hasReal = result.any((existing) =>
            !existing.id.startsWith('msg_local_') &&
            !existing.id.startsWith('msg_story_') &&
            !existing.id.startsWith('temp_') &&
            existing.content == m.content &&
            (existing.senderId == m.senderId || existing.isMine == m.isMine) &&
            existing.timestamp.difference(m.timestamp).abs().inSeconds < 120);
        if (hasReal) {
          continue;
        }
      } else {
        result.removeWhere((existing) =>
            (existing.id.startsWith('msg_local_') ||
                existing.id.startsWith('msg_story_') ||
                existing.id.startsWith('temp_')) &&
            existing.content == m.content &&
            (existing.senderId == m.senderId || existing.isMine == m.isMine) &&
            existing.timestamp.difference(m.timestamp).abs().inSeconds < 120);
      }

      seenIds.add(m.id);
      result.add(m);
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  // Public methods exposed for testing and external coordination
  bool safeAddOrUpdateActiveMessage(ChatMessageModel incoming) =>
      _safeAddOrUpdateActiveMessage(incoming);

  List<ChatMessageModel> deduplicateMessages(List<ChatMessageModel> messages) =>
      _deduplicateMessages(messages);

  void _moveConversationToTop(ChatConversationModel conv) {
    final idx = conversations.indexOf(conv);
    if (idx > 0) {
      conversations.removeAt(idx);
      conversations.insert(0, conv);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
