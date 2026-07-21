import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../domain/entities/profile_entity.dart';

/// Avatar inside a gradient ring, with a small edit affordance.
class RingedAvatar extends StatelessWidget {
  const RingedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 108,
    this.onEdit,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onEdit;

  static const _ringWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Container(
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
          if (onEdit != null)
            Positioned(
              right: 0,
              bottom: size * 0.06,
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit,
                      size: 13,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill with a leading accent dot, used for the work-status label.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentPremium.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.growthAccent,
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

/// Progress bar that fades from the text colour into the premium accent.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
  });

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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.lightPrimary,
                      AppColors.accentPremium,
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

/// Section title with an optional trailing action.
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

/// One achievement: a circular icon plus its name.
///
/// Locked badges are dimmed and show a padlock instead of their icon, so
/// the row communicates what is still available without a second section.
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

  /// The catalog ships an `iconUrl`; fall back to a generic medal when it
  /// is missing so an unseeded badge still renders.
  Widget _icon(Color color) {
    final url = badge.iconUrl;
    if (url == null || url.isEmpty) {
      return Icon(Icons.workspace_premium_outlined, size: 20, color: color);
    }
    return Padding(
      padding: const EdgeInsets.all(11),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        color: color,
        errorBuilder: (_, _, _) =>
            Icon(Icons.workspace_premium_outlined, size: 20, color: color),
      ),
    );
  }
}

/// An interest rendered as an expertise chip.
class ExpertiseChip extends StatelessWidget {
  const ExpertiseChip({
    super.key,
    required this.label,
    this.emphasised = false,
  });

  final String label;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: emphasised
            ? scheme.primary
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: emphasised ? Colors.transparent : scheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: emphasised ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
    );
  }
}

/// The "+" affordance at the end of the expertise chips.
class AddChipButton extends StatelessWidget {
  const AddChipButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Icon(Icons.add, size: 18, color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// A saved item tile: cover image with the category and title over it.
class SavedItemCard extends StatelessWidget {
  const SavedItemCard({super.key, required this.item});

  final SavedItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // saved_items is polymorphic, so a row can outlive what it points at.
    if (!item.available) {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              )
            else
              ColoredBox(color: scheme.surfaceContainerHighest),
            // Scrim so the label stays readable over any cover.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
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
                      color: Colors.white70,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
