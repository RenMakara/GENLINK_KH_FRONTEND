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
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final skeletonColor = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;

    return Obx(() {
      if (controller.isLoading.value && controller.storyGroups.isEmpty) {
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: skeletonColor),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 10,
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
      final ownerGroup = rawOwnerGroup != null
          ? StoryGroupModel(
              userId: rawOwnerGroup.userId,
              userName: rawOwnerGroup.userName,
              userAvatar: (currentUserAvatar?.isNotEmpty == true)
                  ? currentUserAvatar!
                  : rawOwnerGroup.userAvatar,
              isOwner: true,
              stories: rawOwnerGroup.stories,
            )
          : StoryGroupModel(
              userId: currentUserId.isNotEmpty ? currentUserId : 'current_user',
              userName: 'community.yourStory'.tr,
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

      // Keep the create-story affordance separate from the owner's story.
      // This lets the owner appear as a normal story profile after publishing
      // while the first slot remains available for adding another story.
      final demoGroups = getDemoStoryGroups();
      final displayGroups = <StoryGroupModel>[
        if (ownerGroup.stories.isNotEmpty) ownerGroup,
        ...demoGroups,
        ...otherGroups,
      ];

      return SizedBox(
        height: 100,
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
              border: border,
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

class _StoryTrayItem extends StatefulWidget {
  final StoryGroupModel group;
  final int index;
  final List<StoryGroupModel> allGroups;
  final bool isCreateStory;
  final Color bgPrimary;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final ThemeData theme;

  const _StoryTrayItem({
    required this.group,
    required this.index,
    required this.allGroups,
    required this.isCreateStory,
    required this.bgPrimary,
    required this.border,
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
    final border = widget.border;
    final textPrimary = widget.textPrimary;
    final textMuted = widget.textMuted;
    final theme = widget.theme;

    if (widget.isCreateStory) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _onStoryTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                CustomPaint(
                  size: const Size.square(64),
                  painter: _DashedCirclePainter(
                    color: AppColors.communityAccent,
                  ),
                  child: const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.communityAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 72,
                  child: Text(
                    'community.yourStory'.tr,
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ) ??
                        TextStyle(
                          color: textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _onStoryTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: group.hasUnseen
                      ? const LinearGradient(
                          colors: [
                            AppColors.communityAccent,
                            AppColors.accentPremium,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: !group.hasUnseen
                      ? Border.all(color: border, width: 1.5)
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bgPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: group.hasUnseen ? 1.0 : 0.80,
                    child: Hero(
                      tag: 'story_avatar_${group.userId}',
                      child: AppAvatar(
                        imageUrl: group.userAvatar,
                        name: group.userName,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  group.userName,
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                        color: group.hasUnseen ? textPrimary : textMuted,
                        fontWeight: group.hasUnseen
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: _containsKhmer(group.userName)
                            ? 'KantumruyPro'
                            : null,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ) ??
                      TextStyle(
                        color: group.hasUnseen ? textPrimary : textMuted,
                        fontSize: 11,
                        fontWeight: group.hasUnseen
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: _containsKhmer(group.userName)
                            ? 'KantumruyPro'
                            : null,
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
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final radius = (size.shortestSide - paint.strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const dashSweep = 0.22;
    const gapSweep = 0.17;
    var start = -0.5 * 3.141592653589793;
    while (start < 2 * 3.141592653589793) {
      canvas.drawArc(rect, start, dashSweep, false, paint);
      start += dashSweep + gapSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
