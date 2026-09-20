import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/chat_models.dart';
import 'chat_avatar.dart';

class ChatListItem extends StatefulWidget {
  final ChatConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onDelete;

  const ChatListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
    this.onMute,
    this.onArchive,
    this.onUnarchive,
    this.onDelete,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _anim;

  double _dragOffset = 0.0;
  static const double _actionWidth = 62.0;
  static const double _maxExtent = _actionWidth * 3; // 186.0

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant ChatListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _dragOffset = 0.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _animController.stop();
    _anim = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _anim!.value;
        });
      });
    _animController.forward(from: 0.0);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _animController.stop();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(-_maxExtent, 0.0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -300 || _dragOffset < -_maxExtent / 3) {
      _animateTo(-_maxExtent);
    } else {
      _animateTo(0.0);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final hasUnread = conversation.unreadCount > 0;
    final isStoryReply =
        conversation.lastMessage.toLowerCase().contains('story') ||
            conversation.id.contains('story');
    final isFinance = conversation.lastMessage.contains(r'$') ||
        conversation.lastMessage.contains('៛') ||
        conversation.lastMessage.toLowerCase().contains('sent') ||
        conversation.lastMessage.toLowerCase().contains('request');

    // 100% opaque background colors to completely prevent background button bleed
    final rowBg = hasUnread
        ? (isDark ? const Color(0xFF161F2E) : const Color(0xFFF3F7FD))
        : (isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary);

    final muteLabel = conversation.isMuted
        ? ('chat.unmuteChat'.tr.isNotEmpty &&
                'chat.unmuteChat'.tr != 'chat.unmuteChat'
            ? 'chat.unmuteChat'.tr
            : 'Unmute')
        : ('chat.muteChat'.tr.isNotEmpty &&
                'chat.muteChat'.tr != 'chat.muteChat'
            ? 'chat.muteChat'.tr
            : 'Mute');

    final archiveLabel = ('chat.archiveChat'.tr.isNotEmpty &&
            'chat.archiveChat'.tr != 'chat.archiveChat')
        ? 'chat.archiveChat'.tr
        : 'Archive';

    final deleteLabel = ('chat.deleteChat'.tr.isNotEmpty &&
            'chat.deleteChat'.tr != 'chat.deleteChat')
        ? 'chat.deleteChat'.tr
        : 'Delete';

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Background Action Buttons (revealed on swipe-left)
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: _maxExtent,
              child: Row(
                children: [
                  _buildActionButton(
                    icon: conversation.isMuted
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    label: muteLabel,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      _animateTo(0.0);
                      widget.onMute?.call();
                    },
                  ),
                  _buildActionButton(
                    icon: conversation.isArchived
                        ? Icons.unarchive_rounded
                        : Icons.archive_rounded,
                    label: conversation.isArchived ? 'Unarchive' : archiveLabel,
                    color: AppColors.brandPrimary,
                    onTap: () {
                      _animateTo(0.0);
                      if (conversation.isArchived) {
                        widget.onUnarchive?.call();
                      } else {
                        widget.onArchive?.call();
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: deleteLabel,
                    color: AppColors.danger,
                    onTap: () {
                      _animateTo(0.0);
                      widget.onDelete?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Foreground Row
        Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _handleHorizontalDragStart,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: Material(
              color: rowBg,
              child: InkWell(
                onTap: () {
                  if (_dragOffset != 0) {
                    _animateTo(0.0);
                  } else {
                    widget.onTap();
                  }
                },
                onLongPress: () {
                  if (_dragOffset != 0) {
                    _animateTo(0.0);
                  } else if (widget.onLongPress != null) {
                    widget.onLongPress!();
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          ChatAvatar(
                            avatarUrl: conversation.avatar,
                            name: conversation.name,
                            radius: 25,
                            isOnline: conversation.isOnline,
                            isEventChat: conversation.isEventChat,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              conversation.name,
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                fontSize: 15.5,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (conversation.isGroup) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandPrimary
                                                    .withValues(
                                                        alpha: isDark ? 0.18 : 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'chat.group'.tr.isNotEmpty &&
                                                        'chat.group'.tr !=
                                                            'chat.group'
                                                    ? 'chat.group'.tr
                                                    : 'GROUP',
                                                style: const TextStyle(
                                                  color: AppColors.brandPrimary,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ] else if (conversation.isEventChat) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandPrimary
                                                    .withValues(
                                                        alpha: isDark ? 0.18 : 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'chat.eventBadge'.tr.isNotEmpty &&
                                                        'chat.eventBadge'.tr !=
                                                            'chat.eventBadge'
                                                    ? 'chat.eventBadge'.tr
                                                    : 'EVENT',
                                                style: const TextStyle(
                                                  color: AppColors.brandPrimary,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (conversation.isMuted) ...[
                                          Icon(
                                            Icons.notifications_off_outlined,
                                            size: 13,
                                            color: textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          conversation.lastMessageTime,
                                          style: TextStyle(
                                            color: hasUnread
                                                ? AppColors.brandPrimary
                                                : textMuted,
                                            fontSize: 12,
                                            fontWeight: hasUnread
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (conversation.isPinned) ...[
                                      const Icon(
                                        Icons.push_pin_rounded,
                                        size: 13,
                                        color: AppColors.brandPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (isFinance) ...[
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 13,
                                        color: hasUnread ? textPrimary : textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                    ] else if (isStoryReply) ...[
                                      Icon(
                                        Icons.reply_rounded,
                                        size: 14,
                                        color: hasUnread ? textPrimary : textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        isStoryReply &&
                                                !conversation.lastMessage
                                                    .contains('Replied')
                                            ? ('chat.repliedToYourStory'.tr.isNotEmpty &&
                                                    'chat.repliedToYourStory'.tr !=
                                                        'chat.repliedToYourStory'
                                                ? '${'chat.repliedToYourStory'.tr}: ${conversation.lastMessage}'
                                                : 'Replied to your story: ${conversation.lastMessage}')
                                            : (conversation.lastMessage.isEmpty
                                                ? ('chat.noMessages'.tr.isNotEmpty &&
                                                        'chat.noMessages'.tr !=
                                                            'chat.noMessages'
                                                    ? 'chat.noMessages'.tr
                                                    : 'No messages yet')
                                                : conversation.lastMessage),
                                        style: TextStyle(
                                          color: conversation.lastMessage.isEmpty
                                              ? textMuted
                                              : (hasUnread
                                                  ? (isDark
                                                      ? const Color(0xFFE2E8F0)
                                                      : const Color(0xFF334155))
                                                  : textMuted),
                                          fontWeight: (hasUnread &&
                                                  conversation.lastMessage.isNotEmpty)
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                          fontStyle: conversation.lastMessage.isEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          fontSize: 13.5,
                                          height: 1.25,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasUnread) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        constraints: const BoxConstraints(
                                            minWidth: 20, minHeight: 20),
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              conversation.unreadCount > 9 ? 6 : 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          conversation.unreadCount > 99
                                              ? '99+'
                                              : '${conversation.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        left: 0,
                        top: 14,
                        bottom: 14,
                        child: Container(
                          width: 3.5,
                          decoration: const BoxDecoration(
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
