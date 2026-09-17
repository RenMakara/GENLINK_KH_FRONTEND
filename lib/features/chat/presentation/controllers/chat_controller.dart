import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_models.dart';

class ChatController extends GetxController {
  final ChatRepositoryImpl repository;

  ChatController({required this.repository});

  final conversations = <ChatConversationModel>[].obs;
  final activeMessages = <ChatMessageModel>[].obs;
  final activeConversation = Rxn<ChatConversationModel>();

  final replyingToMessage = Rxn<ChatMessageModel>();
  final pinnedMessage = Rxn<ChatMessageModel>();
  final typingUserName = RxnString();

  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;
  final unreadCount = 0.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    fetchUnreadCount();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  int get totalUnreadCount {
    if (unreadCount.value > 0) return unreadCount.value;
    return conversations.fold(0, (sum, item) => sum + item.unreadCount);
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await repository.getUnreadCount();
      unreadCount.value = count;
    } catch (_) {
      unreadCount.value =
          conversations.fold(0, (sum, item) => sum + item.unreadCount);
    }
  }

  Future<void> fetchConversations() async {
    isLoadingConversations.value = true;
    try {
      final list = await repository.getConversations();
      conversations.assignAll(list);
      final localCount =
          conversations.fold(0, (sum, item) => sum + item.unreadCount);
      if (unreadCount.value == 0 || localCount > 0) {
        unreadCount.value = localCount;
      }
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

  Future<ChatConversationModel?> openConversationById(String roomId) async {
    if (roomId.isEmpty) return null;

    final existingIdx = conversations.indexWhere((c) => c.id == roomId);
    if (existingIdx != -1) {
      final conv = conversations[existingIdx];
      await openConversation(conv);
      return conv;
    }

    try {
      await fetchConversations();
      final foundIdx = conversations.indexWhere((c) => c.id == roomId);
      if (foundIdx != -1) {
        final conv = conversations[foundIdx];
        await openConversation(conv);
        return conv;
      }
    } catch (_) {}

    try {
      final room = await repository.getRoom(roomId);
      conversations.insert(0, room);
      conversations.refresh();
      await openConversation(room);
      return room;
    } catch (_) {
      final fallbackRoom = ChatConversationModel(
        id: roomId,
        name: 'Chat Room',
        avatar: 'assets/images/user_profile.png',
        lastMessage: '',
        lastMessageTime: 'Just now',
      );
      conversations.insert(0, fallbackRoom);
      conversations.refresh();
      await openConversation(fallbackRoom);
      return fallbackRoom;
    }
  }

  Future<void> openConversation(ChatConversationModel conv) async {
    activeConversation.value = conv;
    replyingToMessage.value = null;
    pinnedMessage.value = conv.pinnedMessage;
    conv.unreadCount = 0;
    conversations.refresh();
    unreadCount.value =
        conversations.fold(0, (sum, item) => sum + item.unreadCount);
    try {
      await repository.markConversationRead(conv.id);
    } catch (_) {}

    isLoadingMessages.value = true;
    try {
      final msgs = await repository.getMessages(conv.id);
      if (msgs.isNotEmpty) {
        activeMessages.assignAll(msgs);
        final pinned = msgs.firstWhereOrNull((m) => m.isPinned);
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
      conversations.insert(0, newGroup);
      conversations.refresh();
      await openConversation(newGroup);
      return newGroup;
    } catch (e) {
      Get.snackbar(
        'Group creation failed',
        'Could not create the group chat.',
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

    final conv = activeConversation.value;
    if (conv == null) return;

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
        text.isEmpty
            ? (type == 'image' ? '📷 Photo' : 'Shared attachment')
            : text,
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
        content: text.isEmpty
            ? (type == 'image' ? '📷 Photo' : 'Shared attachment')
            : text,
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
        messageType: type,
        mediaUrl: mediaUrl,
        replyTo: effectiveReplyTo,
        deliveryStatus: 'failed',
      );
    } finally {
      isSendingMessage.value = false;
    }

    if (!activeMessages.any((m) => m.id == newMsg.id)) {
      activeMessages.add(newMsg);
    }
    conv.lastMessage = newMsg.content;
    conv.lastMessageTime = 'Just now';
    conv.unreadCount = 0;
    _moveConversationToTop(conv);
    conversations.refresh();
    _scrollToBottom();
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

  Future<ChatMessageModel> sendStoryReply({
    required String userName,
    required String userAvatar,
    required String message,
    String? mediaUrl,
    String? storyId,
    String? userId,
  }) async {
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

    // 2. Call Repository send message API, with resilient fallback for local mock/demo
    ChatMessageModel newMsg;
    try {
      newMsg = await repository.sendMessage(
        conv.id,
        message,
        messageType: 'story_reply',
        mediaUrl: mediaUrl,
      );
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
        storyReference: StoryReference(
          storyId: storyId,
          mediaUrl: mediaUrl,
          isExpired: false,
        ),
      );
    }

    // 3. Update conversation metadata and place at top of list
    conv.lastMessage = message;
    conv.lastMessageTime = 'Just now';
    conv.unreadCount = 0;
    conversations.insert(0, conv);
    conversations.refresh();

    // 4. Set as active conversation and switch activeMessages cleanly without leaking prior conversation messages
    if (activeConversation.value?.id != conv.id) {
      activeConversation.value = conv;
      replyingToMessage.value = null;
      pinnedMessage.value = conv.pinnedMessage;
      try {
        final existingMsgs = await repository.getMessages(conv.id);
        activeMessages.assignAll(existingMsgs);
      } catch (_) {
        activeMessages.clear();
      }
    }
    if (!activeMessages.any((m) => m.id == newMsg.id)) {
      activeMessages.add(newMsg);
    }
    _scrollToBottom();

    return newMsg;
  }

  void onMessageReceived(ChatMessageModel message) {
    if (activeConversation.value?.id == message.conversationId) {
      final exists = activeMessages.any((m) => m.id == message.id);
      if (!exists) {
        activeMessages.add(message);
        _scrollToBottom();
      }
      repository.markConversationRead(message.conversationId);
    }

    final idx = conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx != -1) {
      final conv = conversations[idx];
      conv.lastMessage = message.content;
      conv.lastMessageTime = 'Just now';
      if (activeConversation.value?.id != message.conversationId) {
        conv.unreadCount += 1;
      }
      _moveConversationToTop(conv);
      conversations.refresh();
    }
  }

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
