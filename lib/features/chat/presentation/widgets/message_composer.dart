import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/typography/app_typography.dart';
import '../../domain/models/chat_models.dart';

/// Interactive scale bounce button providing modern iOS tactile feedback.
class _ComposerPressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ComposerPressableScale({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<_ComposerPressableScale> createState() => _ComposerPressableScaleState();
}

class _ComposerPressableScaleState extends State<_ComposerPressableScale> {
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

class MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onEmojiTap;
  final bool isSending;
  final ChatMessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    this.onVoiceTap,
    this.onEmojiTap,
    this.isSending = false,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void didUpdateWidget(MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      _hasText = widget.controller.text.trim().isNotEmpty;
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _showQuickEmojiPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    const commonEmojis = [
      '😊', '😂', '❤️', '🔥', '👍', '🙏', '😍', '👏',
      '🎉', '✨', '🥺', '🥳', '😎', '💯', '🤔', '🙌',
      '💪', '🤝', '⚡', '👀', '🥰', '🤣', '😭', '🤩',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: borderColor, width: 0.6),
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
            left: 18,
            right: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'chat.selectEmoji'.tr.isNotEmpty && 'chat.selectEmoji'.tr != 'chat.selectEmoji'
                        ? 'chat.selectEmoji'.tr
                        : 'Quick Emojis',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: commonEmojis.map((emoji) {
                  return _ComposerPressableScale(
                    onTap: () {
                      final text = widget.controller.text;
                      final selection = widget.controller.selection;
                      final newText = selection.start >= 0
                          ? text.replaceRange(selection.start, selection.end, emoji)
                          : text + emoji;
                      widget.controller.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: (selection.start >= 0 ? selection.start : text.length) + emoji.length,
                        ),
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyingBanner(bool isDark, Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.chatPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'chat.replyingTo'.tr.isNotEmpty && 'chat.replyingTo'.tr != 'chat.replyingTo'
                      ? 'chat.replyingTo'.trParams({'name': widget.replyingTo!.senderName})
                      : 'Replying to ${widget.replyingTo!.senderName}',
                  style: const TextStyle(
                    color: AppColors.chatPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingTo!.content.isNotEmpty
                      ? widget.replyingTo!.content
                      : (widget.replyingTo!.messageType == 'image'
                          ? '📷 Photo'
                          : (widget.replyingTo!.messageType == 'voice'
                              ? '🎤 Voice note'
                              : 'Attachment')),
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
            tooltip: 'Cancel reply',
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final inputBg = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final hint = 'chat.typeMessage'.tr.isNotEmpty && 'chat.typeMessage'.tr != 'chat.typeMessage'
        ? 'chat.typeMessage'.tr
        : 'Type a message...';

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.7), width: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null)
              _buildReplyingBanner(isDark, borderColor, textMuted),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Blue circular + button with tactile scale animation
                  _ComposerPressableScale(
                    onTap: widget.onAttachmentTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.chatPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.chatPrimary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Center text input container
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 110),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: TextField(
                        controller: widget.controller,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontFamily: AppTypography.englishFontFamily,
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: textMuted,
                            fontSize: 15,
                            fontFamily: AppTypography.englishFontFamily,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) {
                          if (_hasText && !widget.isSending) {
                            widget.onSend();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right button: AnimatedSwitcher between Emoji and Send
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _hasText || widget.isSending
                        ? _ComposerPressableScale(
                            key: const ValueKey('send_button'),
                            onTap: widget.isSending ? null : widget.onSend,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.chatPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.chatPrimary.withValues(alpha: 0.32),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: widget.isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                            ),
                          )
                        : _ComposerPressableScale(
                            key: const ValueKey('emoji_button'),
                            onTap: () {
                              if (widget.onEmojiTap != null) {
                                widget.onEmojiTap!();
                              } else {
                                _showQuickEmojiPicker(context);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: Icon(
                                Icons.emoji_emotions_outlined,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                size: 24,
                              ),
                            ),
                          ),
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
