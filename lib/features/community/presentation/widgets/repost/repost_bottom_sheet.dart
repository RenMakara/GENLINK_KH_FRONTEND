import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'original_post_preview.dart';
import 'repost_quote_input.dart';

/// Interactive button wrapper providing subtle 1.0 -> 0.98 -> 1.0 tactile press scale.
class _ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _ScaleOnPress({
    required this.child,
    this.onPressed,
  });

  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.onPressed != null ? (_) => _animController.forward() : null,
      onTapUp: widget.onPressed != null ? (_) => _animController.reverse() : null,
      onTapCancel: widget.onPressed != null ? () => _animController.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Modern iOS-inspired bottom sheet for reposting content with a real post preview.
class RepostBottomSheet extends StatefulWidget {
  final CommunityPostModel post;
  final CommunityController controller;

  const RepostBottomSheet({
    super.key,
    required this.post,
    required this.controller,
  });

  /// Opens the Repost Bottom Sheet modally with smooth slide-up animation.
  static Future<bool?> show(
    BuildContext context, {
    required CommunityPostModel post,
    required CommunityController controller,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 250),
      ),
      builder: (ctx) => RepostBottomSheet(
        post: post,
        controller: controller,
      ),
    );
  }

  @override
  State<RepostBottomSheet> createState() => _RepostBottomSheetState();
}

class _RepostBottomSheetState extends State<RepostBottomSheet> {
  late final TextEditingController _captionController;
  final FocusNode _quoteFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _quoteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRepost() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final caption = _captionController.text.trim();

    // Trigger existing controller repost flow
    widget.controller.repostPost(
      widget.post.id,
      caption: caption.isNotEmpty ? caption : null,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      AppNotificationBanner.showSuccess(
        context: context,
        title: "✓ Reposted",
        message: "Post has been reposted to your feed.",
        icon: Icons.repeat_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    // Repost primary button colors (Modern Dark Charcoal in Light Mode, Elevated High-Contrast in Dark Mode)
    final primaryBtnBg = isDark
        ? const Color(0xFFF2F4F7)
        : const Color(0xFF14161A);
    final primaryBtnFg = isDark
        ? const Color(0xFF14161A)
        : Colors.white;

    final repostTitle = 'community.repostContent'.tr.isNotEmpty &&
            'community.repostContent'.tr != 'community.repostContent'
        ? 'community.repostContent'.tr
        : 'Repost Content';

    final repostSubtitle = 'community.repostingOriginal'.tr.isNotEmpty &&
            'community.repostingOriginal'.tr != 'community.repostingOriginal'
        ? 'community.repostingOriginal'.trParams({'name': widget.post.authorName})
        : 'Reposting content originally by ${widget.post.authorName}';

    final repostNowText = 'community.repostNow'.tr.isNotEmpty &&
            'community.repostNow'.tr != 'community.repostNow'
        ? 'community.repostNow'.tr
        : 'Repost Now';

    final cancelText = 'common.cancel'.tr.isNotEmpty &&
            'common.cancel'.tr != 'common.cancel'
        ? 'common.cancel'.tr
        : 'Cancel';

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = (screenHeight - viewInsetsBottom).clamp(
      320.0,
      screenHeight * 0.90,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsetsBottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxSheetHeight,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorderStrong
                        : AppColors.lightBorderStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Scrollable Body (Header, Preview, Quote, Actions)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),

                      // ── Header (Icon + Title + Subtitle) ───────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightBgSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.repeat_rounded,
                              size: 24,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  repostTitle,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  repostSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Original Post Real Preview ─────────────────────────
                      OriginalPostPreview(post: widget.post),

                      const SizedBox(height: 16),

                      // ── Quote Input Section ────────────────────────────────
                      RepostQuoteInput(
                        controller: _captionController,
                        focusNode: _quoteFocusNode,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 20),

                      // ── Action Buttons (Cancel / Repost Now) ───────────────
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: Semantics(
                              label: 'Cancel repost',
                              button: true,
                              child: _ScaleOnPress(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => Navigator.of(context).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? AppColors.darkSurfaceSecondary
                                          : AppColors.lightSurfacePrimary,
                                      side: BorderSide(
                                        color: borderSubtle,
                                        width: 1.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      cancelText,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Repost Now Button
                          Expanded(
                            child: Semantics(
                              label: 'Repost this content',
                              button: true,
                              child: _ScaleOnPress(
                                onPressed: _isSubmitting ? null : _handleRepost,
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _handleRepost,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBtnBg,
                                      foregroundColor: primaryBtnFg,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: primaryBtnFg,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.repeat_rounded,
                                                size: 20,
                                                color: primaryBtnFg,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                repostNowText,
                                                style: TextStyle(
                                                  color: primaryBtnFg,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
