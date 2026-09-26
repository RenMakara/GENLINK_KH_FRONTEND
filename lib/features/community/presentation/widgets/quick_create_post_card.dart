import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'community_creation_flow.dart';

/// Single-row compact social-media composer for GenLink Home.
///
/// Layout:
/// `[Avatar] ✎ What's on your mind?   🖼   📷   ⊕`
///
/// Features:
/// - Single horizontal container (approx 58-64px height, 20px radius).
/// - Current logged-in user's real avatar with existing GenLink fallback.
/// - Tappable text area with edit icon opening the full post composer.
/// - Photo button (Icons.image_outlined) triggering gallery media picker.
/// - Camera / Video button (Icons.camera_alt_outlined) triggering camera picker.
/// - More (+) button (Icons.add_circle_outline) opening iOS-style creation options sheet.
/// - 44px minimum touch targets with subtle press scale animation (1.0 -> 0.96 -> 1.0).
/// - Light / Dark mode surfaces matching GenLink design system tokens.
class QuickCreatePostCard extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onTapPhoto;
  final VoidCallback? onTapCamera;
  final VoidCallback? onTapMore;

  // Legacy callbacks preserved for backward compatibility
  final VoidCallback? onTapPost;
  final VoidCallback? onTapDiscussion;
  final VoidCallback? onTapEvent;

  final String? avatarUrl;
  final String? userName;
  final EdgeInsetsGeometry padding;

  const QuickCreatePostCard({
    super.key,
    this.onTap,
    this.onTapPhoto,
    this.onTapCamera,
    this.onTapMore,
    this.onTapPost,
    this.onTapDiscussion,
    this.onTapEvent,
    this.avatarUrl,
    this.userName,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerBg = isDark ? const Color(0xFF1E2024) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);
    final mutedIconColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final mutedTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    Widget buildAvatar() {
      if (avatarUrl != null && avatarUrl!.isNotEmpty) {
        return AppAvatar(imageUrl: avatarUrl, name: userName, size: 40);
      }
      if (authController == null) {
        return AppAvatar(name: userName, size: 40);
      }
      return Obx(() {
        final authUser = authController.currentUser.value;
        return AppAvatar(
          imageUrl: authUser?.avatarUrl,
          name: userName ?? authUser?.fullName,
          size: 40,
        );
      });
    }

    return Padding(
      padding: padding,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. User Avatar
            buildAvatar(),
            const SizedBox(width: 10),

            // 2. Text Area (✎ What's on your mind?)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap ?? () => CommunityCreationFlow.openCreatePost(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.5,
                          color: mutedIconColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 3. Photo Button
            _ComposerActionButton(
              icon: Icons.image_outlined,
              iconSize: 22,
              tooltip: 'Add photo',
              color: mutedIconColor,
              onTap: onTapPhoto ??
                  onTapPost ??
                  () => CommunityCreationFlow.openCreatePostWithPhoto(context),
            ),
            const SizedBox(width: 6),

            // 4. Camera / Video Button
            _ComposerActionButton(
              icon: Icons.camera_alt_outlined,
              iconSize: 21.5,
              tooltip: 'Add video',
              color: mutedIconColor,
              onTap: onTapCamera ??
                  () => CommunityCreationFlow.openCreatePostWithCamera(context),
            ),
            const SizedBox(width: 6),

            // 5. More (+) Button
            _ComposerActionButton(
              icon: Icons.add_circle_outline,
              iconSize: 22,
              tooltip: 'More options',
              color: mutedIconColor,
              onTap: onTapMore ??
                  () {
                    if (onTapDiscussion != null) {
                      onTapDiscussion!();
                    } else if (onTapEvent != null) {
                      onTapEvent!();
                    } else {
                      _showMoreOptionsSheet(context);
                    }
                  },
            ),
          ],
        ),
      ),
    );
  }

  String get _prompt {
    final translated = 'community.whatsOnYourMind'.tr;
    if (translated.isNotEmpty && translated != 'community.whatsOnYourMind') {
      return translated;
    }
    return "What's on your mind?";
  }

  void _showMoreOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xEE16181F) : const Color(0xFAFFFFFF);
    final cardBg = isDark ? const Color(0x14FFFFFF) : const Color(0x08000000);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderSubtle = isDark ? const Color(0x20FFFFFF) : const Color(0x12000000);
    final sheetBorder = isDark ? const Color(0x28FFFFFF) : const Color(0x18000000);
    final iconBg = isDark ? const Color(0x24FFFFFF) : const Color(0x0E000000);
    final iconBorder = isDark ? const Color(0x2CFFFFFF) : const Color(0x14000000);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: sheetBorder, width: 0.8),
                left: BorderSide(color: sheetBorder, width: 0.8),
                right: BorderSide(color: sheetBorder, width: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'community.create'.tr.isNotEmpty &&
                              'community.create'.tr != 'community.create'
                          ? 'community.create'.tr
                          : 'Create',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ComposerOptionTile(
                    icon: Icons.post_add_rounded,
                    title: 'community.createPost'.tr.isNotEmpty &&
                            'community.createPost'.tr != 'community.createPost'
                        ? 'community.createPost'.tr
                        : 'Create Post',
                    subtitle: 'community.shareWithCommunity'.tr.isNotEmpty &&
                            'community.shareWithCommunity'.tr != 'community.shareWithCommunity'
                        ? 'community.shareWithCommunity'.tr
                        : 'Share an update with your community',
                    cardBg: cardBg,
                    border: borderSubtle,
                    iconBg: iconBg,
                    iconBorder: iconBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      CommunityCreationFlow.openCreatePost(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ComposerOptionTile(
                    icon: Icons.amp_stories_rounded,
                    title: 'community.createStory'.tr.isNotEmpty &&
                            'community.createStory'.tr != 'community.createStory'
                        ? 'community.createStory'.tr
                        : 'Create Story',
                    subtitle: 'create.actionStoryDesc'.tr.isNotEmpty &&
                            'create.actionStoryDesc'.tr != 'create.actionStoryDesc'
                        ? 'create.actionStoryDesc'.tr
                        : 'Create a photo, video, or moment story',
                    cardBg: cardBg,
                    border: borderSubtle,
                    iconBg: iconBg,
                    iconBorder: iconBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      CommunityCreationFlow.openCreateStory(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ComposerOptionTile(
                    icon: Icons.forum_outlined,
                    title: 'community.startDiscussion'.tr.isNotEmpty &&
                            'community.startDiscussion'.tr != 'community.startDiscussion'
                        ? 'community.startDiscussion'.tr
                        : 'Start Discussion',
                    subtitle: 'Ask questions or debate ideas with peers',
                    cardBg: cardBg,
                    border: borderSubtle,
                    iconBg: iconBg,
                    iconBorder: iconBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      CommunityCreationFlow.openCreateDiscussion(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ComposerOptionTile(
                    icon: Icons.event_available_rounded,
                    title: 'community.createEvent'.tr.isNotEmpty &&
                            'community.createEvent'.tr != 'community.createEvent'
                        ? 'community.createEvent'.tr
                        : 'Create Event',
                    subtitle: 'create.actionEventDesc'.tr.isNotEmpty &&
                            'create.actionEventDesc'.tr != 'create.actionEventDesc'
                        ? 'create.actionEventDesc'.tr
                        : 'Host an event or community meetup',
                    cardBg: cardBg,
                    border: borderSubtle,
                    iconBg: iconBg,
                    iconBorder: iconBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      CommunityCreationFlow.openCreateEvent(context);
                    },
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

class _ComposerActionButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ComposerActionButton({
    required this.icon,
    this.iconSize = 22,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  @override
  State<_ComposerActionButton> createState() => _ComposerActionButtonState();
}

class _ComposerActionButtonState extends State<_ComposerActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap != null ? (_) => _animController.forward() : null,
          onTapCancel: widget.onTap != null ? () => _animController.reverse() : null,
          onTap: widget.onTap != null
              ? () {
                  _animController.reverse();
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                }
              : null,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 38,
              height: 44,
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ComposerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconBorder, width: 0.8),
                ),
                child: Center(
                  child: Icon(icon, color: textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.5,
                        fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
