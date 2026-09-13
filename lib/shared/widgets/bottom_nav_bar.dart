import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/widgets/avatar/app_avatar.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../main_controller.dart';

// ─── Tab definitions ──────────────────────────────────────────────────────────
class _TabDef {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String labelKey;
  final String labelFallback;

  const _TabDef({
    required this.outlineIcon,
    required this.filledIcon,
    required this.labelKey,
    required this.labelFallback,
  });
}

const _kTabs = [
  _TabDef(
    outlineIcon: Icons.home_outlined,
    filledIcon: Icons.home_rounded,
    labelKey: 'nav.home',
    labelFallback: 'Home',
  ),
  _TabDef(
    outlineIcon: Icons.bar_chart_outlined,
    filledIcon: Icons.bar_chart_rounded,
    labelKey: 'nav.levelUp',
    labelFallback: 'LevelUp',
  ),
  _TabDef(
    outlineIcon: Icons.paid_outlined,
    filledIcon: Icons.paid_rounded,
    labelKey: 'nav.finance',
    labelFallback: 'Finance',
  ),
  _TabDef(
    outlineIcon: Icons.person_outline,
    filledIcon: Icons.person_rounded,
    labelKey: 'nav.profile',
    labelFallback: 'Profile',
  ),
];

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
          child: _NavBarContent(
            currentIndex: currentIndex,
            onTap: onTap,
            onCenterTap: onCenterTap,
            avatarUrl: avatarUrl,
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

  static void _showProfileMenu(BuildContext context) {
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
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
                leading:
                    Icon(Icons.group_add_outlined, color: textPrimary),
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
                leading: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'auth.logout'.tr,
                  style: const TextStyle(color: Colors.redAccent),
                ),
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

  static void _showLogoutConfirm(
      BuildContext context, AuthController authController) {
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
            child: Text(
              'auth.logout'.tr,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal Navigation Content (Glass Pill + Capsule + Separate +) ──────────
class _NavBarContent extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;
  final String? avatarUrl;

  const _NavBarContent({
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
    this.avatarUrl,
  });

  @override
  State<_NavBarContent> createState() => _NavBarContentState();
}

class _NavBarContentState extends State<_NavBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  double _fromPos = 0.0;
  double _toPos = 0.0;

  @override
  void initState() {
    super.initState();
    _fromPos = widget.currentIndex.toDouble();
    _toPos = widget.currentIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.2, 0.0, 0.2, 1.0),
    );
    _ctrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(_NavBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromPos = currentPos;
      _toPos = widget.currentIndex.toDouble();
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get currentPos {
    final t = _anim.value.clamp(0.0, 1.0);
    final val = lerpDouble(_fromPos, _toPos, t) ?? _toPos;
    return val.clamp(0.0, (_kTabs.length - 1).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semanticColors = AppSemanticColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final isVeryNarrow = totalWidth < 340;
        final isNarrow = totalWidth < 370;

        final horizontalMargin = isVeryNarrow ? 10.0 : (isNarrow ? 14.0 : 16.0);
        final safeBottom = MediaQuery.of(context).padding.bottom;
        final bottomMargin = safeBottom > 0 ? safeBottom + 4.0 : 16.0;

        // Heights
        final barHeight = isVeryNarrow ? 60.0 : (isNarrow ? 62.0 : 64.0);
        final capsulePaddingH = isVeryNarrow ? 6.0 : (isNarrow ? 7.0 : 8.0);
        final capsulePaddingV = isVeryNarrow ? 6.0 : (isNarrow ? 6.5 : 7.0);

        // Plus button sizing
        final plusSize = isVeryNarrow ? 44.0 : 48.0;
        final plusIconSize = isVeryNarrow ? 20.0 : (isNarrow ? 21.0 : 22.0);
        final plusGap = isVeryNarrow ? 8.0 : 10.0;

        // Content sizes
        final iconSize = isVeryNarrow ? 20.0 : (isNarrow ? 21.0 : 22.0);
        final fontSize = isVeryNarrow ? 9.5 : (isNarrow ? 10.0 : 10.0);

        // Outer glass capsule styling — ONE continuous glass/frosted surface
        final pillBg = isDark
            ? const Color(0xCC121418) // rich translucent dark glass
            : const Color(0xCCFFFFFF); // crisp translucent frosted light glass
        final pillBorder = isDark
            ? const Color(0x2EFFFFFF) // subtle luminous glass highlight
            : const Color(0x1F000000); // 12% hairline border
        final pillShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.80),
            blurRadius: 1,
            offset: const Offset(0, -0.5),
          ),
        ];

        // Active glass indicator — INNER GLASS HIGHLIGHT inside outer glass capsule
        final capsuleBg = isDark
            ? const Color(0x24FFFFFF) // 14% luminous frosted white highlight on dark glass
            : const Color(0x52FFFFFF); // 32% clean translucent frosted white highlight
        final capsuleBorder = isDark
            ? const Color(0x38FFFFFF) // subtle luminous glass rim
            : const Color(0x66FFFFFF); // delicate white light-catch rim border
        final capsuleShadow = [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.50),
            blurRadius: 1,
            offset: const Offset(0, -0.5),
          ),
        ];

        // Active & Inactive colors from Design System
        final activeIconColor = semanticColors.navigationActiveIcon;
        final activeLabelColor = semanticColors.navigationActiveLabel;
        final inactiveIconColor = semanticColors.navigationInactiveIcon;
        final inactiveLabelColor = semanticColors.navigationInactiveLabel;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalMargin,
                0,
                horizontalMargin,
                bottomMargin,
              ),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Main Glass Pill Bar with 4 tabs ─────────────
                    Expanded(
                      child: SizedBox(
                        height: barHeight,
                        child: DecoratedBox(
                          key: const ValueKey('nav_outer_capsule'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            boxShadow: pillShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20.0,
                                sigmaY: 20.0,
                              ),
                              child: Container(
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius:
                                      BorderRadius.circular(barHeight / 2),
                                  border: Border.all(
                                    color: pillBorder,
                                    width: 1.0,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: capsulePaddingH,
                                  vertical: capsulePaddingV,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    final usableWidth =
                                        innerConstraints.maxWidth;
                                    final usableHeight =
                                        innerConstraints.maxHeight;
                                    final slotWidth =
                                        usableWidth / _kTabs.length;

                                    // Active indicator dimensions — natural inner glass highlight
                                    const indicatorVInset = 2.0; // 2.0px gap top + bottom
                                    final indicatorHInset =
                                        isVeryNarrow ? 2.5 : 3.5; // balanced horizontal padding
                                    final indicatorWidth = (slotWidth -
                                            indicatorHInset * 2)
                                        .clamp(0.0, slotWidth);
                                    final indicatorHeight =
                                        usableHeight - indicatorVInset * 2;
                                    // Smooth stadium pill matching outer capsule curves
                                    final indicatorRadius =
                                        BorderRadius.circular(
                                            indicatorHeight / 2);

                                    final pos = currentPos;
                                    final indicatorLeft = pos * slotWidth +
                                        indicatorHInset;

                                    return SizedBox(
                                      width: usableWidth,
                                      height: usableHeight,
                                      child: Stack(
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          // ── Layer 1: ONE Shared Sliding Active Glass Capsule ──
                                          // Fully contained inside the capsule with breathing room
                                          Positioned(
                                            left: indicatorLeft,
                                            top: indicatorVInset,
                                            width: indicatorWidth,
                                            height: indicatorHeight,

                                            child: DecoratedBox(
                                              key: const ValueKey(
                                                  'nav_active_indicator'),
                                              decoration: BoxDecoration(
                                                borderRadius: indicatorRadius,
                                                boxShadow: capsuleShadow,
                                              ),
                                              child: ClipRRect(
                                                borderRadius: indicatorRadius,
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: isDark ? 8.0 : 6.0,
                                                    sigmaY: isDark ? 8.0 : 6.0,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: capsuleBg,
                                                      borderRadius:
                                                          indicatorRadius,
                                                      border: Border.all(
                                                        color: capsuleBorder,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // ── Layer 2: 4 Navigation Slots (Icon + Label) ──
                                          Positioned.fill(
                                            child: Row(
                                              children: List.generate(
                                                  _kTabs.length, (i) {
                                                final dist = (pos - i).abs();
                                                final weight = (1.0 - dist)
                                                    .clamp(0.0, 1.0);
                                                return _TabItem(
                                                  tab: _kTabs[i],
                                                  isSelected:
                                                      widget.currentIndex == i,
                                                  activeWeight: weight,
                                                  iconSize: iconSize,
                                                  fontSize: fontSize,
                                                  activeIconColor:
                                                      activeIconColor,
                                                  activeLabelColor:
                                                      activeLabelColor,
                                                  inactiveIconColor:
                                                      inactiveIconColor,
                                                  inactiveLabelColor:
                                                      inactiveLabelColor,
                                                  onTap: () => widget.onTap(i),
                                                  onLongPress: i == 3
                                                      ? () => BottomNavBar
                                                          ._showProfileMenu(
                                                              context)
                                                      : null,
                                                  avatarUrl: widget.avatarUrl,
                                                  isProfile: i == 3,
                                                  isVeryNarrow: isVeryNarrow,
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: plusGap),

                    // ── Separate + button on the RIGHT ──────────────
                    _PlusButton(
                      size: plusSize,
                      iconSize: plusIconSize,
                      isDark: isDark,
                      onTap: widget.onCenterTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Individual tab item (Icon + Label centered as one group) ────────────────
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.activeWeight,
    required this.iconSize,
    required this.fontSize,
    required this.activeIconColor,
    required this.activeLabelColor,
    required this.inactiveIconColor,
    required this.inactiveLabelColor,
    required this.onTap,
    this.onLongPress,
    this.avatarUrl,
    required this.isProfile,
    required this.isVeryNarrow,
  });

  final _TabDef tab;
  final bool isSelected;
  final double activeWeight; // 0.0 → 1.0 from capsule proximity
  final double iconSize;
  final double fontSize;
  final Color activeIconColor;
  final Color activeLabelColor;
  final Color inactiveIconColor;
  final Color inactiveLabelColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? avatarUrl;
  final bool isProfile;
  final bool isVeryNarrow;

  @override
  Widget build(BuildContext context) {
    final labelText = BottomNavBar._label(
      tab.labelKey,
      tab.labelFallback,
    );
    final iconColor = Color.lerp(
      inactiveIconColor,
      activeIconColor,
      activeWeight,
    )!;
    final labelColor = Color.lerp(
      inactiveLabelColor,
      activeLabelColor,
      activeWeight,
    )!;
    final showActive = isSelected
        ? activeWeight >= 0.35
        : activeWeight > 0.65;

    final Widget iconWidget =
        (isProfile && avatarUrl != null && avatarUrl!.isNotEmpty)
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor,
                    width: showActive ? 1.8 : 1.4,
                  ),
                ),
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  size: iconSize,
                ),
              )
            : Icon(
                showActive ? tab.filledIcon : tab.outlineIcon,
                size: iconSize,
                color: iconColor,
                semanticLabel: labelText,
              );

    return Expanded(
      child: Semantics(
        button: true,
        label: labelText,
        selected: isSelected,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: onLongPress,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean stable icon with intentional visual weight
                iconWidget,
                const SizedBox(height: 2.0), // compact: icon+label as one group
                // Label contained comfortably inside active indicator
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryNarrow ? 4.0 : 6.0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      labelText,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight:
                            showActive ? FontWeight.w600 : FontWeight.w500,
                        fontSize: fontSize,
                        letterSpacing: showActive ? -0.15 : -0.1,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── + Button (Separate on Right) ─────────────────────────────────────────────
class _PlusButton extends StatefulWidget {
  final double size;
  final double iconSize;
  final bool isDark;
  final VoidCallback? onTap;

  const _PlusButton({
    required this.size,
    required this.iconSize,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _press.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFFF0F2F5) : const Color(0xFF141517);
    final iconColor = widget.isDark ? const Color(0xFF141517) : Colors.white;
    final border = widget.isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x1F000000);

    return Semantics(
      button: true,
      label: 'nav.create'.tr,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark
                      ? const Color(0x52000000)
                      : const Color(0x29000000),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _handleTap,
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: widget.iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

