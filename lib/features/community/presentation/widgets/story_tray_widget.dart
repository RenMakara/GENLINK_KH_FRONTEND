import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../controllers/story_controller.dart';
import '../screens/story_viewer_screen.dart';
import 'story_creation_picker_sheet.dart';

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

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bgPrimary = theme.scaffoldBackgroundColor;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final skeletonColor = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;

    return Obx(() {
      if (controller.isLoading.value) {
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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: skeletonColor,
                  ),
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

      final allGroups = controller.storyGroups;
      // Smart sorting: Owner story first, then unseen groups, then viewed groups
      final ownerGroup = allGroups.firstWhereOrNull((g) => g.isOwner);
      final otherGroups = allGroups.where((g) => !g.isOwner).toList();

      otherGroups.sort((a, b) {
        if (a.hasUnseen && !b.hasUnseen) return -1;
        if (!a.hasUnseen && b.hasUnseen) return 1;
        return 0;
      });

      final sortedGroups = [
        ?ownerGroup,
        ...otherGroups,
      ];

      return Container(
        height: 94,
        margin: EdgeInsets.zero,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: sortedGroups.length,
          itemBuilder: (context, idx) {
            final group = sortedGroups[idx];
            return _StoryTrayItem(
              group: group,
              index: idx,
              allGroups: sortedGroups,
              controller: controller,
              isDark: isDark,
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
  final dynamic group;
  final int index;
  final List<dynamic> allGroups;
  final StoryController controller;
  final bool isDark;
  final Color bgPrimary;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final ThemeData theme;

  const _StoryTrayItem({
    required this.group,
    required this.index,
    required this.allGroups,
    required this.controller,
    required this.isDark,
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
    if (widget.group.isOwner && widget.group.stories.isEmpty) {
      StoryCreationPickerSheet.show(context);
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerScreen(
            initialGroupIndex: widget.index,
            groups: widget.allGroups.cast(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(
            begin: 0.98,
            end: 1.00,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ));

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );

          return ScaleTransition(
            scale: scaleAnimation,
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  bool _containsKhmer(String text) {
    return RegExp(r'[\u1780-\u17FF]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isDark = widget.isDark;
    final bgPrimary = widget.bgPrimary;
    final border = widget.border;
    final textPrimary = widget.textPrimary;
    final textMuted = widget.textMuted;
    final theme = widget.theme;

    if (group.isOwner) {
      return Padding(
        padding: const EdgeInsets.only(right: 14),
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
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: group.stories.isNotEmpty ? AppColors.communityAccent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Hero(
                        tag: 'story_avatar_${group.userId}',
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: group.userAvatar.startsWith('assets/')
                              ? AssetImage(group.userAvatar) as ImageProvider
                              : NetworkImage(group.userAvatar),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: () => StoryCreationPickerSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: AppColors.communityAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgPrimary, width: 1.5),
                          ),
                          child: Icon(
                            Icons.add,
                            color: isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 78,
                  child: Text(
                    'community.yourStory'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
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
      padding: const EdgeInsets.only(right: 14),
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
                          colors: [AppColors.communityAccent, AppColors.accentPremium],
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
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: group.userAvatar.startsWith('assets/')
                            ? AssetImage(group.userAvatar) as ImageProvider
                            : NetworkImage(group.userAvatar),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 78,
                child: Text(
                  group.userName,
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: group.hasUnseen ? textPrimary : textMuted,
                        fontWeight: group.hasUnseen ? FontWeight.bold : FontWeight.normal,
                        fontFamily: _containsKhmer(group.userName) ? 'KantumruyPro' : null,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ) ??
                      TextStyle(
                        color: group.hasUnseen ? textPrimary : textMuted,
                        fontSize: 11,
                        fontWeight: group.hasUnseen ? FontWeight.bold : FontWeight.normal,
                        fontFamily: _containsKhmer(group.userName) ? 'KantumruyPro' : null,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ),
                  maxLines: 2,
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
