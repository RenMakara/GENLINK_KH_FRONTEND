import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../../../community/domain/models/community_models.dart';
import '../../../community/presentation/screens/event_details_screen.dart';
import '../../domain/entities/profile_entity.dart';

class RingedAvatar extends StatelessWidget {
  const RingedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 108,
    this.onEdit,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  static const _ringWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: size,
              width: size,
              padding: const EdgeInsets.all(_ringWidth),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.accentPremium,
                    AppColors.growthAccent,
                    AppColors.accentPremium,
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                ),
                child: AppAvatar(
                  imageUrl: imageUrl,
                  name: name,
                  size: size - (_ringWidth + 2) * 2,
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              right: 0,
              bottom: size * 0.06,
              child: SizedBox(
                height: 44,
                width: 44,
                child: Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onEdit,
                    child: Icon(Icons.edit, size: 17, color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Stack(
            children: [
              Container(height: height, color: scheme.outlineVariant),
              Container(
                height: height,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.secondary,
                      AppColors.growthAccent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        ?trailing,
      ],
    );
  }
}

class MutedText extends StatelessWidget {
  const MutedText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final BadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final earned = badge.earned;

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            child: earned
                ? _icon(scheme.onPrimary)
                : Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            badge.name.toUpperCase(),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.4,
              color: earned
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(Color color) {
    final url = badge.iconUrl;
    if (url == null || url.isEmpty) {
      return Icon(Icons.workspace_premium_outlined, size: 20, color: color);
    }
    return Padding(
      padding: const EdgeInsets.all(11),
      child: AppCachedImage(
        imageUrl: url,
        fit: BoxFit.contain,
        color: color,
        memCacheWidth: 60,
        memCacheHeight: 60,
        errorWidget:
            Icon(Icons.workspace_premium_outlined, size: 20, color: color),
      ),
    );
  }
}

/// Keeps interest treatments recognisable in both profile contexts without
/// hard-coding a light-only card colour.
class InterestVisual {
  const InterestVisual(this.icon, this.color);

  final IconData icon;
  final Color color;

  static InterestVisual of(InterestEntity interest) {
    final value = '${interest.code} ${interest.name} ${interest.category}'
        .toUpperCase();
    if (value.contains('BUSINESS')) {
      return const InterestVisual(
        Icons.business_center_outlined,
        AppColors.brandPrimary,
      );
    }
    if (value.contains('ENTREPRENEUR')) {
      return const InterestVisual(
        Icons.lightbulb_outline,
        AppColors.growthAccent,
      );
    }
    if (value.contains('FINANCE') || value.contains('FINTECH')) {
      return const InterestVisual(
        Icons.insights_outlined,
        AppColors.financeAccent,
      );
    }
    if (value.contains('CAREER') || value.contains('GROWTH')) {
      return const InterestVisual(Icons.trending_up_rounded, Color(0xFF9546D9));
    }
    if (value.contains('EDUCATION') || value.contains('LEARN')) {
      return const InterestVisual(Icons.school_outlined, Color(0xFFE65A5A));
    }
    if (value.contains('LANGUAGE')) {
      return const InterestVisual(Icons.language_rounded, Color(0xFF1097DD));
    }
    if (value.contains('HEALTH') || value.contains('WELLNESS')) {
      return const InterestVisual(
        Icons.health_and_safety_outlined,
        Color(0xFFE45A63),
      );
    }
    if (value.contains('MUSIC')) {
      return const InterestVisual(Icons.music_note_rounded, Color(0xFF8744D7));
    }
    if (value.contains('GAME')) {
      return const InterestVisual(
        Icons.sports_esports_outlined,
        Color(0xFF148B61),
      );
    }
    if (value.contains('ART') || value.contains('DESIGN')) {
      return const InterestVisual(Icons.palette_outlined, Color(0xFFE68A00));
    }
    return switch (interest.category) {
      'CAREER' => const InterestVisual(
        Icons.rocket_launch_outlined,
        AppColors.productivityAccent,
      ),
      'FINANCE' => const InterestVisual(
        Icons.payments_outlined,
        AppColors.financeAccent,
      ),
      'EDUCATION' => const InterestVisual(
        Icons.school_outlined,
        Color(0xFFE65A5A),
      ),
      'LIFESTYLE' => const InterestVisual(
        Icons.eco_outlined,
        AppColors.financeAccent,
      ),
      'ENTERTAINMENT' => const InterestVisual(
        Icons.auto_awesome_outlined,
        Color(0xFF9546D9),
      ),
      'COMMUNITY' => const InterestVisual(
        Icons.groups_outlined,
        AppColors.communityAccent,
      ),
      _ => const InterestVisual(
        Icons.interests_outlined,
        AppColors.brandPrimary,
      ),
    };
  }
}

class InterestIconTile extends StatelessWidget {
  const InterestIconTile({super.key, required this.interest, this.size = 48});

  final InterestEntity interest;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = InterestVisual.of(interest);
    final scheme = Theme.of(context).colorScheme;
    final tint = Color.alphaBlend(
      visual.color.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
      ),
      scheme.surface,
    );
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(visual.icon, color: visual.color, size: size * 0.44),
    );
  }
}

class InterestChip extends StatelessWidget {
  const InterestChip({super.key, required this.interest, this.compact = false});

  final InterestEntity interest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visual = InterestVisual.of(interest);
    final tint = Color.alphaBlend(
      visual.color.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1,
      ),
      scheme.surface,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm + 2 : AppSpacing.md,
        vertical: compact ? AppSpacing.xs + 3 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: visual.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, color: visual.color, size: compact ? 16 : 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            interest.name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: visual.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AddChipButton extends StatelessWidget {
  const AddChipButton({super.key, this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: scheme.onSurface),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label ?? 'profile.add'.tr,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedItemCard extends StatelessWidget {
  const SavedItemCard({super.key, required this.item});

  final SavedItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!item.available) {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Text(
            'profile.savedUnavailable'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final canOpen =
        (item.itemType == 'SHORT_CONTENT' || item.itemType == 'EVENT') &&
        item.itemId.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpen
              ? () {
                  if (item.itemType == 'EVENT') {
                    Get.to(
                      () => EventDetailsScreen(
                        event: EventModel(
                          id: item.itemId,
                          title: item.title ?? '',
                        ),
                      ),
                    );
                  } else {
                    Get.toNamed(
                      AppRoutes.shortContentDetail,
                      arguments: item.itemId,
                    );
                  }
                }
              : null,
          child: SizedBox(
            width: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  AppCachedImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 450,
                    errorWidget:
                        ColoredBox(color: scheme.surfaceContainerHighest),
                  )
                else
                  ColoredBox(color: scheme.surfaceContainerHighest),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemType.replaceAll('_', ' '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
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
