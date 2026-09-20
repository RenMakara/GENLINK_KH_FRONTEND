import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

class CommunityCreationBottomSheet extends StatelessWidget {
  final VoidCallback onSelectCreatePost;
  final VoidCallback onSelectCreateStory;
  final VoidCallback onSelectCreateEvent;

  const CommunityCreationBottomSheet({
    super.key,
    required this.onSelectCreatePost,
    required this.onSelectCreateStory,
    required this.onSelectCreateEvent,
  });

  static const List<String> _fontFallbacks = [
    AppTypography.khmerFontFamily,
    AppTypography.englishFontFamily,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xCC16181F) : const Color(0xDAFFFFFF);
    final cardBg = isDark ? const Color(0x14FFFFFF) : const Color(0x08000000);
    final textPrimary = colors.primaryText;
    final textSecondary = colors.secondaryText;
    final borderSubtle = isDark ? const Color(0x20FFFFFF) : const Color(0x12000000);
    final sheetBorder = isDark ? const Color(0x28FFFFFF) : const Color(0x18000000);
    final iconBg = isDark ? const Color(0x24FFFFFF) : const Color(0x0E000000);
    final iconBorder = isDark ? const Color(0x2CFFFFFF) : const Color(0x14000000);

    final title = 'home.actionCreate'.tr.isNotEmpty && 'home.actionCreate'.tr != 'home.actionCreate'
        ? 'home.actionCreate'.tr
        : 'Create';

    final postTitle = 'community.createPost'.tr.isNotEmpty && 'community.createPost'.tr != 'community.createPost'
        ? 'community.createPost'.tr
        : 'Create Post';
    final postSubtitle = 'community.shareWithCommunity'.tr.isNotEmpty && 'community.shareWithCommunity'.tr != 'community.shareWithCommunity'
        ? 'community.shareWithCommunity'.tr
        : 'Share an update with your network';

    final storyTitle = 'community.createStory'.tr.isNotEmpty && 'community.createStory'.tr != 'community.createStory'
        ? 'community.createStory'.tr
        : 'Create Story';
    final storySubtitle = 'create.actionStoryDesc'.tr.isNotEmpty && 'create.actionStoryDesc'.tr != 'create.actionStoryDesc'
        ? 'create.actionStoryDesc'.tr
        : 'Create a photo, video, or text story';

    final eventTitle = 'community.createEvent'.tr.isNotEmpty && 'community.createEvent'.tr != 'community.createEvent'
        ? 'community.createEvent'.tr
        : 'Create Event';
    final eventSubtitle = 'create.actionEventDesc'.tr.isNotEmpty && 'create.actionEventDesc'.tr != 'create.actionEventDesc'
        ? 'create.actionEventDesc'.tr
        : 'Host an event or community meetup';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                title,
                style: TextStyle(
                  fontFamily: AppTypography.englishFontFamily,
                  fontFamilyFallback: _fontFallbacks,
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CreationOptionTile(
              icon: Icons.post_add_rounded,
              title: postTitle,
              subtitle: postSubtitle,
              cardBg: cardBg,
              border: borderSubtle,
              iconBg: iconBg,
              iconBorder: iconBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreatePost,
            ),
            const SizedBox(height: 10),
            _CreationOptionTile(
              icon: Icons.amp_stories_rounded,
              title: storyTitle,
              subtitle: storySubtitle,
              cardBg: cardBg,
              border: borderSubtle,
              iconBg: iconBg,
              iconBorder: iconBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreateStory,
            ),
            const SizedBox(height: 10),
            _CreationOptionTile(
              icon: Icons.event_available_rounded,
              title: eventTitle,
              subtitle: eventSubtitle,
              cardBg: cardBg,
              border: borderSubtle,
              iconBg: iconBg,
              iconBorder: iconBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreateEvent,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _CreationOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _CreationOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: textPrimary.withValues(alpha: 0.08),
          highlightColor: textPrimary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: iconBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: textPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.englishFontFamily,
                          fontFamilyFallback: const [
                            AppTypography.khmerFontFamily,
                            AppTypography.englishFontFamily,
                          ],
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.englishFontFamily,
                          fontFamilyFallback: const [
                            AppTypography.khmerFontFamily,
                            AppTypography.englishFontFamily,
                          ],
                          color: textSecondary,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
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
