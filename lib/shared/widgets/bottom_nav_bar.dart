import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';
import '../../design_system/widgets/avatar/app_avatar.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../main_controller.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
  });

  static String _label(String key, String fallback) {
    final tr = key.tr;
    return (tr.isNotEmpty && tr != key) ? tr : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainController = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : null;
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    Widget buildBar(bool isVisible, String? avatarUrl) {
      return AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isNarrow = width < 360;
              final isVeryNarrow = width < 335;

              // Refined heights for floating design
              final barHeight = isVeryNarrow ? 72.0 : (isNarrow ? 76.0 : 82.0);
              final horizontalMargin = isVeryNarrow ? 12.0 : 20.0;

              // Use MediaQuery to get the bottom safe area and add extra float margin
              final safeBottom = MediaQuery.of(context).padding.bottom;
              final bottomMargin = safeBottom > 0 ? safeBottom + 8.0 : 20.0;

              final centerBtnSize = isVeryNarrow ? 50.0 : (isNarrow ? 54.0 : 60.0);
              final centerIconSize = isVeryNarrow ? 24.0 : (isNarrow ? 26.0 : 28.0);
              final navIconSize = isVeryNarrow ? 22.0 : (isNarrow ? 23.0 : 24.0);
              final navFontSize = isVeryNarrow ? 10.0 : (isNarrow ? 10.5 : 11.0);

              return Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalMargin,
                      0,
                      horizontalMargin,
                      bottomMargin,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceGlass
                                  : AppColors.lightSurfaceGlass,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _NavItem(
                                    icon: CupertinoIcons.house,
                                    activeIcon: CupertinoIcons.house_fill,
                                    label: _label('nav.home', 'Home'),
                                    active: currentIndex == 0,
                                    iconSize: navIconSize,
                                    fontSize: navFontSize,
                                    onTap: () => onTap(0),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: CupertinoIcons.flame,
                                    activeIcon: CupertinoIcons.flame_fill,
                                    label: _label('nav.levelUp', 'LevelUp'),
                                    active: currentIndex == 1,
                                    iconSize: navIconSize,
                                    fontSize: navFontSize,
                                    onTap: () => onTap(1),
                                  ),
                                ),
                                _CenterButton(
                                  onTap: onCenterTap,
                                  size: centerBtnSize,
                                  iconSize: centerIconSize,
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: CupertinoIcons.money_dollar_circle,
                                    activeIcon: CupertinoIcons.money_dollar_circle_fill,
                                    label: _label('nav.finance', 'Finance'),
                                    active: currentIndex == 2,
                                    iconSize: navIconSize,
                                    fontSize: navFontSize,
                                    onTap: () => onTap(2),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: CupertinoIcons.person_crop_circle,
                                    activeIcon: CupertinoIcons.person_crop_circle_fill,
                                    label: _label('nav.profile', 'Profile'),
                                    active: currentIndex == 3,
                                    iconSize: navIconSize,
                                    fontSize: navFontSize,
                                    onTap: () => onTap(3),
                                    imageUrl: avatarUrl,
                                    onLongPress: () => _showProfileMenu(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (mainController == null && authController == null) {
      return buildBar(true, null);
    }

    return Obx(() {
      final isVisible = mainController?.isNavBarVisible.value ?? true;
      final user = authController?.currentUser.value;
      return buildBar(isVisible, user?.avatarUrl);
    });
  }

  void _showProfileMenu(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.group_add_outlined, color: textPrimary),
              title: Text('auth.switchAccount'.tr),
              onTap: () {
                Navigator.pop(ctx);
                Get.showSnackbar(
                  GetSnackBar(
                    message: 'Coming soon',
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              title: Text('auth.logout'.tr, style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _showLogoutConfirm(context, authController);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showLogoutConfirm(BuildContext context, AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: Text('auth.logout'.tr),
        content: Text('auth.logoutConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: Text('auth.logout'.tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const _CenterButton({this.onTap, required this.size, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.white, const Color(0xFFE0E0E0)]
                : [AppColors.lightPrimary, const Color(0xFF333333)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : AppColors.lightPrimary)
                  .withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
            child: SizedBox(
              height: size,
              width: size,
              child: Icon(
                CupertinoIcons.plus,
                size: iconSize,
                color: isDark ? Colors.black : Colors.white,
                semanticLabel: 'nav.create'.tr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? imageUrl;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
    this.onLongPress,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = isDark ? Colors.white : AppColors.lightPrimary;
    final inactiveColor = (isDark ? Colors.white : AppColors.lightPrimary)
        .withValues(alpha: 0.4);

    final color = active ? activeColor : inactiveColor;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: onLongPress,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: AppAvatar(imageUrl: imageUrl, size: iconSize),
                  )
                : Icon(
                    active ? activeIcon : icon,
                    color: color,
                    size: iconSize,
                    semanticLabel: label,
                  ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: fontSize,
                  letterSpacing: active ? 0.2 : 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: active ? 3 : 0,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
