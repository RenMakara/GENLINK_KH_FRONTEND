import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'community_creation_flow.dart';

/// Compact "Share something" entry point for the community feed.
///
/// Features the user's avatar and a pill-shaped input capsule ("Share something with your community...").
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasOptionalActions =
        onTapPost != null || onTapDiscussion != null || onTapEvent != null;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => CommunityCreationFlow.openCreatePost(context),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B1E) : semantic.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: semantic.borderSubtle.withValues(
                  alpha: isDark ? 0.6 : 1.0,
                ),
                width: 0.8,
              ),
              boxShadow: semantic.cardShadow,
            ),
            child: Row(
              children: [
                buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: semantic.secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: semantic.secondaryText,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  fontFamilyFallback: const [
                                    'KantumruyPro',
                                    'Sora',
                                  ],
                                ) ??
                                TextStyle(
                                  color: semantic.secondaryText,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  fontFamilyFallback: const [
                                    'KantumruyPro',
                                    'Sora',
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasOptionalActions) ...[
                  const SizedBox(width: 8),
                  _buildOptionalActionIcons(semantic),
                ],
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
