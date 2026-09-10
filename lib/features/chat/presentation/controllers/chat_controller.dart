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

  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  @override
  void onClose() {
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
      // Keep existing list on failure or notify user
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
    activeConversation.value = conv;
    conv.unreadCount = 0;
    conversations.refresh();
    repository.markConversationRead(conv.id);

    isLoadingMessages.value = true;
    try {
      final msgs = await repository.getMessages(conv.id);
      activeMessages.assignAll(msgs);
      _scrollToBottom();
    } catch (e) {
      activeMessages.clear();
      Get.snackbar(
        'Messages unavailable',
        'Could not load messages for this chat.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<ChatConversationModel?> openPrivateChat(
    String userId, {
    String? name,
    String? avatar,
  }) async {
    try {
      final conv = await repository.openPrivateChat(userId);
      final existingIdx = conversations.indexWhere((c) => c.id == conv.id);
      if (existingIdx != -1) {
        conversations[existingIdx] = conv;
      } else {
        conversations.insert(0, conv);
      }
      conversations.refresh();
      await openConversation(conv);
      return conv;
    } catch (e) {
      // Fallback local conversation placeholder if needed
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

  Future<void> sendMessage({String type = 'text', String? mediaUrl}) async {
    final text = textController.text.trim();
    if (text.isEmpty && mediaUrl == null) return;

    final conv = activeConversation.value;
    if (conv == null) return;

    textController.clear();
    isSendingMessage.value = true;

    try {
      final newMsg = await repository.sendMessage(
        conv.id,
        text.isEmpty
            ? (type == 'image' ? '📷 Photo' : 'Shared attachment')
            : text,
        messageType: type,
        mediaUrl: mediaUrl,
      );

      activeMessages.add(newMsg);
      conv.lastMessage = newMsg.content;
      conv.lastMessageTime = 'Just now';
      _moveConversationToTop(conv);
      conversations.refresh();
      _scrollToBottom();
    } catch (e) {
      Get.snackbar(
        'Send failed',
        'Your message was not sent. Try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  Future<ChatMessageModel> sendStoryReply({
    required String userName,
    required String userAvatar,
    required String message,
    String? mediaUrl,
  }) async {
    // 1. Find existing conversation or create a new one
    var convIndex = conversations.indexWhere((c) => c.name == userName);
    ChatConversationModel conv;

    if (convIndex != -1) {
      conv = conversations.removeAt(convIndex);
    } else {
      conv = ChatConversationModel(
        id: 'conv_story_${userName}_${DateTime.now().millisecondsSinceEpoch}',
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
    ChatMessageModel newMsg;
    try {
      newMsg = await repository.sendMessage(
        conv.id,
        message,
        messageType: 'story_reply',
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      Get.snackbar(
        'Reply failed',
        'Could not send your story reply.',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }

    // Update conversation metadata
    conv.lastMessage = message;
    conv.lastMessageTime = 'Just now';

    // Move to top of conversations list (Index 0)
    conversations.insert(0, conv);
    conversations.refresh();

    // If active conversation matches, append message
    if (activeConversation.value?.id == conv.id) {
      activeMessages.add(newMsg);
      _scrollToBottom();
    }

    return newMsg;
  }

  /// Realtime inbound message handler for WebSocket / Push / STOMP
  void onMessageReceived(ChatMessageModel message) {
    // 1. If currently viewing this conversation, append message and mark as read
    if (activeConversation.value?.id == message.conversationId) {
      final exists = activeMessages.any((m) => m.id == message.id);
      if (!exists) {
        activeMessages.add(message);
        _scrollToBottom();
      }
      repository.markConversationRead(message.conversationId);
    }

    // 2. Update conversation list entry
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
