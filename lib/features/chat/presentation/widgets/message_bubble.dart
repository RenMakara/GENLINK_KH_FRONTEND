import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_finance_card.dart';
import 'chat_story_reply_card.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isGroupChat;
  final bool showAvatar;
  final bool showSenderName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onFinanceTap;
  final VoidCallback? onStoryTap;
  final VoidCallback? onSharedContentTap;
  final Function(String messageId)? onDeleteTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onReactionTap;
  final ValueChanged<String>? onReplyTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.isGroupChat = false,
    this.showAvatar = true,
    this.showSenderName = false,
    this.onAvatarTap,
    this.onFinanceTap,
    this.onStoryTap,
    this.onSharedContentTap,
    this.onDeleteTap,
    this.onLongPress,
    this.onReactionTap,
    this.onReplyTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isPlayingVoice = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMine = msg.isMine;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final incomingBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final incomingBorder = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    if (msg.messageType == 'finance') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              if (widget.showAvatar)
                ChatAvatar(
                  avatarUrl: msg.senderAvatar,
                  name: msg.senderName,
                  radius: 14,
                  showBadge: false,
                  onTap: widget.onAvatarTap,
                )
              else
                const SizedBox(width: 28),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: widget.onLongPress,
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMine && widget.showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          msg.senderName,
                          style: const TextStyle(
                            color: AppColors.chatPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ChatFinanceCard(
                      transaction: msg.financeTransaction?.toJson(),
                      content: msg.content,
                      isMine: isMine,
                      onViewInFinance: widget.onFinanceTap,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.timeAgo,
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                          if (msg.isPinned) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 11,
                              color: AppColors.chatPrimary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (msg.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _buildReactionsRow(isDark),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: widget.showAvatar ? 7 : 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (widget.showAvatar)
              ChatAvatar(
                avatarUrl: msg.senderAvatar,
                name: msg.senderName,
                radius: 14,
                showBadge: false,
                onTap: widget.onAvatarTap,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: widget.onLongPress,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.chatPrimary : incomingBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isMine ? AppColors.chatPrimary : incomingBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMine && widget.showSenderName)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg.senderName,
                              style: const TextStyle(
                                color: AppColors.chatPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                        if (msg.replyTo != null)
                          _buildQuotedReply(msg.replyTo!, isMine, isDark, textMuted),

                        if (msg.isDeleted)
                          _buildDeletedMessageState(isMine, textMuted)
                        else ...[
                          if (msg.messageType == 'story_reply')
                            ChatStoryReplyCard(
                              mediaUrl: msg.mediaUrl,
                              isMine: isMine,
                              isExpired: msg.storyReference?.isExpired ?? false,
                              onTap: widget.onStoryTap,
                            ),

                          if (_isSharedContent(msg.messageType))
                            _buildSharedContentCard(msg, isMine, isDark, textPrimary, textMuted),

                          if (msg.messageType == 'image' && msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty)
                            _buildImagePreview(context, msg.mediaUrl!),

                          if (msg.messageType == 'voice')
                            _buildVoiceWidget(msg, isMine, textMuted),

                          if (msg.content.isNotEmpty && msg.messageType != 'story_reply' && !_isSharedContent(msg.messageType))
                            Text(
                              msg.content,
                              style: TextStyle(
                                color: isMine ? Colors.white : textPrimary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            )
                          else if (msg.messageType == 'story_reply' && msg.content.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                msg.content,
                                style: TextStyle(
                                  color: isMine ? Colors.white : textPrimary,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 3),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.timeAgo,
                              style: TextStyle(
                                color: isMine ? Colors.white70 : textMuted,
                                fontSize: 10,
                              ),
                            ),
                            if (msg.isPinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin_rounded,
                                size: 10.5,
                                color: isMine ? Colors.white70 : AppColors.chatPrimary,
                              ),
                            ],
                            if (isMine && !msg.isDeleted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                _getDeliveryIcon(msg.deliveryStatus),
                                size: 13,
                                color: Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (msg.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _buildReactionsRow(isDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessageState(bool isMine, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: isMine ? Colors.white70 : textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            'chat.messageDeleted'.tr.isNotEmpty && 'chat.messageDeleted'.tr != 'chat.messageDeleted'
                ? 'chat.messageDeleted'.tr
                : 'This message was deleted',
            style: TextStyle(
              color: isMine ? Colors.white70 : textMuted,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedReply(
    ChatReplyReference reply,
    bool isMine,
    bool isDark,
    Color textMuted,
  ) {
    return GestureDetector(
      onTap: () {
        if (widget.onReplyTap != null && reply.messageId.isNotEmpty) {
          widget.onReplyTap!(reply.messageId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.black.withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMine ? Colors.white : AppColors.chatPrimary,
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reply.senderName,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.chatPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _getReplyPreviewText(reply),
              style: TextStyle(
                color: isMine ? Colors.white70 : textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getReplyPreviewText(ChatReplyReference reply) {
    if (reply.content.isNotEmpty) return reply.content;
    switch (reply.messageType) {
      case 'image':
        return 'chat.photo'.tr.isNotEmpty && 'chat.photo'.tr != 'chat.photo'
            ? '📷 ${'chat.photo'.tr}'
            : '📷 Photo';
      case 'voice':
        return 'chat.voiceMessage'.tr.isNotEmpty && 'chat.voiceMessage'.tr != 'chat.voiceMessage'
            ? '🎤 ${'chat.voiceMessage'.tr}'
            : '🎤 Voice message';
      case 'story_reply':
        return 'chat.repliedToYourStory'.tr.isNotEmpty && 'chat.repliedToYourStory'.tr != 'chat.repliedToYourStory'
            ? '↩ ${'chat.repliedToYourStory'.tr}'
            : '↩ Story reply';
      case 'finance':
        return '💰 GenLink Finance';
      default:
        return 'Shared attachment';
    }
  }

  Widget _buildReactionsRow(bool isDark) {
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: widget.message.reactions.map((r) {
        return GestureDetector(
          onTap: () => widget.onReactionTap?.call(r.emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: r.hasReacted
                  ? AppColors.chatPrimary.withValues(alpha: isDark ? 0.35 : 0.14)
                  : (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: r.hasReacted
                    ? AppColors.chatPrimary.withValues(alpha: 0.6)
                    : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 3),
                Text(
                  '${r.count}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: r.hasReacted
                        ? AppColors.chatPrimary
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isSharedContent(String type) {
    return type == 'shared_post' ||
        type == 'post_share' ||
        type == 'shared_event' ||
        type == 'event_share' ||
        type == 'shared_discussion' ||
        type == 'shared_profile';
  }

  Widget _buildSharedContentCard(
    ChatMessageModel msg,
    bool isMine,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    IconData icon = Icons.share_rounded;
    String badge = 'GenLink';

    if (msg.messageType.contains('post')) {
      icon = Icons.article_rounded;
      badge = 'chat.post'.tr.isNotEmpty && 'chat.post'.tr != 'chat.post'
          ? 'chat.post'.tr
          : 'Post';
    } else if (msg.messageType.contains('event')) {
      icon = Icons.event_rounded;
      badge = 'chat.event'.tr.isNotEmpty && 'chat.event'.tr != 'chat.event'
          ? 'chat.event'.tr
          : 'Event';
    } else if (msg.messageType.contains('discussion')) {
      icon = Icons.forum_rounded;
      badge = 'chat.discussion'.tr.isNotEmpty && 'chat.discussion'.tr != 'chat.discussion'
          ? 'chat.discussion'.tr
          : 'Discussion';
    } else if (msg.messageType.contains('profile')) {
      icon = Icons.person_rounded;
      badge = 'chat.profile'.tr.isNotEmpty && 'chat.profile'.tr != 'chat.profile'
          ? 'chat.profile'.tr
          : 'Profile';
    }

    return GestureDetector(
      onTap: widget.onSharedContentTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.black.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurfacePrimary : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMine
                ? Colors.white.withValues(alpha: 0.2)
                : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.chatPrimary.withValues(alpha: isMine ? 0.3 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isMine ? Colors.white : AppColors.chatPrimary, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    badge,
                    style: TextStyle(
                      color: isMine ? Colors.white70 : AppColors.chatPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String url) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.startsWith('http')
                  ? Image.network(url, fit: BoxFit.contain)
                  : Image.asset(url, fit: BoxFit.contain),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
          margin: const EdgeInsets.only(bottom: 6),
          child: url.startsWith('http')
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 120,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.chatPrimary),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 90,
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.white54),
                    ),
                  ),
                )
              : Image.asset(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildVoiceWidget(ChatMessageModel msg, bool isMine, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlayingVoice = !_isPlayingVoice;
              });
            },
            child: Icon(
              _isPlayingVoice
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: isMine ? Colors.white : AppColors.chatPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 88,
            height: 4,
            decoration: BoxDecoration(
              color: isMine ? Colors.white38 : textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: _isPlayingVoice
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isMine ? Colors.white : AppColors.chatPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            msg.voiceDurationSeconds != null
                ? '${msg.voiceDurationSeconds}s'
                : '0:15',
            style: TextStyle(
              color: isMine ? Colors.white70 : textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeliveryIcon(String status) {
    switch (status) {
      case 'sending':
        return Icons.access_time_rounded;
      case 'sent':
        return Icons.check_rounded;
      case 'delivered':
      case 'read':
      default:
        return Icons.done_all_rounded;
    }
  }
}
