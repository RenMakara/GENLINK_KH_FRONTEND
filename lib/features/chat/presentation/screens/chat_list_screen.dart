import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/chat_models.dart';
import '../controllers/chat_controller.dart';
import '../bindings/chat_binding.dart';
import 'create_group_screen.dart';
import 'archived_chats_screen.dart';
import '../widgets/chat_list_item.dart';
import '../../chat_navigation.dart';


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  ChatController get _effectiveController {
    if (!Get.isRegistered<ChatController>()) {
      ChatBinding().dependencies();
    }
    return Get.find<ChatController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = _effectiveController;
    debugPrint('[CHAT-LIST] build controller = ${identityHashCode(chatController)}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final titleText =
        ('chat.title'.tr.isNotEmpty && 'chat.title'.tr != 'chat.title')
            ? 'chat.title'.tr
            : 'Messages & Chats';

    final searchPlaceholder = ('chat.searchPlaceholder'.tr.isNotEmpty &&
            'chat.searchPlaceholder'.tr != 'chat.searchPlaceholder')
        ? 'chat.searchPlaceholder'.tr
        : ('chat.searchChats'.tr.isNotEmpty &&
                'chat.searchChats'.tr != 'chat.searchChats'
            ? 'chat.searchChats'.tr
            : 'Search chats or students...');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: AppBackButton(onPressed: () => Get.back()),
        ),
        leadingWidth: 70,
        title: Text(
          titleText,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Tooltip(
                message: 'chat.newGroup'.tr.isNotEmpty &&
                        'chat.newGroup'.tr != 'chat.newGroup'
                    ? 'chat.newGroup'.tr
                    : 'New Chat',
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Material(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary
                        : const Color(0xFFF2F4F7),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Get.to(() => const CreateGroupScreen()),
                      child: Center(
                        child: Icon(
                          Icons.person_add_alt_1_outlined,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Clean iOS-Style Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceSecondary
                        : const Color(0xFFF2F4F7),
                    hintText: searchPlaceholder,
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.brandPrimary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Conversations list
              Expanded(
                child: Obx(() {
                  if (chatController.isLoadingConversations.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                   final allConversations = chatController.conversations;
                  final archivedCount =
                      allConversations.where((c) => c.isArchived).length;
                  final showArchivedRow =
                      _searchQuery.isEmpty && archivedCount > 0;

                  final filtered = allConversations.where((conv) {
                    if (conv.isArchived) return false;

                    if (_searchQuery.isNotEmpty) {
                      final matchName =
                          conv.name.toLowerCase().contains(_searchQuery);
                      final matchMsg =
                          conv.lastMessage.toLowerCase().contains(_searchQuery);
                      if (!matchName && !matchMsg) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    final isSearching = _searchQuery.isNotEmpty;
                    final emptyContent = Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.lightBgSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSearching
                                    ? Icons.search_off_rounded
                                    : Icons.forum_outlined,
                                size: 22,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSearching
                                  ? ('chat.noSearchResults'.tr.isNotEmpty &&
                                          'chat.noSearchResults'.tr !=
                                              'chat.noSearchResults'
                                      ? 'chat.noSearchResults'.tr
                                      : 'No chats found')
                                  : (('chat.noMessages'.tr.isNotEmpty &&
                                          'chat.noMessages'.tr !=
                                              'chat.noMessages')
                                      ? 'chat.noMessages'.tr
                                      : 'No messages yet'),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 260),
                              child: Text(
                                isSearching
                                    ? 'Try searching with a different name or keyword.'
                                    : (('chat.noMessagesSubtitle'.tr.isNotEmpty &&
                                            'chat.noMessagesSubtitle'.tr !=
                                                'chat.noMessagesSubtitle')
                                        ? 'chat.noMessagesSubtitle'.tr
                                        : 'Connect with student peers and join group discussions.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (showArchivedRow) {
                      return RefreshIndicator(
                        onRefresh: () => chatController.fetchConversations(),
                        color: AppColors.brandPrimary,
                        backgroundColor: surfaceColor,
                        child: ListView(
                          children: [
                            _buildArchivedRow(
                              context,
                              archivedCount,
                              isDark,
                              textPrimary,
                              textMuted,
                              borderColor,
                            ),
                            const SizedBox(height: 60),
                            emptyContent,
                          ],
                        ),
                      );
                    }

                    return emptyContent;
                  }

                  final totalItemCount =
                      filtered.length + (showArchivedRow ? 1 : 0);

                  return RefreshIndicator(
                    onRefresh: () => chatController.fetchConversations(),
                    color: AppColors.brandPrimary,
                    backgroundColor: surfaceColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: totalItemCount,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 76,
                        endIndent: 16,
                        color: borderColor.withValues(
                            alpha: isDark ? 0.35 : 0.5),
                      ),
                      itemBuilder: (context, index) {
                        if (showArchivedRow && index == 0) {
                          return _buildArchivedRow(
                            context,
                            archivedCount,
                            isDark,
                            textPrimary,
                            textMuted,
                            borderColor,
                          );
                        }
                        final convIndex =
                            showArchivedRow ? index - 1 : index;
                        final conv = filtered[convIndex];
                        return _buildConversationTile(
                          context,
                          conv,
                          chatController,
                          isDark,
                          textPrimary,
                          textSecondary,
                          textMuted,
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

  Widget _buildArchivedRow(
    BuildContext context,
    int count,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
  ) {
    return InkWell(
      onTap: () => Get.to(() => const ArchivedChatsScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: borderColor.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.archive_outlined,
                color: AppColors.brandPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Archived Chats',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ChatConversationModel conv,
    ChatController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return ChatListItem(
      conversation: conv,
      onTap: () async {
        debugPrint('[CHAT-NAV] source = ChatList, roomId = ${conv.id}, currentRoute = ${Get.currentRoute}, controller = ${identityHashCode(controller)}');
        await controller.openConversation(conv);
        if (!context.mounted) return;
        ChatNavigation.openChatDetail(conv.id, conversation: conv);
      },

      onMute: () async {
        await controller.muteConversation(conv.id);
        if (!Get.testMode) {
          final isNowMuted = controller.conversations
                  .firstWhereOrNull((c) => c.id == conv.id)
                  ?.isMuted ??
              !conv.isMuted;
          Get.snackbar(
            isNowMuted ? 'Muted' : 'Unmuted',
            isNowMuted
                ? ('chat.notificationsMuted'.tr.isNotEmpty &&
                        'chat.notificationsMuted'.tr != 'chat.notificationsMuted'
                    ? 'chat.notificationsMuted'.tr
                    : 'Notifications muted')
                : ('chat.notificationsUnmuted'.tr.isNotEmpty &&
                        'chat.notificationsUnmuted'.tr !=
                            'chat.notificationsUnmuted'
                    ? 'chat.notificationsUnmuted'.tr
                    : 'Notifications unmuted'),
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      },
      onArchive: () async {
        await controller.archiveConversation(conv.id);
        if (!Get.testMode) {
          Get.snackbar(
            'Archived',
            'chat.conversationArchived'.tr.isNotEmpty &&
                    'chat.conversationArchived'.tr != 'chat.conversationArchived'
                ? 'chat.conversationArchived'.tr
                : 'Conversation archived',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () => controller.unarchiveConversation(conv.id),
              child: Text(
                'chat.undo'.tr.isNotEmpty && 'chat.undo'.tr != 'chat.undo'
                    ? 'chat.undo'.tr
                    : 'Undo',
                style: const TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
      onUnarchive: () async {
        await controller.unarchiveConversation(conv.id);
        if (!Get.testMode) {
          Get.snackbar(
            'Unarchived',
            'Conversation unarchived',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      },
      onDelete: () => _confirmDeleteConversation(context, conv, controller),
    );
  }

  Future<void> _confirmDeleteConversation(
    BuildContext context,
    ChatConversationModel conv,
    ChatController controller,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'chat.deleteConversationTitle'.tr.isNotEmpty &&
                  'chat.deleteConversationTitle'.tr !=
                      'chat.deleteConversationTitle'
              ? 'chat.deleteConversationTitle'.tr
              : 'Delete conversation?',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'chat.deleteConversationPrompt'.tr.isNotEmpty &&
                  'chat.deleteConversationPrompt'.tr !=
                      'chat.deleteConversationPrompt'
              ? 'chat.deleteConversationPrompt'.tr
              : 'This conversation will be removed from your chat list.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'common.cancel'.tr.isNotEmpty &&
                      'common.cancel'.tr != 'common.cancel'
                  ? 'common.cancel'.tr
                  : 'Cancel',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'common.delete'.tr.isNotEmpty &&
                      'common.delete'.tr != 'common.delete'
                  ? 'common.delete'.tr
                  : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteConversation(conv.id);
      if (!Get.testMode) {
        Get.snackbar(
          'Deleted',
          'chat.conversationDeleted'.tr.isNotEmpty &&
                  'chat.conversationDeleted'.tr != 'chat.conversationDeleted'
              ? 'chat.conversationDeleted'.tr
              : 'Conversation deleted',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}

