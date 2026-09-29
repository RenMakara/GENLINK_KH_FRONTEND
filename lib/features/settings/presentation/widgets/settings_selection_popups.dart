import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

// ============================================================================
// 1. APPEARANCE (THEME) SELECTION POPOVER MENU
// ============================================================================

/// Modern iOS/popover-styled anchored menu for choosing app theme:
/// 1. System
/// 2. Light
/// 3. Dark
///
/// Anchors directly over the tapped row with checkmark indicator on the left
/// and smooth scale/fade popover animation.
class AppearanceSelectionPopup extends StatelessWidget {
  const AppearanceSelectionPopup({super.key, required this.controller});

  final SettingsController controller;

  static Future<void> show(
    BuildContext context,
    SettingsController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top + 16.0;
    final safeBottom = screenHeight - mediaQuery.padding.bottom - 16.0;

    final renderBox = context.findRenderObject() as RenderBox?;
    final Rect targetRect;
    if (renderBox != null && renderBox.hasSize) {
      targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    } else {
      targetRect = Rect.fromLTWH(
        screenWidth - 195,
        screenHeight * 0.35,
        175,
        56,
      );
    }

    const menuWidth = 175.0;
    const menuHeight = 146.0;

    // Align right with the right margin of the row/screen
    double right = screenWidth - targetRect.right + 12.0;
    if (right < 16.0) right = 16.0;
    if (right + menuWidth > screenWidth) {
      right = screenWidth - menuWidth - 16.0;
    }

    // In the reference screenshot, the menu top is slightly above the Appearance row
    double top = targetRect.top - 20.0;
    if (top + menuHeight > safeBottom) {
      top = safeBottom - menuHeight;
    }
    if (top < safeTop) {
      top = safeTop;
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Stack(
          children: [
            Positioned(
              top: top,
              right: right,
              child: FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
                  alignment: Alignment.topRight,
                  child: AppearanceSelectionPopup(controller: controller),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232428) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Obx(() {
          final currentTheme = controller.settings.value.theme;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. System
              _PopoverMenuRow(
                label: 'settings.themeSystemShort'.tr,
                isSelected: currentTheme == UserSettingsEntity.themeSystem,
                onTap: () => _handleSelectTheme(
                  context,
                  controller,
                  UserSettingsEntity.themeSystem,
                ),
              ),

              // 2. Light
              _PopoverMenuRow(
                label: 'settings.themeLight'.tr,
                isSelected: currentTheme == UserSettingsEntity.themeLight,
                onTap: () => _handleSelectTheme(
                  context,
                  controller,
                  UserSettingsEntity.themeLight,
                ),
              ),

              // 3. Dark
              _PopoverMenuRow(
                label: 'settings.themeDark'.tr,
                isSelected: currentTheme == UserSettingsEntity.themeDark,
                onTap: () => _handleSelectTheme(
                  context,
                  controller,
                  UserSettingsEntity.themeDark,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static Future<void> _handleSelectTheme(
    BuildContext context,
    SettingsController controller,
    String themeCode,
  ) async {
    await controller.setTheme(themeCode);
    if (context.mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}

// ============================================================================
// 2. LANGUAGE SELECTION POPOVER MENU
// ============================================================================

/// Modern iOS/popover-styled anchored menu for choosing language:
/// 1. English
/// 2. ភាសាខ្មែរ
class LanguageSelectionPopup extends StatelessWidget {
  const LanguageSelectionPopup({super.key, required this.controller});

  final SettingsController controller;

  static Future<void> show(
    BuildContext context,
    SettingsController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top + 16.0;
    final safeBottom = screenHeight - mediaQuery.padding.bottom - 16.0;

    final renderBox = context.findRenderObject() as RenderBox?;
    final Rect targetRect;
    if (renderBox != null && renderBox.hasSize) {
      targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    } else {
      targetRect = Rect.fromLTWH(
        screenWidth - 200,
        screenHeight * 0.3,
        185,
        56,
      );
    }

    const menuWidth = 185.0;
    const menuHeight = 104.0;

    // Align right with the right margin of the row/screen
    double right = screenWidth - targetRect.right + 12.0;
    if (right < 16.0) right = 16.0;
    if (right + menuWidth > screenWidth) {
      right = screenWidth - menuWidth - 16.0;
    }

    double top = targetRect.top - 18.0;
    if (top + menuHeight > safeBottom) {
      top = safeBottom - menuHeight;
    }
    if (top < safeTop) {
      top = safeTop;
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Stack(
          children: [
            Positioned(
              top: top,
              right: right,
              child: FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
                  alignment: Alignment.topRight,
                  child: LanguageSelectionPopup(controller: controller),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 185,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232428) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Obx(() {
          final currentLang = controller.settings.value.language;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. English
              _PopoverMenuRow(
                label: 'settings.languageEnglish'.tr,
                isSelected: currentLang == UserSettingsEntity.languageEnglish,
                onTap: () => _handleSelectLanguage(
                  context,
                  controller,
                  UserSettingsEntity.languageEnglish,
                ),
              ),

              // 2. Khmer
              _PopoverMenuRow(
                label: 'settings.languageKhmer'.tr,
                isSelected: currentLang == UserSettingsEntity.languageKhmer,
                onTap: () => _handleSelectLanguage(
                  context,
                  controller,
                  UserSettingsEntity.languageKhmer,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static Future<void> _handleSelectLanguage(
    BuildContext context,
    SettingsController controller,
    String languageCode,
  ) async {
    await controller.setLanguage(languageCode);
    if (context.mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}

// ============================================================================
// 3. COMMON POPOVER MENU ROW
// ============================================================================

class _PopoverMenuRow extends StatelessWidget {
  const _PopoverMenuRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        splashColor: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // Checkmark indicator slot on the left
              SizedBox(
                width: 20,
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 19,
                        color: isDark ? Colors.white : Colors.black87,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E1E24),
                    letterSpacing: -0.2,
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
