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
      conversations.clear();
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
