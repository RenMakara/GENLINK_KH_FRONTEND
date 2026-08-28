import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainController = Get.find<MainController>();

    return Obx(() {
      final isVisible = mainController.isNavBarVisible.value;

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

              return Padding(
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
                                label: 'nav.home'.tr,
                                active: currentIndex == 0,
                                iconSize: navIconSize,
                                fontSize: navFontSize,
                                onTap: () => onTap(0),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: CupertinoIcons.person_2,
                                activeIcon: CupertinoIcons.person_2_fill,
                                label: 'nav.community'.tr,
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
                                icon: CupertinoIcons.money_dollar,
                                activeIcon: CupertinoIcons.money_dollar_circle_fill,
                                label: 'nav.financial'.tr,
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
                                label: 'nav.profile'.tr,
                                active: currentIndex == 3,
                                iconSize: navIconSize,
                                fontSize: navFontSize,
                                onTap: () => onTap(3),
                              ),
                            ),
                          ],
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
    });
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

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
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
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
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
