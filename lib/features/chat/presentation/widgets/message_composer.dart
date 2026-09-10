import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/chat_models.dart';

class MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final VoidCallback onVoiceTap;
  final bool isSending;
  final ChatMessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    required this.onVoiceTap,
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
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
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
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null)
              Container(
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
              ),

            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 10,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.chatPrimary,
                      size: 28,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'chat.shareContent'.tr.isNotEmpty && 'chat.shareContent'.tr != 'chat.shareContent'
                        ? 'chat.shareContent'.tr
                        : 'Attachments',
                    onPressed: widget.onAttachmentTap,
                  ),
                  const SizedBox(width: 4),

                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 110),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: textMuted,
                            fontSize: 14,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
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
                  const SizedBox(width: 6),

                  if (_hasText || widget.isSending)
                    Material(
                      color: AppColors.chatPrimary,
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: InkWell(
                        onTap: widget.isSending ? null : widget.onSend,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
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
                                  size: 18,
                                ),
                        ),
                      ),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.chatPrimary,
                          size: 24,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        tooltip: 'chat.voiceNote'.tr.isNotEmpty && 'chat.voiceNote'.tr != 'chat.voiceNote'
                            ? 'chat.voiceNote'.tr
                            : 'Voice Note',
                        onPressed: widget.onVoiceTap,
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
