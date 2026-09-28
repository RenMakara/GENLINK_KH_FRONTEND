import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../../domain/models/story_model.dart';
import '../../../../shared/utils/current_user.dart';
import '../controllers/story_controller.dart';
import '../screens/story_viewer_screen.dart';
import 'story_creation_picker_sheet.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';

// ---------------------------------------------------------------------------
// Story ring colors — GenLink neutral system (no bright colors)
// ---------------------------------------------------------------------------

// Unviewed story ring — charcoal (dark mode) / near-black (light mode)
// Subtle but clearly indicates "new content" without Instagram-style gradient
const _kStoryUnseenRingLight = Color(0xFF1C1C1E); // near-black
const _kStoryUnseenRingDark = Color(0xFFF2F2F7); // near-white

// Viewed story ring — muted gray
const _kStoryViewedRingLight = Color(0xFFCBCDD1);
const _kStoryViewedRingDark = Color(0xFF4A4C50);

// "+" badge — adaptive: dark bg with white icon in light mode,
//             white bg with dark icon in dark mode
const _kPlusBadgeLightBg = Color(0xFF1C1C1E); // near-black in light mode
const _kPlusBadgeDarkBg = Color(0xFFF2F2F7); // near-white in dark mode
const _kPlusBadgeLightIcon = Colors.white;
const _kPlusBadgeDarkIcon = Color(0xFF1C1C1E);

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

      // -----------------------------------------------------------------------
      // Build display list from REAL backend data only — NO demo/mock injection
      // -----------------------------------------------------------------------
      final allGroups = List<StoryGroupModel>.from(controller.storyGroups);
      final currentUserId = CurrentUser.id;
      final currentUserAvatar = CurrentUser.avatarUrl;

      // Determine the owner's display name from real auth data
      final ownerName =
          CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
          ? CurrentUser.name
          : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'You');

      // Find the owner group (marked by backend isOwner flag or matching userId)
      final rawOwnerGroup = allGroups.firstWhereOrNull(
        (g) =>
            g.isOwner ||
            (currentUserId.isNotEmpty && g.userId == currentUserId),
      );

      // Merge real avatar from auth into owner group so it always shows correctly
      final ownerGroup = rawOwnerGroup != null
          ? StoryGroupModel(
              userId: rawOwnerGroup.userId,
              userName:
                  rawOwnerGroup.userName.isNotEmpty &&
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

      // Other users' stories — real backend data only, no demo injection
      final otherGroups = allGroups
          .where(
            (g) =>
                !g.isOwner &&
                (currentUserId.isEmpty || g.userId != currentUserId) &&
                // Guard: skip any accidentally-injected demo/mock data
                !g.userId.startsWith('demo_') &&
                !g.userId.startsWith('mock_'),
          )
          .toList();

      // Sort: unseen first
      otherGroups.sort((a, b) {
        if (a.hasUnseen && !b.hasUnseen) return -1;
        if (!a.hasUnseen && b.hasUnseen) return 1;
        return 0;
      });

      // Final display list — owner with stories first, then others
      // index 0 in the ListView is always the "Create Story" button (ownerGroup)
      // index 1..n maps to displayGroups[0..n-1]
      final displayGroups = <StoryGroupModel>[
        if (ownerGroup.stories.isNotEmpty) ownerGroup,
        ...otherGroups,
      ];

      final tray = SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: displayGroups.length + 1, // +1 for Create Story at idx 0
          itemBuilder: (context, idx) {
            final isCreateStory = idx == 0;
            final group = isCreateStory ? ownerGroup : displayGroups[idx - 1];
            return _StoryTrayItem(
              group: group,
              // Viewer index: maps into displayGroups (idx-1 when not create)
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
      if (!controller.hasStoriesError.value) return tray;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.storiesErrorMessage.value,
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: controller.fetchStories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          tray,
        ],
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

    // Pass the real displayGroups and the correct index within that list
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
  // Create Story item: real user avatar + neutral "+" badge
  // No "Your Story" label — the "+" badge makes purpose clear, keeps tray clean
  // -------------------------------------------------------------------------
  Widget _buildCreateStoryItem(
    BuildContext context,
    bool isDark,
    StoryGroupModel group,
    Color textMuted,
  ) {
    const double avatarSize = 58.0;
    const double badgeSize = 20.0;

    // Adaptive badge colors: dark on light bg, light on dark bg
    final badgeBg = isDark ? _kPlusBadgeDarkBg : _kPlusBadgeLightBg;
    final badgeIcon = isDark ? _kPlusBadgeDarkIcon : _kPlusBadgeLightIcon;

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
                      // Main avatar circle with subtle border
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
                      // Neutral "+" badge at bottom-right
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            color: badgeBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBgPrimary
                                  : AppColors.lightSurfacePrimary,
                              width: 2.0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: badgeIcon,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Small "You" label — minimal, just enough to identify this slot
                Text(
                  _shortOwnerLabel(group.userName),
                  style:
                      widget.theme.textTheme.labelSmall?.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                        fontSize: 10.5,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ) ??
                      TextStyle(
                        color: textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
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

  /// Returns a short label for the owner slot.
  /// Uses the first name only (e.g. "Nat" from "Nat Enat") to keep it compact.
  /// Falls back to "You" if name is not available.
  String _shortOwnerLabel(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty || name == 'Guest' || name == 'User') return 'You';
    // Use first word (first name) to keep label short
    return name.split(' ').first;
  }

  // -------------------------------------------------------------------------
  // Normal story item: neutral ring (unseen = dark/light solid, seen = gray)
  // No bright gradient — clean black/white/neutral system
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
    const double ringGap = 2.5;
    const double outerSize = avatarSize + (ringStroke + ringGap) * 2;

    final isKhmer = _containsKhmer(group.userName);

    // Unseen ring color: near-black in light mode, near-white in dark mode
    final unseenRingColor = isDark
        ? _kStoryUnseenRingDark
        : _kStoryUnseenRingLight;
    final viewedRingColor = isDark
        ? _kStoryViewedRingDark
        : _kStoryViewedRingLight;

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
                      // Ring layer — neutral solid ring (no gradient)
                      Positioned.fill(
                        child: _NeutralRingWidget(
                          size: outerSize,
                          strokeWidth: ringStroke,
                          gapWidth: ringGap,
                          bgColor: bgPrimary,
                          ringColor: group.hasUnseen
                              ? unseenRingColor
                              : viewedRingColor,
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
                    style:
                        theme.textTheme.labelSmall?.copyWith(
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
// Neutral ring (both viewed and unviewed) — solid color + bg gap ring
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

    // Solid neutral ring
    final ringRadius = outerRadius - strokeWidth / 2;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Background gap ring — separates ring from avatar edge cleanly
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
