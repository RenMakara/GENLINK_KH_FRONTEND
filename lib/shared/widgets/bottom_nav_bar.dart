import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/widgets/avatar/app_avatar.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../main_controller.dart';

// ═══════════════════════════════════════════════════════════════════════
//  BOTTOM NAV BAR — Moving Glass Active Item
// ═══════════════════════════════════════════════════════════════════════
//
//  Architecture (3 layers in a Stack):
//
//  Layer 1 — Fixed glass bar (background pill)
//  Layer 2 — 4 static inactive tabs (outline icons, opaque bkg)
//             Tappable. Icon of the currently-active slot is hidden
//             so the moving active item on Layer 3 is the sole visible
//             content for that slot.
//  Layer 3 — ONE animated Positioned widget that travels horizontally:
//               ┌ GlassCapsule ─────────────────────┐
//               │  ActiveIcon (filled)               │
//               │  ActiveLabel                       │
//               └────────────────────────────────────┘
//             The icon and label switch (with AnimatedSwitcher crossfade)
//             at the midpoint of each transition so they appear to "arrive"
//             at the destination slot together with the glass.
//
//  The + button is completely separate (to the right, fixed).
// ═══════════════════════════════════════════════════════════════════════

// ─── Tab definition ──────────────────────────────────────────────────
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
    outlineIcon: Icons.emoji_events_outlined,
    filledIcon: Icons.emoji_events_rounded,
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
    outlineIcon: Icons.person_outline_rounded,
    filledIcon: Icons.person_rounded,
    labelKey: 'nav.profile',
    labelFallback: 'Profile',
  ),
];

// ─── Public widget ────────────────────────────────────────────────────
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

  static String _tr(String key, String fallback) {
    final v = key.tr;
    return (v.isNotEmpty && v != key) ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final mainCtrl =
        Get.isRegistered<MainController>() ? Get.find<MainController>() : null;
    final authCtrl =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    Widget buildBar(bool visible, String? avatarUrl) {
      return AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: _NavBarContent(
            currentIndex: currentIndex,
            onTap: onTap,
            onCenterTap: onCenterTap,
            avatarUrl: avatarUrl,
          ),
        ),
      );
    }

    if (mainCtrl == null && authCtrl == null) return buildBar(true, null);

    return Obx(() {
      final visible = mainCtrl?.isNavBarVisible.value ?? true;
      final user = authCtrl?.currentUser.value;
      return buildBar(visible, user?.avatarUrl);
    });
  }

  // ── Profile long-press menu (unchanged) ───────────────────────────
  static void showProfileMenu(BuildContext context) {
    final authCtrl = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
                    color: isDark
                        ? AppColors.darkBorderStrong
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.group_add_outlined, color: textPrimary),
                title: Text('auth.switchAccount'.tr),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.showSnackbar(const GetSnackBar(
                    message: 'Coming soon',
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
              if (authCtrl != null)
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded,
                      color: Colors.redAccent),
                  title: Text('auth.logout'.tr,
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLogoutConfirm(context, authCtrl);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showLogoutConfirm(
      BuildContext context, AuthController authCtrl) {
    Get.dialog(AlertDialog(
      title: Text('auth.logout'.tr),
      content: Text('auth.logoutConfirm'.tr),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: Text('common.cancel'.tr)),
        TextButton(
          onPressed: () {
            Get.back();
            authCtrl.logout();
          },
          child: Text('auth.logout'.tr,
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    ));
  }
}

// ─── Internal stateful bar ────────────────────────────────────────────
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
  // ── Animation state ───────────────────────────────────────────────
  late final AnimationController _ctrl;

  // _fromPos / _toPos are fractional tab indices (0.0, 1.0, 2.0, 3.0).
  double _fromPos = 0.0;
  double _toPos = 0.0;

  // Which tab's icon + label the glass currently shows.
  // Switches to widget.currentIndex at animation midpoint.
  int _displayedIndex = 0;

  // ── Helpers ───────────────────────────────────────────────────────
  static String _tr(String key, String fallback) =>
      BottomNavBar._tr(key, fallback);

  double get _curPos {
    final t = Curves.easeOutCubic.transform(_ctrl.value);
    return lerpDouble(_fromPos, _toPos, t)!;
  }

  // Given bar-content width and center-button width, returns the X centre
  // of each of the 4 tab slots.
  //
  // Row layout:  [Tab0 flex] [Tab1 flex] [CenterBtn fixed] [Tab2 flex] [Tab3 flex]
  static List<double> _tabCenters(double barW, double centerBtnW) {
    final tabW = (barW - centerBtnW) / 4.0;
    return [
      tabW * 0.5,                              // Tab 0
      tabW * 1.5,                              // Tab 1
      tabW * 2.0 + centerBtnW + tabW * 0.5,   // Tab 2
      tabW * 2.0 + centerBtnW + tabW * 1.5,   // Tab 3
    ];
  }

  // ── Lifecycle ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fromPos = widget.currentIndex.toDouble();
    _toPos = widget.currentIndex.toDouble();
    _displayedIndex = widget.currentIndex;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )
      ..value = 1.0 // "completed" — _curPos == _toPos immediately
      ..addListener(_onTick);
  }

  void _onTick() {
    // Switch the icon + label at the animation midpoint so the content
    // appears to "arrive" at the destination together with the glass.
    final t = Curves.easeOutCubic.transform(_ctrl.value);
    if (t >= 0.5 && _displayedIndex != widget.currentIndex) {
      setState(() => _displayedIndex = widget.currentIndex);
    }
  }

  @override
  void didUpdateWidget(_NavBarContent old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _fromPos = _curPos; // continue from wherever the glass currently is
      _toPos = widget.currentIndex.toDouble();
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      final isVN = totalW < 340;
      final isN = totalW < 370;

      // Sizing
      final hMargin = isVN ? 10.0 : (isN ? 14.0 : 16.0);
      final safeB = MediaQuery.of(context).padding.bottom;
      final bottomM = safeB > 0 ? safeB + 4.0 : 16.0;
      final barH = isVN ? 56.0 : 58.0;
      final centerBtnSz = isVN ? 44.0 : 48.0;
      final plusGap = isVN ? 8.0 : 10.0;
      final iconSz = isVN ? 20.0 : (isN ? 21.0 : 22.0);
      final fontSize = isVN ? 9.5 : (isN ? 10.0 : 10.5);

      // Active glass capsule protrudes above the bar to create a floating lens.
      const topProtrusion = 9.0;
      const bottomProtrusion = 5.0;
      final capH = barH + topProtrusion + bottomProtrusion;

      // Bar content width (inside horizontal margins, excluding + button gap & button)
      final barContentW = totalW - hMargin * 2 - plusGap - centerBtnSz;
      final centers = _tabCenters(barContentW, 0 /* no center btn inside bar */);

      // Capsule width: fits comfortably in one tab slot
      final tabSlotW = barContentW / _kTabs.length;
      final capW = (tabSlotW - (isVN ? 4.0 : 6.0)).clamp(54.0, 76.0);
      const capRadius = Radius.circular(24.0);

      // Colors
      final barBg = isDark
          ? const Color(0xB8121418)
          : const Color(0xCCF7F9FC);
      final barBorder = isDark
          ? const Color(0x22FFFFFF)
          : const Color(0x18000000);
      final barShadow = [
        BoxShadow(
          color: isDark ? const Color(0x52000000) : const Color(0x14000000),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: isDark ? const Color(0x2E000000) : const Color(0x0A000000),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
      final inactiveColor = isDark
          ? const Color(0x75FFFFFF)
          : const Color(0x66141517);
      final activeColor = isDark ? Colors.white : const Color(0xFF141517);

      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.fromLTRB(hMargin, 0, hMargin, bottomM),
            child: SizedBox(
              height: capH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Main glass bar  ──────────────────────────────
                  Expanded(
                    child: SizedBox(
                      height: capH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ─ Layer 1: Fixed glass pill bar ─────────
                          Positioned(
                            left: 0,
                            right: 0,
                            top: topProtrusion,
                            height: barH,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(barH / 2),
                                boxShadow: barShadow,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(barH / 2),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: barBg,
                                      borderRadius:
                                          BorderRadius.circular(barH / 2),
                                      border: Border.all(
                                          color: barBorder, width: 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ─ Layer 2: Static inactive tabs ─────────
                          // Each tab shows ONLY its outline icon.
                          // The slot whose index == _displayedIndex has its
                          // icon hidden (opacity 0) because the moving glass
                          // covers it with the filled version.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: topProtrusion,
                            height: barH,
                            child: Row(
                              children: List.generate(_kTabs.length, (i) {
                                final tab = _kTabs[i];
                                final isHidden = i == _displayedIndex;
                                return Expanded(
                                  child: Semantics(
                                    button: true,
                                    label: _tr(
                                        tab.labelKey, tab.labelFallback),
                                    selected: widget.currentIndex == i,
                                    excludeSemantics: true,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        widget.onTap(i);
                                      },
                                      onLongPress: i == 3
                                          ? () => BottomNavBar
                                              .showProfileMenu(context)
                                          : null,
                                      child: Center(
                                        child: AnimatedOpacity(
                                          opacity: isHidden ? 0.0 : 1.0,
                                          duration: const Duration(
                                              milliseconds: 160),
                                          child: _StaticTabIcon(
                                            tab: tab,
                                            avatarUrl:
                                                i == 3
                                                    ? widget.avatarUrl
                                                    : null,
                                            color: inactiveColor,
                                            size: iconSz,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // ─ Layer 3: Moving glass active item ─────
                          // ONE Positioned widget that travels horizontally.
                          // Contains: glass capsule + filled icon + label.
                          AnimatedBuilder(
                            animation: _ctrl,
                            builder: (context, _) {
                              // Interpolated fractional tab position
                              final pos = _curPos.clamp(0.0, 3.0);
                              final idxF = pos.floor();
                              final frac = pos - idxF;
                              final i0 = idxF.clamp(0, 2);
                              final i1 = (i0 + 1).clamp(0, 3);

                              // Stretch effect: capsule widens slightly
                              // during fast travel, then snaps back.
                              final travelDist =
                                  (_toPos - _fromPos).abs();
                              final stretch = (travelDist * 7.0)
                                      .clamp(0.0, 14.0) *
                                  math.sin((_ctrl.value * math.pi)
                                      .clamp(0.0, math.pi));
                              final currentCapW = capW + stretch;

                              // Horizontal centre of the glass
                              final cx = lerpDouble(
                                  centers[i0], centers[i1], frac)!;

                              return Positioned(
                                left: cx - currentCapW / 2,
                                top: 0,
                                width: currentCapW,
                                height: capH,
                                child: _MovingGlassItem(
                                  isDark: isDark,
                                  capRadius: capRadius,
                                  capH: capH,
                                  displayedIndex: _displayedIndex,
                                  avatarUrl: widget.avatarUrl,
                                  activeColor: activeColor,
                                  iconSize: iconSz,
                                  fontSize: fontSize,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: plusGap),

                  // ── Separate + button ─────────────────────────────
                  _SeparatePlusButton(
                    size: centerBtnSz,
                    iconSize: isVN ? 24.0 : 26.0,
                    onTap: widget.onCenterTap,
                    tooltip: _tr('nav.create', 'Create'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Static inactive tab icon ─────────────────────────────────────────
// Shows the outline (inactive) icon for a slot.
// For profile (index 3) shows avatar when provided, else outline person.
class _StaticTabIcon extends StatelessWidget {
  final _TabDef tab;
  final String? avatarUrl;
  final Color color;
  final double size;

  const _StaticTabIcon({
    required this.tab,
    required this.avatarUrl,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: size + 2,
        height: size + 2,
        child: ClipOval(
          child: AppAvatar(imageUrl: avatarUrl, size: size + 2),
        ),
      );
    }
    return Icon(tab.outlineIcon, size: size, color: color);
  }
}

// ─── Moving glass active item ─────────────────────────────────────────
// The ONE object that travels between tab slots.
// Contains: glass capsule shell + filled icon + active label.
// The icon + label switch via AnimatedSwitcher at the midpoint of each
// transition (_displayedIndex changes in the state).
class _MovingGlassItem extends StatelessWidget {
  final bool isDark;
  final Radius capRadius;
  final double capH;
  final int displayedIndex;
  final String? avatarUrl;
  final Color activeColor;
  final double iconSize;
  final double fontSize;

  const _MovingGlassItem({
    required this.isDark,
    required this.capRadius,
    required this.capH,
    required this.displayedIndex,
    required this.avatarUrl,
    required this.activeColor,
    required this.iconSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final tab = _kTabs[displayedIndex];
    final label = BottomNavBar._tr(tab.labelKey, tab.labelFallback);

    // ── Glass capsule appearance ─────────────────────────────────────
    // Dark-tinted translucent glass in both light and dark mode.
    // Light mode: dark glass lens on white bar (premium, high contrast).
    // Dark mode:  frosted lighter glass on dark bar.
    final glassFill = isDark
        ? const Color(0x3CFFFFFF)   // white 24% on dark
        : const Color(0xE8111111);  // black 91% on light (dark glass capsule)
    final glassBorder = isDark
        ? const Color(0x50FFFFFF)   // white 31%
        : const Color(0x28111111);  // black 16%
    final capsuleShadow = [
      BoxShadow(
        color: isDark ? const Color(0x66000000) : const Color(0x44000000),
        blurRadius: 14,
        offset: const Offset(0, 5),
        spreadRadius: -2,
      ),
      // Top rim specular gleam
      BoxShadow(
        color: isDark ? const Color(0x28FFFFFF) : const Color(0x55FFFFFF),
        blurRadius: 4,
        offset: const Offset(0, -1),
      ),
    ];

    // Icon + label always white on the dark glass capsule.
    const contentColor = Colors.white;

    // ── Icon widget (switches with AnimatedSwitcher at midpoint) ────
    Widget iconWidget;
    if (displayedIndex == 3 && avatarUrl != null && avatarUrl!.isNotEmpty) {
      iconWidget = Container(
        key: ValueKey('avatar_$avatarUrl'),
        width: iconSize + 2,
        height: iconSize + 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: contentColor, width: 1.5),
        ),
        child: ClipOval(
            child: AppAvatar(imageUrl: avatarUrl, size: iconSize + 2)),
      );
    } else {
      iconWidget = Icon(
        tab.filledIcon,
        key: ValueKey(displayedIndex),
        size: iconSize,
        color: contentColor,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(capRadius),
        boxShadow: capsuleShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(capRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: capH,
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: BorderRadius.all(capRadius),
              border: Border.all(color: glassBorder, width: 0.8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Filled icon ───────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: iconWidget,
                ),

                const SizedBox(height: 2.5),

                // ── Active label ──────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    label,
                    key: ValueKey('label_$displayedIndex'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                      letterSpacing: -0.1,
                      height: 1.15,
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

// ─── Separate + button ────────────────────────────────────────────────
class _SeparatePlusButton extends StatefulWidget {
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isDark;

  const _SeparatePlusButton({
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.tooltip,
    required this.isDark,
  });

  @override
  State<_SeparatePlusButton> createState() => _SeparatePlusButtonState();
}

class _SeparatePlusButtonState extends State<_SeparatePlusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
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
    final bg = widget.isDark
        ? const Color(0xFFF0F2F5)
        : const Color(0xFF18191B);
    final icon = widget.isDark ? const Color(0xFF141517) : Colors.white;
    final border = widget.isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x1F000000);

    return Semantics(
      button: true,
      label: widget.tooltip,
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
                child:
                    Center(child: Icon(Icons.add_rounded, size: widget.iconSize, color: icon)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
