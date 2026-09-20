import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';

class ForumRepostDialog extends StatefulWidget {
  final ForumTopicModel topic;

  const ForumRepostDialog({
    super.key,
    required this.topic,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ForumTopicModel topic,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ForumRepostDialog(
        topic: topic,
      ),
    );
  }

  @override
  State<ForumRepostDialog> createState() => _ForumRepostDialogState();
}

class _ForumRepostDialogState extends State<ForumRepostDialog> {
  late final TextEditingController _captionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handleRepost() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    final CommunityController controller;
    if (Get.isRegistered<CommunityController>()) {
      controller = Get.find<CommunityController>();
    } else {
      controller = Get.put(CommunityController());
    }

    final quote = _captionController.text;

    try {
      final success = await controller.repostDiscussion(
        widget.topic,
        caption: quote,
      );

      if (!mounted) return;

      Navigator.of(context).pop(success);

      if (success) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: 'community.reposted'.tr.isNotEmpty &&
                  'community.reposted'.tr != 'community.reposted'
              ? 'community.reposted'.tr
              : '✓ Reposted',
          message: 'Discussion has been reposted to your feed.',
          icon: Icons.repeat_rounded,
        );
      } else {
        AppNotificationBanner.showError(
          context: context,
          title: 'common.error'.tr.isNotEmpty &&
                  'common.error'.tr != 'common.error'
              ? 'common.error'.tr
              : 'Error',
          message: 'Failed to repost discussion. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(false);

      AppNotificationBanner.showError(
        context: context,
        title: 'common.error'.tr.isNotEmpty &&
                'common.error'.tr != 'common.error'
            ? 'common.error'.tr
            : 'Error',
        message: 'Failed to repost discussion. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.65;

    return SafeArea(
      child: AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          side: BorderSide(color: borderSubtle),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.end,
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.repeat_rounded,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'community.repostContent'.tr.isNotEmpty &&
                          'community.repostContent'.tr !=
                              'community.repostContent'
                      ? 'community.repostContent'.tr
                      : 'Repost this content?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ) ??
                      TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isAnonymous = widget.topic.isAnonymous ||
                        widget.topic.authorName.trim().toLowerCase() == 'anonymous';
                    final effectiveAuthor = isAnonymous
                        ? ('community.anonymous'.tr.isNotEmpty &&
                                'community.anonymous'.tr != 'community.anonymous'
                            ? 'community.anonymous'.tr
                            : 'Anonymous')
                        : widget.topic.authorName;
                    return Text(
                      'community.repostingOriginal'.tr.isNotEmpty &&
                              'community.repostingOriginal'.tr !=
                                  'community.repostingOriginal'
                          ? 'community.repostingOriginal'
                              .trParams({'name': effectiveAuthor})
                          : 'This will repost content originally by $effectiveAuthor.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ) ??
                          TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: borderSubtle),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _captionController,
                    minLines: 2,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontSize: 14,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                        ),
                    decoration: InputDecoration(
                      hintText: 'community.repostQuoteHint'.tr.isNotEmpty &&
                              'community.repostQuoteHint'.tr !=
                                  'community.repostQuoteHint'
                          ? 'community.repostQuoteHint'.tr
                          : 'Add a quote (optional)...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: textMuted,
                            fontSize: 14,
                          ) ??
                          TextStyle(
                            color: textMuted,
                            fontSize: 14,
                          ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: BorderSide(color: borderSubtle),
              minimumSize: const Size(88, 42),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: Text(
              'common.cancel'.tr.isNotEmpty &&
                      'common.cancel'.tr != 'common.cancel'
                  ? 'common.cancel'.tr
                  : 'Cancel',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleRepost,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              disabledBackgroundColor:
                  (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      .withValues(alpha: 0.6),
              elevation: 0,
              minimumSize: const Size(88, 42),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 4,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                      ),
                    ),
                  )
                : Text(
                    'community.repost'.tr.isNotEmpty &&
                            'community.repost'.tr != 'community.repost'
                        ? 'community.repost'.tr
                        : 'Repost',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextInverse
                          : AppColors.lightTextInverse,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
