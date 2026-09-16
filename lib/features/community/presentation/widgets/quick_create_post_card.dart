import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import 'community_creation_flow.dart';

/// Compact "Share something" entry point for the community feed.
///
/// The card keeps the existing create-post and optional creation callbacks;
/// only their visual presentation is condensed into the Home feed design.
class QuickCreatePostCard extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onTapPost;
  final VoidCallback? onTapDiscussion;
  final VoidCallback? onTapEvent;
  final String? avatarUrl;
  final String? userName;
  final EdgeInsetsGeometry padding;

  const QuickCreatePostCard({
    super.key,
    this.onTap,
    this.onTapPost,
    this.onTapDiscussion,
    this.onTapEvent,
    this.avatarUrl,
    this.userName,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final hasOptionalActions =
        onTapPost != null || onTapDiscussion != null || onTapEvent != null;

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => CommunityCreationFlow.openCreatePost(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chatPrimarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: semantic.borderSubtle),
              boxShadow: semantic.cardShadow,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ) ??
                        TextStyle(
                          color: semantic.secondaryText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasOptionalActions)
                  _buildOptionalActionIcons(semantic)
                else
                  _buildDecorativeActionIcons(semantic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _prompt {
    final name = userName?.trim();
    if (name != null && name.isNotEmpty && name != 'Guest') {
      final personalized = 'community.whatsHappeningWithName'.trParams({
        'name': name,
      });
      if (personalized.isNotEmpty &&
          personalized != 'community.whatsHappeningWithName') {
        return personalized;
      }
    }

    final translated = 'community.shareWithCommunity'.tr;
    return translated.isNotEmpty && translated != 'community.shareWithCommunity'
        ? translated
        : 'Share something with your community.';
  }

  Widget _buildDecorativeActionIcons(AppSemanticColors semantic) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickCreateActionIcon(
          icon: Icons.image_outlined,
          tooltip: 'Post',
          color: AppColors.brandPrimary,
        ),
        _buildDivider(semantic),
        _QuickCreateActionIcon(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Discussion',
          color: AppColors.brandPrimary,
        ),
        _buildDivider(semantic),
        _QuickCreateActionIcon(
          icon: Icons.add_box_outlined,
          tooltip: 'Event',
          color: AppColors.brandPrimary,
        ),
      ],
    );
  }

  Widget _buildOptionalActionIcons(AppSemanticColors semantic) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickCreateActionIcon(
          icon: Icons.image_outlined,
          tooltip: 'Post',
          color: AppColors.brandPrimary,
          onTap: onTapPost,
        ),
        _buildDivider(semantic),
        _QuickCreateActionIcon(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Discussion',
          color: AppColors.brandPrimary,
          onTap: onTapDiscussion,
        ),
        _buildDivider(semantic),
        _QuickCreateActionIcon(
          icon: Icons.add_box_outlined,
          tooltip: 'Event',
          color: AppColors.brandPrimary,
          onTap: onTapEvent,
        ),
      ],
    );
  }

  Widget _buildDivider(AppSemanticColors semantic) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: semantic.borderSubtle,
    );
  }
}

class _QuickCreateActionIcon extends StatelessWidget {
  const _QuickCreateActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = SizedBox(
      width: 32,
      height: 40,
      child: Center(child: Icon(icon, color: color, size: 22)),
    );

    if (onTap == null) {
      return Semantics(label: tooltip, child: iconWidget);
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: iconWidget,
        ),
      ),
    );
  }
}
