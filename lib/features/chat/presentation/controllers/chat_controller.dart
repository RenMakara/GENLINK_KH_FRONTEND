import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_models.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  final ChatRepositoryImpl repository;

  ChatController({required this.repository}) {
    debugPrint('[CHAT-LIFECYCLE] controller instance = ${identityHashCode(this)} created');
  }

  final conversations = <ChatConversationModel>[].obs;
  final activeMessages = <ChatMessageModel>[].obs;
  final activeConversation = Rxn<ChatConversationModel>();
  final activeRoomId = RxnString();

  final replyingToMessage = Rxn<ChatMessageModel>();
  final pinnedMessage = Rxn<ChatMessageModel>();
  final typingUserName = RxnString();

  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;
  final unreadCount = 0.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final Set<String> _recentReceivedMessageIds = <String>{};
  int _messageLoadSequence = 0;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[CHAT-LIFECYCLE] controller instance = ${identityHashCode(this)} onInit');
    WidgetsBinding.instance.addObserver(this);
    fetchConversations();
    fetchUnreadCount();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('[CHAT-LIFECYCLE] controller instance = ${identityHashCode(this)} onReady');
  }

  @override
  void onClose() {
    debugPrint('[CHAT-LIFECYCLE] controller instance = ${identityHashCode(this)} onClose');
    WidgetsBinding.instance.removeObserver(this);
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchUnreadCount();
      if (conversations.isNotEmpty) {
        fetchConversations();
      }
      final currentRoomId = activeRoomId.value;
      if (currentRoomId != null && currentRoomId.isNotEmpty) {
        repository.getMessages(currentRoomId).then((msgs) {
          if (activeRoomId.value == currentRoomId) {
            activeMessages.assignAll(msgs);
          }
        }).catchError((_) {}).whenComplete(() {
          if (activeRoomId.value == currentRoomId) {
            isLoadingMessages.value = false;
          }
        });
      }
    }
  }

  int get totalUnreadCount {
    final localCount =
        conversations.fold(0, (sum, item) => sum + item.unreadCount);
    return unreadCount.value > localCount ? unreadCount.value : localCount;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await repository.getUnreadCount();
      final localCount =
          conversations.fold(0, (sum, item) => sum + item.unreadCount);
      unreadCount.value = count > localCount ? count : localCount;
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
      if (unreadCount.value == 0 || localCount > unreadCount.value) {
        unreadCount.value = localCount;
      }
    } catch (e) {
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Chats unavailable',
          'Could not load your chats. Pull to retry.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingConversations.value = false;
    }
  }

  bool _isPostFrameRefreshScheduled = false;

  void safeRefreshConversations() {
    void doRefresh() {
      _isPostFrameRefreshScheduled = false;
      conversations.refresh();
      unreadCount.value =
          conversations.fold(0, (sum, item) => sum + item.unreadCount);
    }

    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) {
      if (!_isPostFrameRefreshScheduled) {
        _isPostFrameRefreshScheduled = true;
        binding.addPostFrameCallback((_) => doRefresh());
      }
    } else {
      doRefresh();
    }
  }

  /// Leaves the active conversation, clearing active room state and messages.
  /// If [roomId] is provided, only leaves if it matches the current active room.
  void leaveConversation({String? roomId}) {
    if (roomId != null && activeRoomId.value != roomId) {
      debugPrint('[CHAT-STATE] leaveConversation ignored: roomId ($roomId) != activeRoomId (${activeRoomId.value})');
      return;
    }
    _messageLoadSequence++;
    debugPrint('[CHAT-STATE] activeMessages.clear() reason = leaveConversation, roomId = $roomId, activeRoomId = ${activeRoomId.value}, sequence = $_messageLoadSequence');
    activeRoomId.value = null;
    activeConversation.value = null;
    activeMessages.clear();
    isLoadingMessages.value = false;
    replyingToMessage.value = null;
    pinnedMessage.value = null;
    typingUserName.value = null;
  }

  /// Canonical method to ensure conversation messages and room metadata are loaded.
  /// Idempotent: If messages for [roomId] are already loaded and active, avoids redundant clearing or re-fetching.
  /// If switching rooms or loading anew, cleanly clears old messages, sets activeRoomId, and loads history.
  Future<ChatConversationModel?> ensureConversationLoaded(
    String roomId, {
    ChatConversationModel? conversation,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) return null;

    debugPrint('[CHAT-LOAD] roomId = $cleanRoomId, activeRoomId = ${activeRoomId.value}, activeConversation = ${activeConversation.value?.id}, activeMessages.length = ${activeMessages.length}, isLoadingMessages = ${isLoadingMessages.value}, _messageLoadSequence = $_messageLoadSequence');

    // 1. Resolve conversation metadata (passed in, existing in conversations, or provisional)
    ChatConversationModel? targetConv = conversation;
    if (targetConv == null) {
      if (activeConversation.value?.id == cleanRoomId) {
        targetConv = activeConversation.value;
      } else {
        final existingIdx = conversations.indexWhere((c) => c.id == cleanRoomId);
        if (existingIdx != -1) {
          targetConv = conversations[existingIdx];
        }
      }
    }

    final isSameRoom = activeRoomId.value == cleanRoomId ||
        (activeRoomId.value == null && activeConversation.value?.id == cleanRoomId);
    final hasActiveMessages = activeMessages.isNotEmpty &&
        activeMessages.every((m) =>
            m.conversationId == cleanRoomId ||
            'private_${m.conversationId}' == cleanRoomId ||
            m.conversationId == 'private_$cleanRoomId');

    // 2. Check if already fully loaded for this room
    if (isSameRoom && hasActiveMessages && !isLoadingMessages.value) {
      debugPrint('[CHAT-LOAD] roomId=$cleanRoomId, activeRoomId=${activeRoomId.value}, messages=${activeMessages.length}, isLoading=${isLoadingMessages.value}, decision=ALREADY_LOADED (isSameRoom: $isSameRoom, hasActiveMessages: $hasActiveMessages)');
      activeRoomId.value = cleanRoomId;
      if (targetConv != null && activeConversation.value != targetConv) {
        activeConversation.value = targetConv;
      }
      return activeConversation.value;
    }

    debugPrint('[CHAT-LOAD] roomId=$cleanRoomId, activeRoomId=${activeRoomId.value}, messages=${activeMessages.length}, isLoading=${isLoadingMessages.value}, decision=NEEDS_LOAD (isSameRoom: $isSameRoom, hasActiveMessages: $hasActiveMessages, isLoading: ${isLoadingMessages.value})');

    // 3. Set active room and provisional state immediately
    final requestId = ++_messageLoadSequence;
    activeRoomId.value = cleanRoomId;

    if (targetConv != null) {
      activeConversation.value = targetConv;
      targetConv.unreadCount = 0;
      safeRefreshConversations();
    } else if (activeConversation.value == null ||
        activeConversation.value!.id != cleanRoomId) {
      activeConversation.value = ChatConversationModel(
        id: cleanRoomId,
        name: 'Chat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: '',
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );
    }

    // Clear stale messages when opening / switching / reloading
    debugPrint('[CHAT-STATE] activeMessages.clear() reason = ensureConversationLoaded (switching/reloading), roomId = $cleanRoomId, activeRoomId = ${activeRoomId.value}, sequence = $requestId');
    activeMessages.clear();
    replyingToMessage.value = null;
    pinnedMessage.value = activeConversation.value?.pinnedMessage;
    isLoadingMessages.value = true;

    // Mark as read on backend asynchronously and refresh unread count
    repository.markConversationRead(cleanRoomId).then((_) {
      fetchUnreadCount();
    }).catchError((_) {});

    // 4. Fetch messages directly for this room with race protection
    debugPrint('[CHAT-API] GET messages roomId = $cleanRoomId, requestSequence = $requestId');
    try {
      final msgs = await repository.getMessages(cleanRoomId);
      debugPrint('[CHAT-API] response roomId = $cleanRoomId, messageCount = ${msgs.length}, requestSequence = $requestId, currentSequence = $_messageLoadSequence, activeRoomId = ${activeRoomId.value}');
      if (activeRoomId.value == cleanRoomId && _messageLoadSequence == requestId) {
        debugPrint('[CHAT-API] APPLIED roomId = $cleanRoomId, count = ${msgs.length}');
        debugPrint('[CHAT-STATE] activeMessages.assignAll() roomId = $cleanRoomId, count = ${msgs.length}');
        activeMessages.assignAll(msgs);
        final pinned = msgs.firstWhereOrNull((m) => m.isPinned);
        if (pinned != null) {
          pinnedMessage.value = pinned;
        }
        _scrollToBottom();
      } else {
        debugPrint('[CHAT-API] DISCARDED roomId = $cleanRoomId, reason = ${activeRoomId.value != cleanRoomId ? "activeRoomId changed (expected $cleanRoomId but was ${activeRoomId.value})" : "sequence mismatch (requestId $requestId != $_messageLoadSequence)"}');
      }
    } catch (e) {
      debugPrint('[CHAT-API] ERROR roomId = $cleanRoomId, error = $e');
    } finally {
      if (activeRoomId.value == cleanRoomId) {
        isLoadingMessages.value = false;
      }
    }

    // 5. If metadata was provisional or needs enrichment, fetch room in parallel
    if (activeConversation.value == null ||
        activeConversation.value!.name == 'Chat' ||
        !conversations.any((c) => c.id == cleanRoomId)) {
      try {
        final room = await repository.getRoom(cleanRoomId);
        if (activeRoomId.value == cleanRoomId && _messageLoadSequence == requestId) {
          final enriched =
              room.id.isEmpty ? room.copyWith(id: cleanRoomId) : room;
          activeConversation.value = enriched;
          final idx = conversations.indexWhere((c) => c.id == cleanRoomId);
          if (idx != -1) {
            conversations[idx] = enriched;
          } else {
            conversations.insert(0, enriched);
          }
          safeRefreshConversations();
        }
      } catch (_) {}
    }

    fetchUnreadCount();
    return activeConversation.value;
  }

  Future<ChatConversationModel?> openConversationById(String roomId) async {
    return ensureConversationLoaded(roomId);
  }

  Future<void> openConversation(ChatConversationModel conv) async {
    await ensureConversationLoaded(conv.id, conversation: conv);
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
      debugPrint('[CHAT-API] openPrivateChat failed for userId=$userId: $e');
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Chat unavailable',
          'Could not start conversation. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return null;
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

    try {
      final newMsg = await repository.sendMessage(
        conv.id,
        text.isEmpty
            ? (type == 'image' ? '📷 Photo' : 'Shared attachment')
            : text,
        messageType: type,
        mediaUrl: mediaUrl,
        replyTo: effectiveReplyTo,
      );

      final currentRoom = activeRoomId.value ?? activeConversation.value?.id;
      if (currentRoom == conv.id &&
          !activeMessages.any((m) => m.id == newMsg.id)) {
        activeMessages.add(newMsg);
      }
      conv.lastMessage = newMsg.content;
      conv.lastMessageTime = 'Just now';
      conv.unreadCount = 0;
      _moveConversationToTop(conv);
      conversations.refresh();
      _scrollToBottom();
    } catch (e) {
      debugPrint('[CHAT-API] sendMessage failed for conv=${conv.id}: $e');
      textController.text = text;
      if (effectiveReplyTo != null) {
        replyingToMessage.value = ChatMessageModel(
          id: effectiveReplyTo.messageId,
          conversationId: conv.id,
          senderId: '',
          senderName: effectiveReplyTo.senderName,
          content: effectiveReplyTo.content,
          timestamp: DateTime.now(),
          timeAgo: '',
          isMine: false,
          messageType: effectiveReplyTo.messageType,
          mediaUrl: effectiveReplyTo.mediaUrl,
        );
      }
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Failed to send',
          'Unable to deliver your message. Please check your connection.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Sends text initiated outside the chat composer, such as a Community
  /// discussion share, using the backend's normal TEXT message contract.
  Future<void> sendSharedText(
    ChatConversationModel conv,
    String content,
  ) async {
    final text = content.trim();
    if (text.isEmpty) return;

    isSendingMessage.value = true;
    try {
      final newMsg = await repository.sendMessage(
        conv.id,
        text,
        messageType: 'text',
      );
      final currentRoom = activeRoomId.value ?? activeConversation.value?.id;
      if (currentRoom == conv.id &&
          !activeMessages.any((message) => message.id == newMsg.id)) {
        activeMessages.add(newMsg);
      }
      conv.lastMessage = newMsg.content;
      conv.lastMessageTime = 'Just now';
      conv.unreadCount = 0;
      _moveConversationToTop(conv);
      conversations.refresh();
      _scrollToBottom();
    } finally {
      isSendingMessage.value = false;
    }
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
      conversations.removeWhere((c) => c.id == conversationId);
      if (activeRoomId.value == conversationId ||
          activeConversation.value?.id == conversationId) {
        leaveConversation(roomId: conversationId);
      }
      conversations.refresh();
      return true;
    } catch (e) {
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Delete failed',
          'Could not delete conversation.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
  }

  Future<bool> archiveConversation(String conversationId) async {
    try {
      await repository.archiveConversation(conversationId);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        final updated = conversations[idx].copyWith(isArchived: true);
        conversations[idx] = updated;
        conversations.refresh();
      }
      return true;
    } catch (e) {
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Archive failed',
          'Could not archive conversation.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
  }

  Future<bool> unarchiveConversation(String conversationId) async {
    try {
      await repository.unarchiveConversation(conversationId);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        final updated = conversations[idx].copyWith(isArchived: false);
        conversations[idx] = updated;
        conversations.refresh();
      }
      return true;
    } catch (e) {
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Unarchive failed',
          'Could not unarchive conversation.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
  }

  Future<bool> muteConversation(String conversationId) async {
    try {
      await repository.muteConversation(conversationId);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        final current = conversations[idx];
        final updated = current.copyWith(isMuted: !current.isMuted);
        conversations[idx] = updated;
        conversations.refresh();
      }
      return true;
    } catch (e) {
      if (Get.context != null &&
          Get.isSnackbarOpen != true &&
          Get.key.currentState != null) {
        Get.snackbar(
          'Mute failed',
          'Could not update mute status.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
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

    // 2. Call Repository send message API
    final newMsg = await repository.sendMessage(
      conv.id,
      message,
      messageType: 'story_reply',
      mediaUrl: mediaUrl,
    );

    // 3. Update conversation metadata and place at top of list
    conv.lastMessage = message;
    conv.lastMessageTime = 'Just now';
    conv.unreadCount = 0;
    conversations.insert(0, conv);
    conversations.refresh();

    // 4. Set as active conversation and switch activeMessages cleanly without leaking prior conversation messages
    if (activeRoomId.value != conv.id) {
      activeRoomId.value = conv.id;
      activeConversation.value = conv;
      activeMessages.clear();
      replyingToMessage.value = null;
      pinnedMessage.value = conv.pinnedMessage;
      try {
        final existingMsgs = await repository.getMessages(conv.id);
        if (activeRoomId.value == conv.id) {
          activeMessages.assignAll(existingMsgs);
        }
      } catch (_) {
        if (activeRoomId.value == conv.id) {
          activeMessages.clear();
        }
      }
    }
    if (activeRoomId.value == conv.id &&
        !activeMessages.any((m) => m.id == newMsg.id)) {
      activeMessages.add(newMsg);
    }
    _scrollToBottom();

    return newMsg;
  }

  void onMessageReceived(ChatMessageModel message) {
    final activeId = activeRoomId.value ?? activeConversation.value?.id;
    final rawId = message.id;
    final isDuplicate = rawId.isNotEmpty &&
        (_recentReceivedMessageIds.contains(rawId) ||
            _recentReceivedMessageIds.contains('chat-msg:$rawId'));
    if (rawId.isNotEmpty) {
      if (_recentReceivedMessageIds.length > 200) {
        _recentReceivedMessageIds.remove(_recentReceivedMessageIds.first);
      }
      _recentReceivedMessageIds.add(rawId);
      _recentReceivedMessageIds.add('chat-msg:$rawId');
    }

    if (activeId != null && activeId == message.conversationId) {
      final exists = activeMessages.any((m) => m.id == message.id);
      if (!exists) {
        activeMessages.add(message);
        _scrollToBottom();
      }
      repository.markConversationRead(message.conversationId).catchError((_) => false);
    }

    final idx = conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx != -1) {
      final conv = conversations[idx];
      conv.lastMessage = message.content;
      conv.lastMessageTime = 'Just now';
      if (activeId != message.conversationId && !isDuplicate) {
        conv.unreadCount += 1;
        unreadCount.value += 1;
      }
      _moveConversationToTop(conv);
      safeRefreshConversations();
      final localCount =
          conversations.fold(0, (sum, item) => sum + item.unreadCount);
      if (localCount > unreadCount.value) {
        unreadCount.value = localCount;
      }
    } else if (activeId != message.conversationId && !isDuplicate) {
      // Incoming message for a conversation not yet in local conversations list
      unreadCount.value += 1;
      fetchUnreadCount();
      fetchConversations();
    }
  }

  /// Handles chat notification frames received on STOMP `/user/queue/notifications`.
  /// Ensures unread badges and previews increment in real time even when incoming via notification topic,
  /// with strict deduplication against `/user/queue/chat` frames so counts never double-increment.
  void onChatNotificationReceived(Map<String, dynamic> json) {
    final roomId = (json['referenceId'] ?? json['roomId'] ?? '').toString();
    final activeId = activeRoomId.value ?? activeConversation.value?.id;
    if (activeId != null && activeId.isNotEmpty && activeId == roomId) {
      return;
    }

    final dedupeKey =
        (json['dedupeKey'] ?? json['deliveryId'] ?? '').toString();
    String? rawMsgId;
    if (dedupeKey.contains(':')) {
      final parts = dedupeKey.split(':');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        rawMsgId = parts[1];
      }
    }

    final isDuplicate = (dedupeKey.isNotEmpty &&
            _recentReceivedMessageIds.contains(dedupeKey)) ||
        (rawMsgId != null && _recentReceivedMessageIds.contains(rawMsgId)) ||
        (rawMsgId != null &&
            _recentReceivedMessageIds.contains('chat-msg:$rawMsgId'));

    if (isDuplicate) {
      return;
    }

    if (dedupeKey.isNotEmpty) {
      if (_recentReceivedMessageIds.length > 200) {
        _recentReceivedMessageIds.remove(_recentReceivedMessageIds.first);
      }
      _recentReceivedMessageIds.add(dedupeKey);
    }
    if (rawMsgId != null && rawMsgId.isNotEmpty) {
      _recentReceivedMessageIds.add(rawMsgId);
      _recentReceivedMessageIds.add('chat-msg:$rawMsgId');
    }

    if (roomId.isNotEmpty) {
      final idx = conversations.indexWhere((c) => c.id == roomId);
      if (idx != -1) {
        final conv = conversations[idx];
        conv.unreadCount += 1;
        final preview = json['message']?.toString();
        if (preview != null && preview.isNotEmpty) {
          conv.lastMessage = preview;
          conv.lastMessageTime = 'Just now';
        }
        _moveConversationToTop(conv);
        safeRefreshConversations();
      }
    }

    unreadCount.value += 1;
    fetchUnreadCount();
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
