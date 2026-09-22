import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/widgets/avatar/app_avatar.dart';
import '../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/community/presentation/controllers/community_controller.dart';
import '../../features/community/presentation/widgets/community_creation_flow.dart';
import '../../features/finance/presentation/controllers/finance_controller.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
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
    outlineIcon: Icons.person_outline,
    filledIcon: Icons.person_rounded,
    labelKey: 'nav.profile',
    labelFallback: 'Profile',
  ),
];

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ValueChanged<int>? onDoubleTapActive;
  final VoidCallback? onCenterTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onDoubleTapActive,
    this.onCenterTap,
  });

  static final Set<int> _defaultRefreshingTabs = <int>{};

  /// Default handler for double tapping an already active tab:
  /// smoothly scrolls to top if a scroll controller/position exists and triggers refresh.
  static Future<void> defaultOnDoubleTapActive(int index) async {
    if (_defaultRefreshingTabs.contains(index)) return;
    _defaultRefreshingTabs.add(index);
    try {
      if (index == 0 && Get.isRegistered<CommunityController>()) {
        final c = Get.find<CommunityController>();
        final hasScrolledPosition = c.scrollController.hasClients &&
            c.scrollController.positions.any((position) => position.pixels > 0);
        if (hasScrolledPosition) {
          await c.scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
        await c.refreshFeed();
      } else if (index == 1 && Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().reload();
      } else if (index == 2 && Get.isRegistered<FinanceController>()) {
        await Get.find<FinanceController>().reload();
      } else if (index == 3 && Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().reload();
      }
    } catch (_) {
      // Safe fallback
    } finally {
      _defaultRefreshingTabs.remove(index);
    }
  }

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
            onDoubleTapActive: onDoubleTapActive,
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
    BuildContext context,
    AuthController authController,
  ) async {
    final confirmed = await GenLinkConfirmDialog.showLogout(context: context);
    if (confirmed) {
      authController.logout();
    }
  }
}

// ─── Internal Navigation Content (Glass Pill + Capsule + Separate +) ──────────
class _NavBarContent extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ValueChanged<int>? onDoubleTapActive;
  final VoidCallback? onCenterTap;
  final String? avatarUrl;

  const _NavBarContent({
    required this.currentIndex,
    required this.onTap,
    this.onDoubleTapActive,
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
  DateTime? _lastActiveTapTime;
  int? _lastActiveTapIndex;
  static const Duration _kDoubleTapInterval = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _fromPos = widget.currentIndex.toDouble();
    _toPos = widget.currentIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(_NavBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _lastActiveTapTime = null;
      _lastActiveTapIndex = null;
      _fromPos = currentPos;
      _toPos = widget.currentIndex.toDouble();
      _ctrl.forward(from: 0.0);
    }
  }

  void _handleTabTap(int i) {
    if (i != widget.currentIndex) {
      // Inactive tab tapped: immediate normal navigation, clear double-tap tracker
      _lastActiveTapTime = null;
      _lastActiveTapIndex = null;
      widget.onTap(i);
      return;
    }

    // Active tab tapped
    final now = DateTime.now();
    if (_lastActiveTapIndex == i &&
        _lastActiveTapTime != null &&
        now.difference(_lastActiveTapTime!) <= _kDoubleTapInterval) {
      // Confirmed double tap on already active tab!
      _lastActiveTapTime = null;
      _lastActiveTapIndex = null;
      HapticFeedback.mediumImpact();
      if (widget.onDoubleTapActive != null) {
        widget.onDoubleTapActive!(i);
      } else {
        BottomNavBar.defaultOnDoubleTapActive(i);
      }
      return;
    }

    // First tap on active tab: normal behavior
    _lastActiveTapTime = now;
    _lastActiveTapIndex = i;
    widget.onTap(i);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get currentPos {
    return lerpDouble(_fromPos, _toPos, _anim.value) ?? _toPos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaQuery.size.width;

        // Device size tiers based on available layout width
        final isVeryNarrow = totalWidth < 345;
        final isNarrow = totalWidth < 375;

        // Safe area insets
        final safePadding = mediaQuery.padding;
        final safeLeft = safePadding.left;
        final safeRight = safePadding.right;
        final safeBottom = safePadding.bottom;

        // Dynamic horizontal padding with safe area respect
        final baseHorizontal = isVeryNarrow ? 10.0 : (isNarrow ? 13.0 : 16.0);
        final leftPadding = safeLeft > 0 ? safeLeft + 8.0 : baseHorizontal;
        final rightPadding = safeRight > 0 ? safeRight + 8.0 : baseHorizontal;

        // Dynamic bottom margin respecting home indicator / system nav
        final bottomMargin = safeBottom > 0 ? safeBottom + 4.0 : 16.0;

        // Bar heights
        final barHeight = isVeryNarrow ? 62.0 : (isNarrow ? 65.0 : 68.0);
        final totalBarHeight = barHeight;

        // Plus button sizing
        final plusSize = isVeryNarrow ? 44.0 : (isNarrow ? 47.0 : 48.0);
        final plusIconSize = isVeryNarrow ? 20.0 : (isNarrow ? 21.0 : 22.0);
        final plusGap = isVeryNarrow ? 8.0 : 10.0;

        // Content sizes
        final iconSize = isVeryNarrow ? 20.0 : (isNarrow ? 21.5 : 22.0);
        final fontSize = isVeryNarrow ? 9.5 : (isNarrow ? 10.0 : 10.5);

        // Glass bar styling — iOS Liquid Glass material
        final pillSurfaceGradient = isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x281C2028), // deep translucent charcoal with optical depth
                  Color(0x18090B0E), // translucent charcoal base
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x75FFFFFF), // translucent frosted white glass
                  Color(0x4AFFFFFF),
                ],
              );
        final pillBorder = isDark
            ? const Color(0x18FFFFFF) // subtle translucent glass rim
            : const Color(0x22000000); // subtle neutral rim
        final pillShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: isDark ? 28 : 24,
            offset: Offset(0, isDark ? 8 : 8),
            spreadRadius: isDark ? -4 : -3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];

        // Active glass lens — floating glass capsule catching light
        final capsuleShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -1,
          ),
        ];

        // Text / Icon colors — strictly neutral monochrome (no feature colors)
        final iconColor =
            isDark ? Colors.white : const Color(0xFF121212);
        final activeLabelColor =
            isDark ? Colors.white : const Color(0xFF121212);
        final inactiveLabelColor =
            isDark ? const Color(0x8AFFFFFF) : const Color(0x8A121212);

        // Scaffold gives a bottomNavigationBar loose height constraints. Keep
        // this slot limited to the actual bar plus its safe-area margin so a
        // floating SnackBar can calculate a visible position above it.
        return SizedBox(
          height: totalBarHeight + bottomMargin,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  0,
                  rightPadding,
                  bottomMargin,
                ),
                child: SizedBox(
                  height: totalBarHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Main Glass Pill Bar with 4 tabs ─────────────
                      Expanded(
                        child: SizedBox(
                          height: totalBarHeight,
                          child: LayoutBuilder(
                            builder: (context, barConstraints) {
                              final barWidth = barConstraints.maxWidth;
                              final slotWidth = barWidth / _kTabs.length;

                              // Responsive active glass lens dimensions
                              final horizontalInset =
                                  (slotWidth * 0.08).clamp(3.5, 6.0);
                              final capsuleWidth =
                                  slotWidth - (horizontalInset * 2);
                              final verticalInset =
                                  (barHeight * 0.11).clamp(6.0, 8.5);
                              final capsuleHeight =
                                  barHeight - (verticalInset * 2);
                              final capsuleRadius =
                                  Radius.circular(capsuleHeight / 2);

                              final pos = currentPos;
                              final capsuleCenter = (pos + 0.5) * slotWidth;
                              final capsuleLeft =
                                  capsuleCenter - capsuleWidth / 2;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Layer 1: Fixed Glass Pill Background
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    height: barHeight,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          barHeight / 2,
                                        ),
                                        boxShadow: pillShadow,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          barHeight / 2,
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 26,
                                            sigmaY: 26,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: pillSurfaceGradient,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                barHeight / 2,
                                              ),
                                              border: Border.all(
                                                color: pillBorder,
                                                width: 0.75,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Subtle specular highlight across upper surface of the glass
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  right: 0,
                                                  height: barHeight * 0.46,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          barHeight / 2,
                                                        ),
                                                      ),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: isDark
                                                            ? [
                                                                const Color(
                                                                  0x10FFFFFF,
                                                                ),
                                                                const Color(
                                                                  0x00FFFFFF,
                                                                ),
                                                              ]
                                                            : [
                                                                const Color(
                                                                  0x65FFFFFF,
                                                                ),
                                                                const Color(
                                                                  0x00FFFFFF,
                                                                ),
                                                              ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Layer 2: ONE Shared Sliding Active Glass Lens (wrapped in IgnorePointer)
                                  Positioned(
                                    left: capsuleLeft,
                                    top: verticalInset,
                                    width: capsuleWidth,
                                    height: capsuleHeight,
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            capsuleRadius,
                                          ),
                                          boxShadow: capsuleShadow,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.all(
                                            capsuleRadius,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 18,
                                              sigmaY: 18,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: isDark
                                                      ? [
                                                          const Color(0x1AFFFFFF),
                                                          const Color(0x06FFFFFF),
                                                        ]
                                                      : [
                                                          const Color(0x9AFFFFFF),
                                                          const Color(0x50FFFFFF),
                                                        ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.all(
                                                  capsuleRadius,
                                                ),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0x20FFFFFF)
                                                      : const Color(0x24000000),
                                                  width: 0.75,
                                                ),
                                              ),
                                              child: Stack(
                                                children: [
                                                  // Soft inner specular highlight (liquid glass reflection arc)
                                                  Positioned(
                                                    top: 0,
                                                    left: 0,
                                                    right: 0,
                                                    height: capsuleHeight * 0.46,
                                                    child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                          top: capsuleRadius,
                                                        ),
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: isDark
                                                              ? [
                                                                  const Color(
                                                                    0x12FFFFFF,
                                                                  ),
                                                                  const Color(
                                                                    0x00FFFFFF,
                                                                  ),
                                                                ]
                                                              : [
                                                                  const Color(
                                                                    0x75FFFFFF,
                                                                  ),
                                                                  const Color(
                                                                    0x00FFFFFF,
                                                                  ),
                                                                ],
                                                        ),
                                                      ),
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

                                  // Layer 3: 4 Tab Items (Strictly Monochrome Icons + Labels)
                                  // Each _TabItem has its own spring-bounce
                                  // animation that triggers when it becomes active.
                                  Positioned.fill(
                                    child: Row(
                                      children: List.generate(_kTabs.length, (
                                        i,
                                      ) {
                                        final dist = (pos - i).abs();
                                        final weight = (1.0 - dist).clamp(
                                          0.0,
                                          1.0,
                                        );
                                        return _TabItem(
                                          tab: _kTabs[i],
                                          isSelected: widget.currentIndex == i,
                                          activeWeight: weight,
                                          iconSize: iconSize,
                                          fontSize: fontSize,
                                          iconColor: iconColor,
                                          activeLabelColor: activeLabelColor,
                                          inactiveLabelColor: inactiveLabelColor,
                                          onTap: () => _handleTabTap(i),
                                          onLongPress: i == 3
                                              ? () =>
                                                    BottomNavBar._showProfileMenu(
                                                      context,
                                                    )
                                              : null,
                                          avatarUrl: widget.avatarUrl,
                                          isProfile: i == 3,
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              );
                            },
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
          ),
        );
      },
    );
  }
}

// ─── Individual tab item with spring-bounce on activation ────────────────────
class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.activeWeight,
    required this.iconSize,
    required this.fontSize,
    required this.iconColor,
    required this.activeLabelColor,
    required this.inactiveLabelColor,
    required this.onTap,
    this.onLongPress,
    this.avatarUrl,
    required this.isProfile,
  });

  final _TabDef tab;
  final bool isSelected;
  final double activeWeight; // 0.0 → 1.0 from capsule proximity
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color activeLabelColor;
  final Color inactiveLabelColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? avatarUrl;
  final bool isProfile;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    // Spring sequence: grow → overshoot → settle
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.30,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.30,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(_TabItem old) {
    super.didUpdateWidget(old);
    // Fire bounce when this tab becomes the newly selected one
    if (!old.isSelected && widget.isSelected) {
      _bounce.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelText = BottomNavBar._label(
      widget.tab.labelKey,
      widget.tab.labelFallback,
    );
    final labelColor = Color.lerp(
      widget.inactiveLabelColor,
      widget.activeLabelColor,
      widget.activeWeight,
    )!;
    final showActive = widget.isSelected || widget.activeWeight > 0.5;

    final Widget iconWidget =
        (widget.isProfile &&
            widget.avatarUrl != null &&
            widget.avatarUrl!.isNotEmpty)
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.iconColor, width: 1.5),
            ),
            child: AppAvatar(imageUrl: widget.avatarUrl, size: widget.iconSize),
          )
        : Icon(
            showActive ? widget.tab.filledIcon : widget.tab.outlineIcon,
            size: widget.iconSize,
            color: widget.iconColor,
            semanticLabel: labelText,
          );

    return Expanded(
      child: Semantics(
        button: true,
        label: labelText,
        selected: widget.isSelected,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, -0.5 * widget.activeWeight), // subtle lift only
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with combined weight-scale + spring-bounce
                  AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (context, child) {
                      final weightScale = 1.0 + 0.08 * widget.activeWeight;
                      final springScale = _bounce.isAnimating
                          ? _bounceAnim.value
                          : 1.0;
                      return Transform.scale(
                        scale: weightScale * springScale,
                        child: child,
                      );
                    },
                    child: iconWidget,
                  ),
                  const SizedBox(height: 4.0),
                  // Label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labelText,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        textScaler: MediaQuery.textScalerOf(context).clamp(
                          maxScaleFactor: 1.15,
                        ),
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: showActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: widget.fontSize,
                          letterSpacing: showActive ? 0.1 : -0.1,
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
        tween: Tween<double>(
          begin: 1.0,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
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
    final isDark = widget.isDark;
    final iconColor = isDark ? Colors.white : const Color(0xFF121212);
    final glassBorder = isDark
        ? const Color(0x18FFFFFF)
        : const Color(0x22000000);

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.28 : 0.08,
                  ),
                  blurRadius: isDark ? 26 : 22,
                  offset: Offset(0, isDark ? 8 : 7),
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.10 : 0.03,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0x281C2028),
                              const Color(0x18090B0E),
                            ]
                          : [
                              const Color(0x75FFFFFF),
                              const Color(0x4AFFFFFF),
                            ],
                    ),
                    border: Border.all(color: glassBorder, width: 0.75),
                  ),
                  child: Stack(
                    children: [
                      // Inner top specular reflection
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.size * 0.46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(widget.size / 2),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      const Color(0x10FFFFFF),
                                      const Color(0x00FFFFFF),
                                    ]
                                  : [
                                      const Color(0x65FFFFFF),
                                      const Color(0x00FFFFFF),
                                    ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _handleTap,
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            CommunityCreationFlow.openCreateMenu(context);
                          },
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: widget.iconSize,
                              color: iconColor,
                            ),
                          ),
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
  }
}
