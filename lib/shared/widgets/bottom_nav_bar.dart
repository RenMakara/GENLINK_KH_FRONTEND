import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom navigation: Home · Community · [+] · Financial · Profile.
///
/// iOS-style (CupertinoIcons) with labels: the active tab uses the filled
/// glyph variant, full-strength colour and a bold label; inactive tabs are
/// outlined and muted. The bar floats on a soft shadow — no hairline — and
/// the centre "+" is a raised white circle with its own shadow, per the
/// design.
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

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isNarrow = width < 360;
          final isVeryNarrow = width < 335;
          final barHeight = isVeryNarrow ? 74.0 : (isNarrow ? 78.0 : 84.0);
          final horizontalPadding = isVeryNarrow ? 4.0 : (isNarrow ? 6.0 : 10.0);
          final centerBtnSize = isVeryNarrow ? 52.0 : (isNarrow ? 56.0 : 62.0);
          final centerIconSize = isVeryNarrow ? 24.0 : (isNarrow ? 26.0 : 28.0);
          final navIconSize = isVeryNarrow ? 22.0 : (isNarrow ? 24.0 : 26.0);
          final navFontSize = isVeryNarrow ? 11.0 : (isNarrow ? 12.0 : 12.5);

          return Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 6),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                      icon: CupertinoIcons.person_3,
                      activeIcon: CupertinoIcons.person_3_fill,
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
                      icon: CupertinoIcons.chart_bar,
                      activeIcon: CupertinoIcons.chart_bar_fill,
                      label: 'nav.financial'.tr,
                      active: currentIndex == 2,
                      iconSize: navIconSize,
                      fontSize: navFontSize,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: CupertinoIcons.person,
                      activeIcon: CupertinoIcons.person_fill,
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
          );
        },
      ),
    );
  }
}

/// The raised white "+" circle: same surface as the bar, lifted by its own
/// shadow rather than tinted grey.
class _CenterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const _CenterButton({
    this.onTap,
    this.size = 62.0,
    this.iconSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: isDark ? scheme.surfaceContainerHighest : theme.cardColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              height: size,
              width: size,
              child: Icon(
                CupertinoIcons.plus,
                size: iconSize,
                color: scheme.onSurface,
                semanticLabel: 'Create',
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
    this.iconSize = 28.0,
    this.fontSize = 12.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    final activeColor = isDark ? Colors.white : scheme.onSurface;
    final inactiveColor = scheme.onSurface.withValues(alpha: 0.45);
    final color = active ? activeColor : inactiveColor;

    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: color,
            size: iconSize,
            semanticLabel: label,
          ),
          const SizedBox(height: 3),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
