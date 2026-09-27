import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../chat/domain/models/chat_models.dart';
import '../../../chat/presentation/bindings/chat_binding.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';

class ForumShareToChatSheet extends StatefulWidget {
  final ForumTopicModel? topic;
  final CommunityPostModel? post;
  final EventModel? event;
  final SharedContentModel? customSharedContent;

  const ForumShareToChatSheet({
    super.key,
    this.topic,
    this.post,
    this.event,
    this.customSharedContent,
  }) : assert(
          topic != null ||
              post != null ||
              event != null ||
              customSharedContent != null,
          'Either topic, post, event or customSharedContent must be provided',
        );

  static void show(
    BuildContext context, {
    ForumTopicModel? topic,
    CommunityPostModel? post,
    EventModel? event,
    SharedContentModel? customSharedContent,
  }) {
    assert(
      topic != null ||
          post != null ||
          event != null ||
          customSharedContent != null,
      'Either topic, post, event or customSharedContent must be provided',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForumShareToChatSheet(
        topic: topic,
        post: post,
        event: event,
        customSharedContent: customSharedContent,
      ),
    );
  }

  @override
  State<ForumShareToChatSheet> createState() => _ForumShareToChatSheetState();
}

class _ForumShareToChatSheetState extends State<ForumShareToChatSheet> {
  late final ChatController _chatController;
  final TextEditingController _searchController = TextEditingController();
  String? _sendingConversationId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      _chatController = Get.find<ChatController>();
    } else {
      ChatBinding().dependencies();
      _chatController = Get.find<ChatController>();
    }
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareTo(ChatConversationModel conv) async {
    if (_sendingConversationId != null) return;
    setState(() => _sendingConversationId = conv.id);

    try {
      await _chatController.openConversation(conv);

      final SharedContentModel sharedContent;
      if (widget.customSharedContent != null) {
        sharedContent = widget.customSharedContent!;
      } else if (widget.post != null) {
        final p = widget.post!;
        final firstLine = p.content.trim().split('\n').first.trim();
        final title = firstLine.isNotEmpty
            ? (firstLine.length > 60
                ? '${firstLine.substring(0, 57)}...'
                : firstLine)
            : 'Post by ${p.authorName}';
        String? thumb;
        if (p.imageUrls.isNotEmpty) {
          final img = p.imageUrls.firstWhere(
            (u) => !CommunityPostModel.isVideoUrl(u),
            orElse: () => '',
          );
          if (img.isNotEmpty) thumb = img;
        }
        if (thumb == null && p.mediaUrls != null && p.mediaUrls!.isNotEmpty) {
          final img = p.mediaUrls!.firstWhere(
            (u) => !CommunityPostModel.isVideoUrl(u),
            orElse: () => '',
          );
          if (img.isNotEmpty) thumb = img;
        }
        thumb ??= (p.mediaUrls != null && p.mediaUrls!.isNotEmpty)
            ? p.mediaUrls!.first
            : (p.imageUrls.isNotEmpty ? p.imageUrls.first : null);
        sharedContent = SharedContentModel(
          type: SharedContentType.post,
          id: p.id,
          title: title,
          previewText: p.content.trim(),
          thumbnailUrl: thumb,
          authorName: p.authorName,
          authorAvatar: p.authorAvatar,
          subtitle: p.community.isNotEmpty ? p.community : null,
        );
      } else if (widget.topic != null) {
        final t = widget.topic!;
        sharedContent = SharedContentModel(
          type: SharedContentType.discussion,
          id: t.id,
          title: t.title.trim(),
          previewText: t.content.trim(),
          authorName: t.authorName,
          authorAvatar: t.authorAvatar,
          subtitle: t.category.isNotEmpty ? t.category : null,
        );
      } else if (widget.event != null) {
        final e = widget.event!;
        sharedContent = SharedContentModel(
          type: SharedContentType.event,
          id: e.id,
          title: e.title.trim(),
          previewText: e.description.trim(),
          thumbnailUrl: e.imageUrl,
          authorName: e.organizerName,
          subtitle: e.location.isNotEmpty ? e.location : e.dateString,
        );
      } else {
        throw StateError('No content provided to share');
      }

      await _chatController.sendSharedContent(conv, sharedContent);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      Get.toNamed<void>(
        AppRoutes.chatDetail,
        arguments: {'roomId': conv.id},
      );

      final isPost = widget.post != null;
      final successTitle = 'community.shareToChat'.tr.isNotEmpty &&
              'community.shareToChat'.tr != 'community.shareToChat'
          ? 'community.shareToChat'.tr
          : 'Share to Chat';
      final successMsg = isPost
          ? ('community.sharedPostSuccess'.tr.isNotEmpty &&
                  'community.sharedPostSuccess'.tr != 'community.sharedPostSuccess'
              ? 'community.sharedPostSuccess'.tr
              : 'Post shared to chat')
          : ('community.sharedDiscussionSuccess'.tr.isNotEmpty &&
                  'community.sharedDiscussionSuccess'.tr !=
                      'community.sharedDiscussionSuccess'
              ? 'community.sharedDiscussionSuccess'.tr
              : 'Discussion shared to chat');

      if (Get.context != null) {
        AppNotificationBanner.showSuccess(
          context: Get.context!,
          title: successTitle,
          message: successMsg,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sendingConversationId = null);
        AppNotificationBanner.showError(
          context: context,
          title: 'Error',
          message: widget.post != null
              ? 'Failed to share post.'
              : 'Failed to share discussion.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;

    final sheetTitle = 'community.shareToChat'.tr.isNotEmpty &&
            'community.shareToChat'.tr != 'community.shareToChat'
        ? 'community.shareToChat'.tr
        : 'Share to Chat';

    final String previewTitle;
    final String previewSubtitle;
    final IconData previewIcon;

    if (widget.post != null) {
      final p = widget.post!;
      previewTitle = p.content.trim().isNotEmpty
          ? p.content.trim()
          : (p.authorName.isNotEmpty ? 'Post by ${p.authorName}' : 'Feed Post');
      previewSubtitle = p.authorName.isNotEmpty ? p.authorName : p.authorTag;
      previewIcon = Icons.article_outlined;
    } else {
      final t = widget.topic!;
      previewTitle = t.title;
      previewSubtitle = t.authorName;
      previewIcon = Icons.forum_rounded;
    }

    return Container(
      key: const Key('forum_share_to_chat_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: borderSubtle, width: 0.8),
          left: BorderSide(color: borderSubtle, width: 0.8),
          right: BorderSide(color: borderSubtle, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                          ) ??
                          TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Preview summary card (Neutral styling)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      previewIcon,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          previewTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          previewSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search chat...',
                  hintStyle: TextStyle(color: textMuted, fontSize: 13.5),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: textMuted, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white70 : Colors.black87,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // Conversation list
            Flexible(
              child: Obx(() {
                final allConversations = _chatController.conversations;
                final filtered = _searchQuery.isEmpty
                    ? allConversations
                    : allConversations
                        .where((c) =>
                            c.name.toLowerCase().contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: textMuted, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No chats available'
                                : 'No matching chats',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: borderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final conv = filtered[index];
                    final isSending = _sendingConversationId == conv.id;

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: AppAvatar(
                          imageUrl: conv.avatar,
                          name: conv.name,
                          size: 40,
                        ),
                        title: Text(
                          conv.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          conv.lastMessage.isNotEmpty
                              ? conv.lastMessage
                              : (conv.isGroup
                                  ? '${conv.membersCount} members'
                                  : 'Active chat'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        trailing: isSending
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : Colors.black,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                    color: isDark ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                        onTap: () => _shareTo(conv),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
