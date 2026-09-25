import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_list_item.dart';
import '../../chat_navigation.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatController = Get.find<ChatController>();

    final bgColor =
        isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: const AppBackButton(),
        title: Obx(() {
          final count =
              chatController.conversations.where((c) => c.isArchived).length;
          return Row(
            children: [
              Text(
                'Archived Chats',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Obx(() {
        final archived = chatController.conversations
            .where((c) => c.isArchived)
            .toList();

        if (archived.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightBgSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.archive_outlined,
                      size: 32,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Archived Chats',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conversations you archive will appear here so you can keep your main inbox focused.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: archived.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 1, color: borderColor),
          itemBuilder: (context, index) {
            final conv = archived[index];
            return ChatListItem(
              conversation: conv,
              onTap: () async {
                await chatController.openConversation(conv);
                if (!context.mounted) return;
                ChatNavigation.openChatDetail(conv.id, conversation: conv);
              },
              onUnarchive: () async {
                final ok =
                    await chatController.unarchiveConversation(conv.id);
                if (ok && context.mounted) {
                  AppNotificationBanner.showSuccess(
                    context: context,
                    title: 'Chat Unarchived',
                    message:
                        '"${conv.name}" has been moved back to your main chats.',
                    icon: Icons.unarchive_rounded,
                  );
                }
              },
              onMute: () async {
                await chatController.muteConversation(conv.id);
              },
              onDelete: () {
                _showDeleteDialog(context, chatController, conv.id, conv.name);
              },
            );
          },
        );
      }),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ChatController controller,
    String conversationId,
    String name,
  ) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'Delete Conversation',
      message:
          'Are you sure you want to permanently delete the conversation with "$name"? All message history will be cleared.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && context.mounted) {
      final ok = await controller.deleteConversation(conversationId);
      if (ok && context.mounted) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: 'Deleted',
          message: 'Conversation has been deleted.',
          icon: Icons.delete_outline_rounded,
        );
      }
    }
  }
}
