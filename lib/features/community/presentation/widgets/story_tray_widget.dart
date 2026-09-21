import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../../domain/models/story_model.dart';
import '../../../../shared/utils/current_user.dart';
import '../controllers/story_controller.dart';
import '../screens/story_viewer_screen.dart';
import 'demo_stories_data.dart';
import 'story_creation_picker_sheet.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';

// ---------------------------------------------------------------------------
// Story gradient ring colors — used for unviewed story ring
// ---------------------------------------------------------------------------
const _kStoryGradientColors = [
  Color(0xFFE040FB), // Purple-pink
  Color(0xFFFF6B35), // Orange
  Color(0xFFFFD600), // Yellow
];



// Viewed story ring
const _kStoryViewedRingLight = Color(0xFFCBCDD1);
const _kStoryViewedRingDark = Color(0xFF4A4C50);

// "+" badge background
const _kPlusBadgeBg = Color(0xFF1F6FEB); // AppColors.brandPrimary

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------
class StoryTrayWidget extends StatefulWidget {
  const StoryTrayWidget({super.key});

  @override
  State<StoryTrayWidget> createState() => _StoryTrayWidgetState();
}

class _StoryTrayWidgetState extends State<StoryTrayWidget> {
  late final StoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<StoryController>()
        ? Get.find<StoryController>()
        : Get.put(StoryController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final bgPrimary = theme.scaffoldBackgroundColor;
    final skeletonColor = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;

    return Obx(() {
      if (controller.isLoading.value && controller.storyGroups.isEmpty) {
        return SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 3),
                  CircleAvatar(radius: 29, backgroundColor: skeletonColor),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 8,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final allGroups = List<StoryGroupModel>.from(controller.storyGroups);
      final currentUserId = CurrentUser.id;
      final currentUserAvatar = CurrentUser.avatarUrl;
      final rawOwnerGroup = allGroups.firstWhereOrNull((g) => g.isOwner);
      final ownerName = CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
          ? CurrentUser.name
          : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'You');
      final ownerGroup = rawOwnerGroup != null
          ? StoryGroupModel(
              userId: rawOwnerGroup.userId,
              userName: rawOwnerGroup.userName.isNotEmpty &&
                      rawOwnerGroup.userName != 'community.yourStory'.tr &&
                      rawOwnerGroup.userName != 'Your Story'
                  ? rawOwnerGroup.userName
                  : ownerName,
              userAvatar: (currentUserAvatar?.isNotEmpty == true)
                  ? currentUserAvatar!
                  : rawOwnerGroup.userAvatar,
              isOwner: true,
              stories: rawOwnerGroup.stories,
            )
          : StoryGroupModel(
              userId: currentUserId.isNotEmpty ? currentUserId : 'current_user',
              userName: ownerName,
              userAvatar: currentUserAvatar ?? '',
              isOwner: true,
              stories: [],
            );
      final otherGroups = allGroups.where((g) => !g.isOwner).toList();

      otherGroups.sort((a, b) {
        if (a.hasUnseen && !b.hasUnseen) return -1;
        if (!a.hasUnseen && b.hasUnseen) return 1;
        return 0;
      });

      final demoGroups = getDemoStoryGroups();
      final displayGroups = <StoryGroupModel>[
        if (ownerGroup.stories.isNotEmpty) ownerGroup,
        ...demoGroups,
        ...otherGroups,
      ];

      return SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: displayGroups.length + 1,
          itemBuilder: (context, idx) {
            final isCreateStory = idx == 0;
            final group = isCreateStory ? ownerGroup : displayGroups[idx - 1];
            return _StoryTrayItem(
              group: group,
              index: isCreateStory ? -1 : idx - 1,
              allGroups: displayGroups,
              isCreateStory: isCreateStory,
              bgPrimary: bgPrimary,
              textPrimary: textPrimary,
              textMuted: textMuted,
              theme: theme,
            );
          },
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Individual tray item
// ---------------------------------------------------------------------------
class _StoryTrayItem extends StatefulWidget {
  final StoryGroupModel group;
  final int index;
  final List<StoryGroupModel> allGroups;
  final bool isCreateStory;
  final Color bgPrimary;
  final Color textPrimary;
  final Color textMuted;
  final ThemeData theme;

  const _StoryTrayItem({
    required this.group,
    required this.index,
    required this.allGroups,
    required this.isCreateStory,
    required this.bgPrimary,
    required this.textPrimary,
    required this.textMuted,
    required this.theme,
  });

  @override
  State<_StoryTrayItem> createState() => _StoryTrayItemState();
}

class _StoryTrayItemState extends State<_StoryTrayItem> {
  bool _isPressed = false;

  void _onStoryTap() {
    if (widget.isCreateStory) {
      StoryCreationPickerSheet.show(context);
      return;
    }

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 180),
            pageBuilder: (context, animation, secondaryAnimation) {
              return StoryViewerScreen(
                initialGroupIndex: widget.index,
                groups: widget.allGroups,
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final scaleAnimation = Tween<double>(begin: 0.96, end: 1.00)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastOutSlowIn,
                          reverseCurve: Curves.easeInCubic,
                        ),
                      );

                  final fadeAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                    reverseCurve: Curves.easeIn,
                  );

                  return ScaleTransition(
                    scale: scaleAnimation,
                    alignment: Alignment.center,
                    child: FadeTransition(opacity: fadeAnimation, child: child),
                  );
                },
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  bool _containsKhmer(String text) {
    return RegExp(r'[\u1780-\u17FF]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bgPrimary = widget.bgPrimary;
    final textMuted = widget.textMuted;
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isCreateStory) {
      return _buildCreateStoryItem(context, isDark, group, textMuted);
    }

    return _buildStoryItem(context, isDark, group, bgPrimary);
  }

  // -------------------------------------------------------------------------
  // Create Story item: avatar + blue "+" badge + "Your Story" label
  // -------------------------------------------------------------------------
  Widget _buildCreateStoryItem(
    BuildContext context,
    bool isDark,
    StoryGroupModel group,
    Color textMuted,
  ) {
    const double avatarSize = 58.0;
    const double badgeSize = 22.0;

    // "Your Story" label with localization
    final yourStoryLabel =
        'community.yourStory'.tr.isNotEmpty &&
                'community.yourStory'.tr != 'community.yourStory'
            ? 'community.yourStory'.tr
            : 'Your Story';
    final isKhmer = _containsKhmer(yourStoryLabel);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _onStoryTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                // Avatar + "+" badge stack
                SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main avatar circle
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.10),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: AppAvatar(
                              imageUrl: group.userAvatar,
                              name: group.userName,
                              size: avatarSize,
                            ),
                          ),
                        ),
                      ),
                      // Blue "+" badge at bottom-right
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            color: _kPlusBadgeBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBgPrimary
                                  : AppColors.lightSurfacePrimary,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPlusBadgeBg.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // "Your Story" label
                Text(
                  yourStoryLabel,
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.5,
                        fontFamily: isKhmer ? 'KantumruyPro' : null,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ) ??
                      TextStyle(
                        color: textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: isKhmer ? 'KantumruyPro' : null,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Normal story item: gradient ring (unseen) or neutral ring (seen) + label
  // -------------------------------------------------------------------------
  Widget _buildStoryItem(
    BuildContext context,
    bool isDark,
    StoryGroupModel group,
    Color bgPrimary,
  ) {
    final textPrimary = widget.textPrimary;
    final textMuted = widget.textMuted;
    final theme = widget.theme;

    // Ring dimensions
    const double avatarSize = 52.0;
    const double ringStroke = 2.5;
    const double ringGap = 2.5; // gap between ring and avatar edge
    // Total container size = avatarSize + 2*ringStroke + 2*ringGap
    const double outerSize = avatarSize + (ringStroke + ringGap) * 2;

    final isKhmer = _containsKhmer(group.userName);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _onStoryTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                SizedBox(
                  width: outerSize,
                  height: outerSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring layer
                      Positioned.fill(
                        child: group.hasUnseen
                            ? _GradientRingWidget(
                                size: outerSize,
                                strokeWidth: ringStroke,
                                gapWidth: ringGap,
                                bgColor: bgPrimary,
                                colors: _kStoryGradientColors,
                              )
                            : _NeutralRingWidget(
                                size: outerSize,
                                strokeWidth: ringStroke,
                                gapWidth: ringGap,
                                bgColor: bgPrimary,
                                ringColor: isDark
                                    ? _kStoryViewedRingDark
                                    : _kStoryViewedRingLight,
                              ),
                      ),
                      // Avatar
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: group.hasUnseen ? 1.0 : 0.80,
                        child: Hero(
                          tag: 'story_avatar_${group.userId}',
                          child: ClipOval(
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: AppAvatar(
                                imageUrl: group.userAvatar,
                                name: group.userName,
                                size: avatarSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    group.userName,
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: group.hasUnseen ? textPrimary : textMuted,
                          fontWeight: group.hasUnseen
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 10.5,
                          fontFamily: isKhmer ? 'KantumruyPro' : null,
                          fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                        ) ??
                        TextStyle(
                          color: group.hasUnseen ? textPrimary : textMuted,
                          fontSize: 10.5,
                          fontWeight: group.hasUnseen
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontFamily: isKhmer ? 'KantumruyPro' : null,
                          fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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

// ---------------------------------------------------------------------------
// Gradient ring (unviewed) — uses a CustomPaint approach with a gap ring
// drawn at background color so the avatar appears cleanly separated.
// ---------------------------------------------------------------------------
class _GradientRingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double gapWidth;
  final Color bgColor;
  final List<Color> colors;

  const _GradientRingWidget({
    required this.size,
    required this.strokeWidth,
    required this.gapWidth,
    required this.bgColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientRingFullPainter(
        colors: colors,
        strokeWidth: strokeWidth,
        gapWidth: gapWidth,
        bgColor: bgColor,
      ),
    );
  }
}

class _GradientRingFullPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final double gapWidth;
  final Color bgColor;

  const _GradientRingFullPainter({
    required this.colors,
    required this.strokeWidth,
    required this.gapWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // Gradient ring
    final gradientRadius = outerRadius - strokeWidth / 2;
    final shader = ui.Gradient.sweep(
      center,
      colors,
      List.generate(colors.length, (i) => i / (colors.length - 1)),
      TileMode.clamp,
      -0.5, // offset so gradient starts from top-ish
      (2 * 3.14159265) - 0.5,
    );
    final ringPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, gradientRadius, ringPaint);

    // White/bg gap ring to separate gradient ring from avatar
    final gapRadius = gradientRadius - strokeWidth / 2 - gapWidth / 2;
    final gapPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = gapWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, gapRadius, gapPaint);
  }

  @override
  bool shouldRepaint(_GradientRingFullPainter old) =>
      old.colors != colors ||
      old.strokeWidth != strokeWidth ||
      old.gapWidth != gapWidth ||
      old.bgColor != bgColor;
}

// ---------------------------------------------------------------------------
// Neutral ring (viewed)
// ---------------------------------------------------------------------------
class _NeutralRingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double gapWidth;
  final Color bgColor;
  final Color ringColor;

  const _NeutralRingWidget({
    required this.size,
    required this.strokeWidth,
    required this.gapWidth,
    required this.bgColor,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NeutralRingPainter(
        ringColor: ringColor,
        strokeWidth: strokeWidth,
        gapWidth: gapWidth,
        bgColor: bgColor,
      ),
    );
  }
}

class _NeutralRingPainter extends CustomPainter {
  final Color ringColor;
  final double strokeWidth;
  final double gapWidth;
  final Color bgColor;

  const _NeutralRingPainter({
    required this.ringColor,
    required this.strokeWidth,
    required this.gapWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // Neutral ring
    final ringRadius = outerRadius - strokeWidth / 2;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Gap ring
    final gapRadius = ringRadius - strokeWidth / 2 - gapWidth / 2;
    final gapPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = gapWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, gapRadius, gapPaint);
  }

  @override
  bool shouldRepaint(_NeutralRingPainter old) =>
      old.ringColor != ringColor ||
      old.strokeWidth != strokeWidth ||
      old.gapWidth != gapWidth ||
      old.bgColor != bgColor;
}
