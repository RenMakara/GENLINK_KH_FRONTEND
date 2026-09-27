import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/typography/app_typography.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../community/presentation/controllers/story_controller.dart';
import '../../../community/presentation/screens/story_viewer_screen.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';
import '../../domain/models/chat_models.dart';
import '../bindings/chat_binding.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_attachment_sheet.dart';
import '../widgets/chat_content_picker_sheet.dart';
import '../widgets/chat_system_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import 'group_profile_screen.dart';

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;
  static const double _scaleFactor = 0.94;
  static const Duration _duration = Duration(milliseconds: 140);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? _scaleFactor : 1.0,
        duration: _duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, this.roomId});

  final String? roomId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  bool _isSearching = false;
  final TextEditingController _inChatSearchController = TextEditingController();
  String _inChatSearchQuery = '';
  String? _screenRoomId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final roomId = (widget.roomId ?? (args is Map ? args['roomId'] : args))?.toString().trim();
    if (roomId != null && roomId.isNotEmpty) {
      _screenRoomId = roomId;
    }
    final c = Get.isRegistered<ChatController>() ? Get.find<ChatController>() : null;
    debugPrint('[CHAT-DETAIL] initState roomId = ${widget.roomId}, screenRoomId = $_screenRoomId, controller = ${c != null ? identityHashCode(c) : "not registered"}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initFromArguments();
      }
    });
  }

  @override
  void didUpdateWidget(ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = Get.isRegistered<ChatController>() ? Get.find<ChatController>() : null;
    debugPrint('[CHAT-DETAIL] didUpdateWidget roomId = ${widget.roomId} (old: ${oldWidget.roomId}), controller = ${c != null ? identityHashCode(c) : "not registered"}');
    if (widget.roomId != oldWidget.roomId && widget.roomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initFromArguments();
        }
      });
    }
  }

  void _initFromArguments() {
    if (!mounted) return;
    final args = Get.arguments;
    final roomId = (widget.roomId ?? (args is Map ? args['roomId'] : args))?.toString().trim();
    if (!Get.isRegistered<ChatController>()) {
      ChatBinding().dependencies();
    }
    final controller = Get.find<ChatController>();
    debugPrint('[CHAT-DETAIL] _initFromArguments roomId = $roomId, screenRoomId = $_screenRoomId, controller = ${identityHashCode(controller)}, activeRoomId = ${controller.activeRoomId.value}');
    if (roomId != null && roomId.isNotEmpty) {
      _screenRoomId = roomId;
      controller.ensureConversationLoaded(roomId);
    } else {
      final fallbackRoomId =
          controller.activeRoomId.value ?? controller.activeConversation.value?.id;
      if (fallbackRoomId != null && fallbackRoomId.isNotEmpty) {
        _screenRoomId = fallbackRoomId;
        controller.ensureConversationLoaded(fallbackRoomId);
      }
    }
  }


  @override
  void dispose() {
    final c = Get.isRegistered<ChatController>() ? Get.find<ChatController>() : null;
    debugPrint('[CHAT-DETAIL] dispose roomId = $_screenRoomId, controller = ${c != null ? identityHashCode(c) : "not registered"}');
    _inChatSearchController.dispose();
    if (Get.isRegistered<ChatController>()) {
      final controller = Get.find<ChatController>();
      controller.leaveConversation(roomId: _screenRoomId);
    }
    super.dispose();
  }

  void _onHeaderTap(ChatConversationModel conv) {
    if (conv.isGroup) {
      Get.to(() => GroupProfileScreen(conversation: conv));
    } else if (conv.isEventChat) {
      AppNotificationBanner.showInfo(
        context: context,
        title: 'Event Details',
        message: 'Viewing details for ${conv.name}...',
        icon: Icons.event_rounded,
      );
    } else {
      ProfileNavigation.open(
        username: conv.profileUsername,
        userId: conv.profileUserId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Obx(() {
      final conv = chatController.activeConversation.value;
      if (conv == null) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            elevation: 0,
            leading: Center(
              child: AppBackButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Get.back<void>();
                  } else {
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
              ),
            ),
            title: Text(
              'chat.title'.tr.isNotEmpty && 'chat.title'.tr != 'chat.title'
                  ? 'chat.title'.tr
                  : 'Chat',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.chatPrimary),
          ),
        );
      }

      final statusText = conv.isGroup
          ? ('chat.members'.tr.isNotEmpty && 'chat.members'.tr != 'chat.members'
              ? 'chat.members'.trParams({'count': '${conv.membersCount}'})
              : '${conv.membersCount} members')
          : (conv.isOnline
              ? ('chat.online'.tr.isNotEmpty && 'chat.online'.tr != 'chat.online'
                  ? 'chat.online'.tr
                  : 'Online')
              : ('chat.offline'.tr.isNotEmpty && 'chat.offline'.tr != 'chat.offline'
                  ? 'chat.offline'.tr
                  : 'Offline'));

      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: surfaceColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(
              color: borderColor.withValues(alpha: 0.6),
              height: 0.5,
            ),
          ),
          leading: Center(
            child: _PressableScale(
              onTap: () => Get.back(),
              child: AppBackButton(onPressed: () => Get.back()),
            ),
          ),
          leadingWidth: 56,
          titleSpacing: 0,
          title: InkWell(
            onTap: () => _onHeaderTap(conv),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  ChatAvatar(
                    avatarUrl: conv.avatar,
                    name: conv.name,
                    radius: 21,
                    isOnline: conv.isOnline,
                    isEventChat: conv.isEventChat,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTypography.englishFontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: conv.isOnline ? AppColors.success : textMuted,
                            fontSize: 12.5,
                            fontWeight: conv.isOnline ? FontWeight.w500 : FontWeight.normal,
                            fontFamily: AppTypography.englishFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            _PressableScale(
              child: IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: textPrimary,
                  size: 22,
                ),
                tooltip: 'chat.search'.tr.isNotEmpty && 'chat.search'.tr != 'chat.search'
                    ? 'chat.search'.tr
                    : 'Search in Chat',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _inChatSearchController.clear();
                      _inChatSearchQuery = '';
                    }
                  });
                },
              ),
            ),

            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: textPrimary, size: 21),
                color: surfaceColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor.withValues(alpha: 0.7), width: 0.8),
                ),
                onSelected: (val) {
                if (val == 'info') {
                  _onHeaderTap(conv);
                } else if (val == 'mute') {
                  chatController.muteConversation(conv.id);
                  AppNotificationBanner.showSuccess(
                    context: context,
                    title: 'Notifications',
                    message: conv.isMuted
                        ? 'Notifications unmuted.'
                        : 'Notifications muted.',
                    icon: Icons.notifications_off_rounded,
                  );
                } else if (val == 'archive') {
                  if (conv.isArchived) {
                    chatController.unarchiveConversation(conv.id);
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: 'Unarchived',
                      message: 'Conversation unarchived.',
                      icon: Icons.unarchive_rounded,
                    );
                  } else {
                    chatController.archiveConversation(conv.id);
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: 'Archived',
                      message: 'Conversation archived.',
                      icon: Icons.archive_rounded,
                    );
                  }
                } else if (val == 'clear') {
                  AppNotificationBanner.showInfo(
                    context: context,
                    title: 'Clear History',
                    message: 'Chat history cleared.',
                    icon: Icons.delete_sweep_rounded,
                  );
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.chatPrimary),
                      const SizedBox(width: 8),
                      Text(
                        conv.isGroup
                            ? ('chat.groupInfo'.tr.isNotEmpty && 'chat.groupInfo'.tr != 'chat.groupInfo'
                                ? 'chat.groupInfo'.tr
                                : 'Group Info')
                            : ('chat.viewProfile'.tr.isNotEmpty && 'chat.viewProfile'.tr != 'chat.viewProfile'
                                ? 'chat.viewProfile'.tr
                                : 'View Profile'),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 18, color: AppColors.chatPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'chat.muteChat'.tr.isNotEmpty && 'chat.muteChat'.tr != 'chat.muteChat'
                            ? 'chat.muteChat'.tr
                            : 'Mute',
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        conv.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        size: 18,
                        color: AppColors.chatPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conv.isArchived ? 'Unarchive Chat' : 'Archive Chat',
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text(
                        'chat.clearHistory'.tr.isNotEmpty && 'chat.clearHistory'.tr != 'chat.clearHistory'
                            ? 'chat.clearHistory'.tr
                            : 'Clear History',
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                if (_isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: surfaceColor,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _inChatSearchController,
                        autofocus: true,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        onChanged: (val) {
                          setState(() {
                            _inChatSearchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: textMuted),
                          hintText: 'Search in conversation...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          suffixIcon: _inChatSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, size: 16, color: textMuted),
                                  onPressed: () {
                                    _inChatSearchController.clear();
                                    setState(() {
                                      _inChatSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                if (conv.isEventChat)
                  GestureDetector(
                    onTap: () => _onHeaderTap(conv),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.chatPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.chatPrimary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_note_rounded,
                            color: AppColors.chatPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              conv.name,
                              style: const TextStyle(
                                color: AppColors.chatPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.chatPrimary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                Obx(() {
                  final pinned = chatController.pinnedMessage.value;
                  if (pinned == null) return const SizedBox.shrink();
                  return _buildPinnedMessageBanner(context, pinned, chatController);
                }),

                Expanded(
                  child: Obx(() {
                    final activeId = chatController.activeRoomId.value ??
                        chatController.activeConversation.value?.id;
                    final isRoomMismatch = activeId != null &&
                        activeId.isNotEmpty &&
                        conv.id.isNotEmpty &&
                        activeId != conv.id &&
                        activeId != 'private_${conv.id}' &&
                        'private_$activeId' != conv.id;
                    if (chatController.isLoadingMessages.value || isRoomMismatch) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.chatPrimary,
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    final msgs = chatController.activeMessages
                        .where((m) =>
                            m.conversationId == conv.id ||
                            (activeId != null && m.conversationId == activeId) ||
                            'private_${m.conversationId}' == conv.id ||
                            m.conversationId == 'private_${conv.id}')
                        .toList();
                    final displayMsgs = _inChatSearchQuery.isEmpty
                        ? msgs
                        : msgs.where((m) => m.content.toLowerCase().contains(_inChatSearchQuery)).toList();

                    if (displayMsgs.isEmpty) {
                      if (_inChatSearchQuery.isNotEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'chat.noMessagesFound'.tr.isNotEmpty && 'chat.noMessagesFound'.tr != 'chat.noMessagesFound'
                                    ? 'chat.noMessagesFound'.tr
                                    : 'No messages found',
                                style: TextStyle(color: textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChatAvatar(
                                avatarUrl: conv.avatar,
                                name: conv.name,
                                radius: 36,
                                isEventChat: conv.isEventChat,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                conv.name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'chat.startConversation'.tr.isNotEmpty && 'chat.startConversation'.tr != 'chat.startConversation'
                                    ? 'chat.startConversation'.tr
                                    : 'Start a conversation...',
                                style: TextStyle(color: textMuted, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ActionChip(
                                avatar: const Text('👋', style: TextStyle(fontSize: 14)),
                                label: Text(
                                  'Say Hello',
                                  style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: surfaceColor,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onPressed: () {
                                  chatController.textController.text = 'Hello! 👋';
                                  chatController.sendMessage();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: chatController.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: displayMsgs.length,
                      itemBuilder: (context, index) {
                        final msg = displayMsgs[index];

                        if (msg.isSystemMessage) {
                          return ChatSystemMessage(text: msg.content);
                        }

                        bool showAvatar = true;
                        bool showSenderName = conv.isGroup;

                        if (index > 0) {
                          final prevMsg = displayMsgs[index - 1];
                          if (!prevMsg.isSystemMessage &&
                              prevMsg.senderId == msg.senderId &&
                              msg.timestamp.difference(prevMsg.timestamp).inMinutes < 4) {
                            showAvatar = false;
                            showSenderName = false;
                          }
                        }

                        final showDateSeparator = index == 0 || !_isSameDay(displayMsgs[index - 1].timestamp, msg.timestamp);

                        final bubble = MessageBubble(
                          message: msg,
                          isGroupChat: conv.isGroup,
                          showAvatar: showAvatar,
                          showSenderName: showSenderName,
                          onAvatarTap: () => _onHeaderTap(conv),
                          onFinanceTap: () {
                            AppNotificationBanner.showSuccess(
                              context: context,
                              title: "GenLink Finance",
                              message: "Viewing transaction details...",
                              icon: Icons.account_balance_wallet_rounded,
                            );
                          },
                          onStoryTap: () {
                            final storyId = msg.storyReference?.storyId;
                            if (storyId != null &&
                                storyId.isNotEmpty &&
                                Get.isRegistered<StoryController>()) {
                              final storyCtrl = Get.find<StoryController>();
                              for (int g = 0;
                                  g < storyCtrl.storyGroups.length;
                                  g++) {
                                final sIdx = storyCtrl.storyGroups[g].stories
                                    .indexWhere((s) => s.id == storyId);
                                if (sIdx != -1) {
                                  Get.to<void>(
                                    () => StoryViewerScreen(
                                      initialGroupIndex: g,
                                      groups: storyCtrl.storyGroups,
                                      initialStoryIndex: sIdx,
                                    ),
                                  );
                                  return;
                                }
                              }
                            }
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Story Preview",
                              message: "Story preview unavailable or expired.",
                              icon: Icons.auto_awesome,
                            );
                          },
                          onReplyTap: (replyId) => _scrollToMessage(replyId, displayMsgs, chatController),
                          onReactionTap: (emoji) => chatController.toggleReaction(msg.id, emoji),
                          onLongPress: () => _showMessageActionSheet(context, msg, chatController),
                          onDeleteTap: (msgId) => _showDeleteMessageDialog(context, msg, chatController),
                        );

                        if (showDateSeparator) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDateSeparator(msg.timestamp, context),
                              bubble,
                            ],
                          );
                        }
                        return bubble;
                      },
                    );
                  }),
                ),

                Obx(() {
                  final typingUser = chatController.typingUserName.value;
                  if (typingUser == null || typingUser.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.chatPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'chat.isTyping'.tr.isNotEmpty && 'chat.isTyping'.tr != 'chat.isTyping'
                              ? 'chat.isTyping'.trParams({'name': typingUser})
                              : '$typingUser is typing...',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                Obx(() => MessageComposer(
                      controller: chatController.textController,
                      isSending: chatController.isSendingMessage.value,
                      replyingTo: chatController.replyingToMessage.value,
                      onCancelReply: () => chatController.cancelReply(),
                      onSend: () => chatController.sendMessage(),
                      onAttachmentTap: () => _openAttachmentSheet(context, chatController),
                    )),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _openAttachmentSheet(BuildContext context, ChatController controller) {
    ChatAttachmentSheet.show(
      context,
      onCameraTap: () => _pickAndSendImage(controller, ImageSource.camera),
      onGalleryTap: () => _pickAndSendImage(controller, ImageSource.gallery),
      onFileTap: () => _sendSimulatedAttachment(controller, 'file', 'Document attachment'),
      onLocationTap: () => _sendSimulatedAttachment(controller, 'text', '📍 Shared location: Phnom Penh, Cambodia'),
      onSharePostTap: () {
        ChatContentPickerSheet.show(
          context,
          type: SharedContentType.post,
          onSelected: (content) => controller.sendMessage(sharedContent: content),
        );
      },
      onShareEventTap: () {
        ChatContentPickerSheet.show(
          context,
          type: SharedContentType.event,
          onSelected: (content) => controller.sendMessage(sharedContent: content),
        );
      },
      onShareDiscussionTap: () {
        ChatContentPickerSheet.show(
          context,
          type: SharedContentType.discussion,
          onSelected: (content) => controller.sendMessage(sharedContent: content),
        );
      },
      onShareProfileTap: () {
        ChatContentPickerSheet.show(
          context,
          type: SharedContentType.profile,
          onSelected: (content) => controller.sendMessage(sharedContent: content),
        );
      },
    );
  }

  Future<void> _pickAndSendImage(ChatController controller, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) {
        String mediaUrl = file.path;
        if (Get.isRegistered<MediaUploadService>()) {
          final uploadService = Get.find<MediaUploadService>();
          try {
            final bytes = await file.readAsBytes();
            final uploaded = await uploadService.upload(
              bytes: bytes,
              contentType: 'image/jpeg',
              purpose: MediaPurpose.post,
            );
            if (uploaded.url.isNotEmpty) {
              mediaUrl = uploaded.url;
            }
          } catch (_) {
          }
        }
        await controller.sendMessage(
          type: 'image',
          mediaUrl: mediaUrl,
        );
      }
    } catch (_) {}
  }

  Future<void> _sendSimulatedAttachment(
    ChatController controller,
    String type,
    String text,
  ) async {
    controller.textController.text = text;
    await controller.sendMessage(type: type);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime timestamp, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String label;
    if (_isSameDay(timestamp, now)) {
      label = 'chat.today'.tr.isNotEmpty && 'chat.today'.tr != 'chat.today'
          ? 'chat.today'.tr
          : 'Today';
    } else if (_isSameDay(timestamp, yesterday)) {
      label = 'chat.yesterday'.tr.isNotEmpty && 'chat.yesterday'.tr != 'chat.yesterday'
          ? 'chat.yesterday'.tr
          : 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      label = '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.5),
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            fontFamily: AppTypography.englishFontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedMessageBanner(
    BuildContext context,
    ChatMessageModel pinned,
    ChatController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _scrollToMessage(pinned.id, controller.activeMessages, controller),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.push_pin_rounded,
                  color: AppColors.chatPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'chat.pinnedMessage'.tr.isNotEmpty && 'chat.pinnedMessage'.tr != 'chat.pinnedMessage'
                            ? 'chat.pinnedMessage'.tr
                            : 'Pinned Message',
                        style: const TextStyle(
                          color: AppColors.chatPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pinned.senderName}: ${pinned.content.isNotEmpty ? pinned.content : pinned.messageType}',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: () => controller.unpinMessage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToMessage(String messageId, List<ChatMessageModel> msgs, ChatController controller) {
    final index = msgs.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      AppNotificationBanner.showInfo(
        context: context,
        title: 'Message',
        message: 'Referenced message not found in this thread.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (!controller.scrollController.hasClients) return;
    final maxScroll = controller.scrollController.position.maxScrollExtent;
    final targetOffset = (index / msgs.length) * maxScroll;
    controller.scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showMessageActionSheet(BuildContext context, ChatMessageModel msg, ChatController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    Get.bottomSheet(
      Material(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 16,
            right: 16,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick reaction picker row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickReactions.map((emoji) {
                  final isSelected = msg.reactions.any((r) => r.emoji == emoji && r.hasReacted);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Get.back();
                      controller.toggleReaction(msg.id, emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.chatPrimary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Action list items
            ListTile(
              dense: true,
              leading: const Icon(Icons.reply_rounded, color: AppColors.chatPrimary, size: 20),
              title: Text(
                'chat.reply'.tr.isNotEmpty && 'chat.reply'.tr != 'chat.reply'
                    ? 'chat.reply'.tr
                    : 'Reply',
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                controller.setReplyingTo(msg);
              },
            ),
            if (msg.content.isNotEmpty)
              ListTile(
                dense: true,
                leading: Icon(Icons.copy_rounded, color: textMuted, size: 20),
                title: Text(
                  'chat.copy'.tr.isNotEmpty && 'chat.copy'.tr != 'chat.copy'
                      ? 'chat.copy'.tr
                      : 'Copy',
                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  Clipboard.setData(ClipboardData(text: msg.content));
                  AppNotificationBanner.showSuccess(
                    context: context,
                    title: 'Copied',
                    message: 'chat.copied'.tr.isNotEmpty && 'chat.copied'.tr != 'chat.copied'
                        ? 'chat.copied'.tr
                        : 'Message copied to clipboard',
                    icon: Icons.check_rounded,
                  );
                },
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.push_pin_rounded, color: AppColors.chatPrimary, size: 20),
              title: Text(
                msg.isPinned
                    ? ('chat.unpin'.tr.isNotEmpty && 'chat.unpin'.tr != 'chat.unpin' ? 'chat.unpin'.tr : 'Unpin')
                    : ('chat.pin'.tr.isNotEmpty && 'chat.pin'.tr != 'chat.pin' ? 'chat.pin'.tr : 'Pin'),
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                controller.togglePinMessage(msg);
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.forward_rounded, color: textMuted, size: 20),
              title: Text(
                'chat.forward'.tr.isNotEmpty && 'chat.forward'.tr != 'chat.forward'
                    ? 'chat.forward'.tr
                    : 'Forward',
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                AppNotificationBanner.showInfo(
                  context: context,
                  title: 'Forward',
                  message: 'Forwarding message...',
                  icon: Icons.forward_rounded,
                );
              },
            ),
            if (msg.isMine)
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                title: Text(
                  'chat.deleteMessage'.tr.isNotEmpty && 'chat.deleteMessage'.tr != 'chat.deleteMessage'
                      ? 'chat.deleteMessage'.tr
                      : 'Delete',
                  style: const TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteMessageDialog(context, msg, controller);
                },
              )
            else
              ListTile(
                dense: true,
                leading: const Icon(Icons.flag_outlined, color: AppColors.danger, size: 20),
                title: Text(
                  'chat.report'.tr.isNotEmpty && 'chat.report'.tr != 'chat.report'
                      ? 'chat.report'.tr
                      : 'Report',
                  style: const TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  AppNotificationBanner.showSuccess(
                    context: context,
                    title: 'Report',
                    message: 'chat.reportSubmitted'.tr.isNotEmpty && 'chat.reportSubmitted'.tr != 'chat.reportSubmitted'
                        ? 'chat.reportSubmitted'.tr
                        : 'Thank you for reporting. Our team will review this.',
                    icon: Icons.flag_rounded,
                  );
                },
              ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
  }

  Future<void> _showDeleteMessageDialog(BuildContext context, ChatMessageModel msg, ChatController controller) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'chat.deleteMessageTitle'.tr.isNotEmpty && 'chat.deleteMessageTitle'.tr != 'chat.deleteMessageTitle'
          ? 'chat.deleteMessageTitle'.tr
          : 'Delete message?',
      message: 'chat.deleteMessagePrompt'.tr.isNotEmpty && 'chat.deleteMessagePrompt'.tr != 'chat.deleteMessagePrompt'
          ? 'chat.deleteMessagePrompt'.tr
          : 'Are you sure you want to delete this message?',
      confirmLabel: 'chat.deleteMessage'.tr.isNotEmpty && 'chat.deleteMessage'.tr != 'chat.deleteMessage'
          ? 'chat.deleteMessage'.tr
          : 'Delete',
      cancelLabel: 'common.cancel'.tr.isNotEmpty && 'common.cancel'.tr != 'common.cancel'
          ? 'common.cancel'.tr
          : 'Cancel',
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && context.mounted) {
      controller.deleteMessage(msg.id);
      AppNotificationBanner.showInfo(
        context: context,
        title: 'Deleted',
        message: 'chat.messageDeleted'.tr.isNotEmpty && 'chat.messageDeleted'.tr != 'chat.messageDeleted'
            ? 'chat.messageDeleted'.tr
            : 'This message was deleted',
        icon: Icons.delete_outline_rounded,
      );
    }
  }
}
