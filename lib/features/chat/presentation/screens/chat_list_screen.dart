import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/chat_models.dart';
import '../controllers/chat_controller.dart';
import '../bindings/chat_binding.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends GetView<ChatController> {
  const ChatListScreen({super.key});

  ChatController get _effectiveController {
    if (!Get.isRegistered<ChatController>()) {
      ChatBinding().dependencies();
    }
    return Get.find<ChatController>();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = _effectiveController;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Center(
          child: AppBackButton(onPressed: () => Get.back()),
        ),
        leadingWidth: 72,
        title: const Text(
          "Messages & Chats",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.communityAccent,
              size: 26,
            ),
            onPressed: () {
              Get.snackbar(
                "New Message",
                "Select a classmate or community group to start chatting.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.darkSurfaceSecondary,
                colorText: Colors.white,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Online Friends Horizontal Scroll Row
              _buildOnlineRow(),

              const SizedBox(height: 12),

              // Conversation List
              Expanded(
                child: Obx(() {
                  if (chatController.isLoadingConversations.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.communityAccent,
                      ),
                    );
                  }

                  if (chatController.conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 56,
                            color: AppColors.darkTextMuted.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No messages yet",
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Connect with student peers and join group discussions.",
                            style: TextStyle(
                              color: AppColors.darkTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => chatController.fetchConversations(),
                    color: AppColors.communityAccent,
                    backgroundColor: AppColors.darkSurfaceSecondary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: chatController.conversations.length,
                      itemBuilder: (context, index) {
                        final conv = chatController.conversations[index];
                        return _buildConversationCard(
                          context,
                          conv,
                          chatController,
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineRow() {
    final onlineList = [
      {
        'name': 'Sokuntheara',
        'avatar': 'assets/images/sokuntheara_profile.png',
      },
      {'name': 'Sum Sambo', 'avatar': 'assets/images/sum_sambo_profile.png'},
      {'name': 'Chansela', 'avatar': 'assets/images/heng_chansela_profile.png'},
      {'name': 'Ren Makara', 'avatar': 'assets/images/ren_makara_profile.png'},
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: onlineList.length,
        itemBuilder: (context, index) {
          final friend = onlineList[index];
          return Container(
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(friend['avatar']!),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  friend['name']!,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    ChatConversationModel conv,
    ChatController controller,
  ) {
    return InkWell(
      onTap: () {
        controller.openConversation(conv);
        Get.to(() => const ChatDetailScreen());
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkBorderSubtle),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: conv.avatar.startsWith('http')
                      ? NetworkImage(conv.avatar) as ImageProvider
                      : AssetImage(conv.avatar),
                ),
                if (conv.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conv.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conv.isGroup) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.communityAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "GROUP",
                                  style: TextStyle(
                                    color: AppColors.communityAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        conv.lastMessageTime,
                        style: const TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          style: TextStyle(
                            color: conv.unreadCount > 0
                                ? Colors.white
                                : AppColors.darkTextSecondary,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.communityAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${conv.unreadCount}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
