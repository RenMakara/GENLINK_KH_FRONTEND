import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/chat_models.dart';
import '../controllers/chat_controller.dart';

class ChatDetailScreen extends GetView<ChatController> {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Obx(() {
      final conv = chatController.activeConversation.value;
      if (conv == null) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.communityAccent),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurfacePrimary,
          elevation: 1,
          leading: const Center(child: AppBackButton()),
          leadingWidth: 72,
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: conv.avatar.startsWith('http')
                    ? NetworkImage(conv.avatar) as ImageProvider
                    : AssetImage(conv.avatar),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      conv.isGroup
                          ? "${conv.membersCount} members"
                          : (conv.isOnline ? "Online" : "Offline"),
                      style: TextStyle(
                        color: conv.isOnline
                            ? AppColors.success
                            : AppColors.darkTextMuted,
                        fontSize: 11,
                        fontWeight: conv.isOnline
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.videocam_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                Get.snackbar(
                  "Video Call",
                  "Calling ${conv.name}...",
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: AppColors.darkSurfaceSecondary,
                  colorText: Colors.white,
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.call_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                Get.snackbar(
                  "Voice Call",
                  "Dialing ${conv.name}...",
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: AppColors.darkSurfaceSecondary,
                  colorText: Colors.white,
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                // Messages List
                Expanded(
                  child: Obx(() {
                    if (chatController.isLoadingMessages.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.communityAccent,
                        ),
                      );
                    }

                    final msgs = chatController.activeMessages;

                    return ListView.builder(
                      controller: chatController.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final msg = msgs[index];
                        return _buildMessageBubble(context, msg);
                      },
                    );
                  }),
                ),

                // Message Input Toolbar
                _buildMessageInputBar(context, chatController),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessageModel msg) {
    final isMine = msg.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: msg.senderAvatar != null
                  ? (msg.senderAvatar!.startsWith('http')
                        ? NetworkImage(msg.senderAvatar!) as ImageProvider
                        : AssetImage(msg.senderAvatar!))
                  : const AssetImage('assets/images/user_profile.png'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.communityAccent
                    : AppColors.darkSurfaceSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: Border.all(
                  color: isMine
                      ? AppColors.communityAccent
                      : AppColors.darkBorderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: const TextStyle(
                          color: AppColors.communityAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // ── Story Reply Preview Card inside DM Bubble ──
                  if (msg.messageType == 'story_reply') ...[
                    GestureDetector(
                      onTap: () {
                        AppNotificationBanner.showSuccess(
                          context: context,
                          title: "Story Preview",
                          message: "Reopening story...",
                          icon: Icons.auto_awesome,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMine ? Colors.black26 : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(6),
                                image:
                                    (msg.mediaUrl != null &&
                                        msg.mediaUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(msg.mediaUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  (msg.mediaUrl == null ||
                                      msg.mediaUrl!.isEmpty)
                                  ? const Center(
                                      child: Text(
                                        "Aa",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "↩ Replied to Story",
                                  style: TextStyle(
                                    color: isMine
                                        ? Colors.black87
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  "Tap to view story",
                                  style: TextStyle(
                                    color: isMine
                                        ? Colors.black54
                                        : Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMine ? Colors.black : Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.timeAgo,
                    style: TextStyle(
                      color: isMine ? Colors.black54 : AppColors.darkTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar(
    BuildContext context,
    ChatController controller,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurfacePrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.communityAccent,
            ),
            onPressed: () {
              Get.snackbar(
                "Attachment",
                "Select image or file from library.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.darkSurfaceSecondary,
                colorText: Colors.white,
              );
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller.textController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.darkSurfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => controller.sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.communityAccent,
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.black,
                size: 18,
              ),
              onPressed: () => controller.sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
