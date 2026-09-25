import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ChatAttachmentSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onFileTap;
  final VoidCallback onLocationTap;
  final VoidCallback onSendMoneyTap;
  final VoidCallback onRequestMoneyTap;
  final VoidCallback onScanKhqrTap;
  final VoidCallback onSharePostTap;
  final VoidCallback onShareEventTap;
  final VoidCallback onShareDiscussionTap;
  final VoidCallback onShareProfileTap;

  const ChatAttachmentSheet({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
    required this.onLocationTap,
    required this.onSendMoneyTap,
    required this.onRequestMoneyTap,
    required this.onScanKhqrTap,
    required this.onSharePostTap,
    required this.onShareEventTap,
    required this.onShareDiscussionTap,
    required this.onShareProfileTap,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    required VoidCallback onFileTap,
    required VoidCallback onLocationTap,
    required VoidCallback onSendMoneyTap,
    required VoidCallback onRequestMoneyTap,
    required VoidCallback onScanKhqrTap,
    required VoidCallback onSharePostTap,
    required VoidCallback onShareEventTap,
    required VoidCallback onShareDiscussionTap,
    required VoidCallback onShareProfileTap,
  }) {
    Get.bottomSheet(
      ChatAttachmentSheet(
        onCameraTap: onCameraTap,
        onGalleryTap: onGalleryTap,
        onFileTap: onFileTap,
        onLocationTap: onLocationTap,
        onSendMoneyTap: onSendMoneyTap,
        onRequestMoneyTap: onRequestMoneyTap,
        onScanKhqrTap: onScanKhqrTap,
        onSharePostTap: onSharePostTap,
        onShareEventTap: onShareEventTap,
        onShareDiscussionTap: onShareDiscussionTap,
        onShareProfileTap: onShareProfileTap,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final dividerColor = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'chat.mediaAndAttachments'.tr.isNotEmpty &&
                        'chat.mediaAndAttachments'.tr != 'chat.mediaAndAttachments'
                    ? 'chat.mediaAndAttachments'.tr
                    : 'Media & Attachments',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'chat.camera'.tr.isNotEmpty && 'chat.camera'.tr != 'chat.camera'
                        ? 'chat.camera'.tr
                        : 'Camera',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onCameraTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'chat.gallery'.tr.isNotEmpty && 'chat.gallery'.tr != 'chat.gallery'
                        ? 'chat.gallery'.tr
                        : 'Gallery',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onGalleryTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'chat.file'.tr.isNotEmpty && 'chat.file'.tr != 'chat.file'
                        ? 'chat.file'.tr
                        : 'File',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onFileTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.location_on_rounded,
                    label: 'chat.location'.tr.isNotEmpty && 'chat.location'.tr != 'chat.location'
                        ? 'chat.location'.tr
                        : 'Location',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onLocationTap();
                    },
                  ),
                ],
              ),
            ),

            Divider(height: 28, color: dividerColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'chat.genlinkFinance'.tr.isNotEmpty &&
                        'chat.genlinkFinance'.tr != 'chat.genlinkFinance'
                    ? 'chat.genlinkFinance'.tr
                    : 'GenLink Finance (KHQR / Bakong)',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionItem(
                    icon: Icons.payments_rounded,
                    label: 'chat.sendMoney'.tr.isNotEmpty && 'chat.sendMoney'.tr != 'chat.sendMoney'
                        ? 'chat.sendMoney'.tr
                        : 'Send Money',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onSendMoneyTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.request_quote_rounded,
                    label: 'chat.requestMoney'.tr.isNotEmpty && 'chat.requestMoney'.tr != 'chat.requestMoney'
                        ? 'chat.requestMoney'.tr
                        : 'Request Money',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onRequestMoneyTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'chat.scanKhqr'.tr.isNotEmpty && 'chat.scanKhqr'.tr != 'chat.scanKhqr'
                        ? 'chat.scanKhqr'.tr
                        : 'Scan KHQR',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onScanKhqrTap();
                    },
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            Divider(height: 28, color: dividerColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'chat.shareContent'.tr.isNotEmpty && 'chat.shareContent'.tr != 'chat.shareContent'
                    ? 'chat.shareContent'.tr
                    : 'Share GenLink Content',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionItem(
                    icon: Icons.article_rounded,
                    label: 'chat.post'.tr.isNotEmpty && 'chat.post'.tr != 'chat.post'
                        ? 'chat.post'.tr
                        : 'Post',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onSharePostTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.event_rounded,
                    label: 'chat.event'.tr.isNotEmpty && 'chat.event'.tr != 'chat.event'
                        ? 'chat.event'.tr
                        : 'Event',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onShareEventTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.forum_rounded,
                    label: 'chat.discussion'.tr.isNotEmpty && 'chat.discussion'.tr != 'chat.discussion'
                        ? 'chat.discussion'.tr
                        : 'Discussion',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onShareDiscussionTap();
                    },
                  ),
                  _buildActionItem(
                    icon: Icons.person_rounded,
                    label: 'chat.profile'.tr.isNotEmpty && 'chat.profile'.tr != 'chat.profile'
                        ? 'chat.profile'.tr
                        : 'Profile',
                    color: AppColors.chatPrimary,
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      onShareProfileTap();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 74,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
