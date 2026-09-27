import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ChatStoryReplyCard extends StatelessWidget {
  final String? mediaUrl;
  final bool isMine;
  final bool isExpired;
  final VoidCallback? onTap;

  const ChatStoryReplyCard({
    super.key,
    this.mediaUrl,
    required this.isMine,
    this.isExpired = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final repliedHeader = 'chat.repliedToStory'.tr.isNotEmpty &&
            'chat.repliedToStory'.tr != 'chat.repliedToStory'
        ? '↩ ${'chat.repliedToStory'.tr}'
        : ('storyReply.repliedToStory'.tr.isNotEmpty &&
                'storyReply.repliedToStory'.tr != 'storyReply.repliedToStory'
            ? 'storyReply.repliedToStory'.tr
            : '↩ Replied to Story');

    final subheader = isExpired
        ? ('chat.storyExpired'.tr.isNotEmpty && 'chat.storyExpired'.tr != 'chat.storyExpired'
            ? 'chat.storyExpired'.tr
            : 'Story expired')
        : ('chat.tapToView'.tr.isNotEmpty && 'chat.tapToView'.tr != 'chat.tapToView'
            ? 'chat.tapToView'.tr
            : 'Tap to view story');

    return GestureDetector(
      onTap: isExpired ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.black.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.darkSurfacePrimary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMine
                ? Colors.white.withValues(alpha: 0.25)
                : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.chatPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
                image: (mediaUrl != null && mediaUrl!.trim().isNotEmpty)
                    ? DecorationImage(
                        image: (mediaUrl!.startsWith('http://') ||
                                mediaUrl!.startsWith('https://'))
                            ? NetworkImage(mediaUrl!.trim()) as ImageProvider
                            : (mediaUrl!.startsWith('assets/')
                                ? AssetImage(mediaUrl!.trim())
                                : FileImage(File(mediaUrl!
                                    .trim()
                                    .replaceFirst('file://', '')))),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: (mediaUrl == null || mediaUrl!.isEmpty)
                  ? Center(
                      child: Icon(
                        isExpired ? Icons.timer_off_outlined : Icons.auto_awesome,
                        size: 16,
                        color: isMine ? Colors.white70 : AppColors.chatPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  repliedHeader,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.chatPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subheader,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
