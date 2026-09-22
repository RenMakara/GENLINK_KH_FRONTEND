import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../colors/app_colors.dart';
import '../../typography/app_typography.dart';

/// Semantic variants for the GenLink confirmation dialog system.
enum GenLinkDialogType {
  /// Irreversible or destructive actions (red #E41414).
  /// Examples: Delete item, Quit Quiz, Cancel Registration.
  danger,

  /// Actions where data might be lost or important reversible actions (orange #F59E0B).
  /// Examples: Unsaved changes, Reset, Log Out.
  warning,

  /// Discarding unsaved drafts or edits (purple #8B7CF6).
  /// Examples: Discard Draft, Discard Changes.
  discard,

  /// Standard neutral confirmation (brand blue #1F6FEB).
  /// Examples: Confirm Action, Continue, Submit.
  confirm,

  /// Informational confirmation or advisory notice (blue #1F6FEB).
  /// Examples: Review Information, Notice.
  info,

  /// Positive feedback or completed action acknowledgment (green #22C55E).
  /// Examples: Changes Saved, Operation Successful.
  success,
}

/// Global standardized confirmation dialog component for GenLink.
///
/// Follows the "Modern GenLink Confirmation Dialog" specification:
/// - iOS-inspired clean rounded container (24px radius)
/// - Light (#FFFFFF) and Dark (#242526) surfaces
/// - Centered 52px semantic icon in soft pastel tint container
/// - Bold title with non-clipping line height for English & Khmer
/// - Clear description text
/// - Action hierarchy: Neutral secondary button + filled semantic primary button
/// - Optional top-right 'x' dismiss button
class GenLinkConfirmDialog extends StatelessWidget {
  const GenLinkConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.type = GenLinkDialogType.danger,
    this.icon,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.showCloseButton = true,
    this.isSingleAction = false,
    this.borderRadius = 24.0,
  });

  /// The main heading of the dialog (e.g. "Delete Event?", "Quit Quiz?").
  final String title;

  /// Explanatory message or subtitle describing the consequence.
  final String? message;

  /// Optional custom content widget placed between description and actions.
  final Widget? content;

  /// Semantic variant dictating colors and default icon.
  final GenLinkDialogType type;

  /// Explicit icon overriding the variant's default icon.
  final IconData? icon;

  /// Label for the primary action button (e.g. "Delete", "Quit", "Confirm").
  final String? confirmLabel;

  /// Label for the secondary action button (e.g. "Cancel", "Keep Editing").
  final String? cancelLabel;

  /// Callback executed when the primary action button is tapped.
  final VoidCallback? onConfirm;

  /// Callback executed when the cancel button or close 'x' is tapped.
  final VoidCallback? onCancel;

  /// Whether to show the circular 'x' dismiss button at the top right.
  final bool showCloseButton;

  /// Whether to display only the primary action button (e.g. for Success "OK").
  final bool isSingleAction;

  /// Container corner radius (defaults to 24px per GenLink spec).
  final double borderRadius;

  // ─────────────────────────────────────────────────────────────────────────
  // STATIC SHOW HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows the dialog with smooth fade and scale entrance animation (200ms easeOutCubic).
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    GenLinkDialogType type = GenLinkDialogType.danger,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
    bool isSingleAction = false,
    double borderRadius = 24.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.60 : 0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => GenLinkConfirmDialog(
        title: title,
        message: message,
        content: content,
        type: type,
        icon: icon,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showCloseButton: showCloseButton,
        isSingleAction: isSingleAction,
        borderRadius: borderRadius,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Convenience shortcut for Danger / Destructive actions (e.g. Delete, Quit).
  static Future<bool> showDanger({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      content: content,
      type: GenLinkDialogType.danger,
      icon: icon ?? Icons.delete_outline_rounded,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  /// Convenience shortcut for Warning actions (e.g. Log Out, Reset).
  static Future<bool> showWarning({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      content: content,
      type: GenLinkDialogType.warning,
      icon: icon ?? Icons.warning_amber_rounded,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  /// Convenience shortcut for Discard Draft / Unsaved changes dialogs.
  static Future<bool> showDiscard({
    required BuildContext context,
    String? title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title ?? 'community.discardDraft'.tr,
      message: message ?? 'community.discardMessage'.tr,
      content: content,
      type: GenLinkDialogType.discard,
      icon: icon ?? Icons.description_outlined,
      confirmLabel: confirmLabel ?? 'community.discard'.tr,
      cancelLabel: cancelLabel ?? 'community.keepEditing'.tr,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  /// Convenience shortcut for Log Out confirmation.
  static Future<bool> showLogout({
    required BuildContext context,
    String? title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title ?? 'auth.logout'.tr,
      message: message ?? 'auth.logoutConfirm'.tr,
      content: content,
      type: GenLinkDialogType.warning,
      icon: icon ?? Icons.logout_rounded,
      confirmLabel: confirmLabel ?? 'auth.logout'.tr,
      cancelLabel: cancelLabel ?? 'common.cancel'.tr,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  /// Convenience shortcut for Confirm / Primary actions (e.g. Save, Continue).
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      content: content,
      type: GenLinkDialogType.confirm,
      icon: icon ?? Icons.check_circle_outline_rounded,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  /// Convenience shortcut for Success feedback with single "OK" button.
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
    bool showCloseButton = true,
  }) async {
    await show(
      context: context,
      title: title,
      message: message,
      content: content,
      type: GenLinkDialogType.success,
      icon: icon ?? Icons.check_circle_rounded,
      confirmLabel: confirmLabel ?? 'OK',
      onConfirm: onConfirm,
      isSingleAction: true,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
  }

  /// Convenience shortcut for Informational notices.
  static Future<bool> showInfo({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool showCloseButton = true,
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      content: content,
      type: GenLinkDialogType.info,
      icon: icon ?? Icons.info_outline_rounded,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      showCloseButton: showCloseButton,
    );
    return result == true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _resolveVisualTokens(type, isDark);

    final resolvedIcon = icon ?? visual.defaultIcon;
    final resolvedCancel = cancelLabel ?? 'common.cancel'.tr;
    final resolvedConfirm = confirmLabel ?? visual.defaultConfirmLabel;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: isDark
              ? semantic.borderSubtle
              : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242526) : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Row: Close 'x' Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCloseButton)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(false);
                        onCancel?.call();
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2B2D)
                              : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFB0B3B8)
                              : const Color(0xFF8C9199),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),

            // Semantic Icon Container
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: visual.iconContainerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: visual.accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: visual.accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  resolvedIcon,
                  size: 26,
                  color: visual.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.englishFontFamily,
                fontFamilyFallback: const [AppTypography.khmerFontFamily, 'KantumruyPro'],
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF18191B),
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Message / Description
            if (message != null && message!.isNotEmpty)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.englishFontFamily,
                  fontFamilyFallback: const [AppTypography.khmerFontFamily, 'KantumruyPro'],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF5C6066),
                  height: 1.45,
                ),
              ),

            // Optional custom widget content
            if (content != null) ...[
              const SizedBox(height: 12),
              content!,
            ],
            const SizedBox(height: 22),

            // Button Action Hierarchy
            if (isSingleAction)
              // Single full-width button (e.g. Success "OK")
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: visual.primaryButtonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: visual.primaryButtonColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  child: Text(
                    resolvedConfirm,
                    style: const TextStyle(
                      fontFamily: AppTypography.englishFontFamily,
                      fontFamilyFallback: [AppTypography.khmerFontFamily, 'KantumruyPro'],
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              )
            else
              // Two-Button Row: Neutral Cancel + Semantic Primary
              Row(
                children: [
                  // Secondary / Cancel Button (Neutral)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF2A2B2D)
                              : const Color(0xFFF0F2F5),
                          foregroundColor: isDark
                              ? const Color(0xFFE4E6EB)
                              : const Color(0xFF18191B),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF3E4042)
                                : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          onCancel?.call();
                        },
                        child: Text(
                          resolvedCancel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.englishFontFamily,
                            fontFamilyFallback: const [AppTypography.khmerFontFamily, 'KantumruyPro'],
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE4E6EB)
                                : const Color(0xFF18191B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Primary Action Button (Semantic Filled Color)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: visual.primaryButtonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: visual.primaryButtonColor.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          onConfirm?.call();
                        },
                        child: Text(
                          resolvedConfirm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.englishFontFamily,
                            fontFamilyFallback: [AppTypography.khmerFontFamily, 'KantumruyPro'],
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VISUAL TOKENS RESOLUTION
  // ─────────────────────────────────────────────────────────────────────────

  static _VisualTokens _resolveVisualTokens(GenLinkDialogType type, bool isDark) {
    switch (type) {
      case GenLinkDialogType.danger:
        return _VisualTokens(
          accentColor: const Color(0xFFE41414),
          iconContainerColor: isDark
              ? const Color(0xFF450A0A).withValues(alpha: 0.45)
              : const Color(0xFFFEF2F2),
          primaryButtonColor: const Color(0xFFE41414),
          defaultIcon: Icons.delete_outline_rounded,
          defaultConfirmLabel: 'common.delete'.tr,
        );

      case GenLinkDialogType.warning:
        return _VisualTokens(
          accentColor: const Color(0xFFF59E0B),
          iconContainerColor: isDark
              ? const Color(0xFF451A03).withValues(alpha: 0.45)
              : const Color(0xFFFFFBEB),
          primaryButtonColor: const Color(0xFFEA580C),
          defaultIcon: Icons.warning_amber_rounded,
          defaultConfirmLabel: 'common.continue'.tr,
        );

      case GenLinkDialogType.discard:
        return _VisualTokens(
          accentColor: const Color(0xFF8B7CF6),
          iconContainerColor: isDark
              ? const Color(0xFF3B0764).withValues(alpha: 0.45)
              : const Color(0xFFF5F3FF),
          primaryButtonColor: const Color(0xFF7C3AED),
          defaultIcon: Icons.description_outlined,
          defaultConfirmLabel: 'community.discard'.tr,
        );

      case GenLinkDialogType.confirm:
        return _VisualTokens(
          accentColor: const Color(0xFF1F6FEB),
          iconContainerColor: isDark
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.45)
              : const Color(0xFFEFF6FF),
          primaryButtonColor: const Color(0xFF1F6FEB),
          defaultIcon: Icons.check_circle_outline_rounded,
          defaultConfirmLabel: 'common.continue'.tr,
        );

      case GenLinkDialogType.info:
        return _VisualTokens(
          accentColor: const Color(0xFF1F6FEB),
          iconContainerColor: isDark
              ? const Color(0xFF0C4A6E).withValues(alpha: 0.45)
              : const Color(0xFFF0F9FF),
          primaryButtonColor: const Color(0xFF1F6FEB),
          defaultIcon: Icons.info_outline_rounded,
          defaultConfirmLabel: 'common.continue'.tr,
        );

      case GenLinkDialogType.success:
        return _VisualTokens(
          accentColor: const Color(0xFF22C55E),
          iconContainerColor: isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.45)
              : const Color(0xFFF0FDF4),
          primaryButtonColor: const Color(0xFF22C55E),
          defaultIcon: Icons.check_circle_rounded,
          defaultConfirmLabel: 'OK',
        );
    }
  }
}

class _VisualTokens {
  const _VisualTokens({
    required this.accentColor,
    required this.iconContainerColor,
    required this.primaryButtonColor,
    required this.defaultIcon,
    required this.defaultConfirmLabel,
  });

  final Color accentColor;
  final Color iconContainerColor;
  final Color primaryButtonColor;
  final IconData defaultIcon;
  final String defaultConfirmLabel;
}
