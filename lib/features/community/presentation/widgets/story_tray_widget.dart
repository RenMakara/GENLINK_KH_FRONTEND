import 'dart:io';
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

class StoryTrayWidget extends StatefulWidget {
  const StoryTrayWidget({super.key});

  @override
  State<StoryTrayWidget> createState() => _StoryTrayWidgetState();
}

class _StoryTrayWidgetState extends State<StoryTrayWidget>
    with WidgetsBindingObserver {
  late final StoryController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Get.isRegistered<StoryController>()
        ? Get.find<StoryController>()
        : Get.put(StoryController());

    if (_controller.storyGroups.isEmpty && !_controller.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isClosed) {
          _controller.fetchStories();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isClosed) {
        _controller.purgeExpiredStories();
        _controller.fetchStories();
      }
    }
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
                  CircleAvatar(radius: 32, backgroundColor: skeletonColor),
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
      final currentUserId = CurrentUser.id;
      final currentUserAvatar = CurrentUser.avatarUrl;
      final rawOwnerGroup = allGroups.firstWhereOrNull((g) =>
          g.isOwner || (currentUserId.isNotEmpty && g.userId == currentUserId));
      final ownerGroup = rawOwnerGroup != null
          ? StoryGroupModel(
              userId: rawOwnerGroup.userId,
              userName: rawOwnerGroup.userName,
              userAvatar: (currentUserAvatar?.isNotEmpty == true)
                  ? currentUserAvatar!
                  : rawOwnerGroup.userAvatar,
              isOwner: true,
              stories: rawOwnerGroup.stories.where((s) => !s.isExpired).toList(),
            )
          : StoryGroupModel(
              userId: currentUserId.isNotEmpty ? currentUserId : 'current_user',
              userName: 'community.yourStory'.tr,
              userAvatar: currentUserAvatar ?? '',
              isOwner: true,
              stories: [],
            );

      final seenUserIds = <String>{};
      if (ownerGroup.userId.isNotEmpty) {
        seenUserIds.add(ownerGroup.userId);
      }
      if (currentUserId.isNotEmpty) {
        seenUserIds.add(currentUserId);
      }

      final otherGroups = <StoryGroupModel>[];
      for (final g in allGroups) {
        if (g.isOwner) continue;
        if (currentUserId.isNotEmpty && g.userId == currentUserId) continue;
        if (g.userId.isNotEmpty && seenUserIds.contains(g.userId)) continue;
        final activeStories = g.stories.where((s) => !s.isExpired).toList();
        if (activeStories.isEmpty) continue;

        if (g.userId.isNotEmpty) {
          seenUserIds.add(g.userId);
        }

        otherGroups.add(
          StoryGroupModel(
            userId: g.userId,
            userName: g.userName,
            userAvatar: g.userAvatar,
            isOwner: false,
            stories: activeStories,
          ),
        );
      }

      otherGroups.sort((a, b) {
        if (a.hasUnseen && !b.hasUnseen) return -1;
        if (!a.hasUnseen && b.hasUnseen) return 1;
        return 0;
      });

      // ONLY real groups: owner followed by real other users with active stories.
      // NO demo/mock groups.
      final displayGroups = [ownerGroup, ...otherGroups];

      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: displayGroups.length,
          itemBuilder: (context, idx) {
            final group = displayGroups[idx];
            return _StoryTrayItem(
              group: group,
              index: idx,
              allGroups: displayGroups,
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
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.00).animate(
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
    ).then((_) {
      if (mounted) setState(() {});
    });
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
                          color: group.stories.isNotEmpty
                              ? AppColors.communityAccent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Hero(
                        tag: 'story_avatar_${group.userId}',
                        child: _buildStoryAvatar(
                          avatarUrl: group.userAvatar,
                          size: 52,
                          isDark: isDark,
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
                            color: isDark
                                ? AppColors.darkTextInverse
                                : AppColors.lightTextInverse,
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
                      child: _buildStoryAvatar(
                        avatarUrl: group.userAvatar,
                        size: 52,
                        isDark: isDark,
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

Widget _buildStoryAvatar({
  required String? avatarUrl,
  required double size,
  required bool isDark,
}) {
  final cleanUrl = avatarUrl?.trim();
  final hasUrl = cleanUrl != null &&
      cleanUrl.isNotEmpty &&
      cleanUrl != 'null' &&
      cleanUrl != 'undefined';

  ImageProvider? provider;
  if (hasUrl) {
    if (cleanUrl.startsWith('assets/')) {
      provider = AssetImage(cleanUrl);
    } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null && uri.hasScheme) {
        provider = NetworkImage(cleanUrl);
      }
    } else if (cleanUrl.startsWith('/') || cleanUrl.startsWith('file://')) {
      try {
        final filePath = cleanUrl.startsWith('file://')
            ? Uri.parse(cleanUrl).toFilePath()
            : cleanUrl;
        provider = FileImage(File(filePath));
      } catch (_) {}
    }
  }

  provider ??= const AssetImage('assets/images/user_profile.png');

  return CircleAvatar(
    radius: size / 2,
    backgroundColor: isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary,
    backgroundImage: provider,
    onBackgroundImageError: (exception, stackTrace) {
      debugPrint('[StoryTrayWidget] Avatar image load error: $exception');
    },
    child: null,
  );
}
