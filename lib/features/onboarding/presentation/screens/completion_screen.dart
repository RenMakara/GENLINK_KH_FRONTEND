import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/glass/glass_effect.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';
import '../controllers/completion_controller.dart';

class CompletionScreen extends GetView<CompletionController> {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;

            return Stack(
              children: [
                const Positioned.fill(child: _CompletionBackdrop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      const _CompletionBrand(),
                      SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                      Text(
                        'onboarding.allSet'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: semantic.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 310),
                        child: Text(
                          'onboarding.allSetBody'.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: semantic.secondaryText),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? AppSpacing.sm : AppSpacing.md,
                          ),
                          child: const _CompletionIllustration(),
                        ),
                      ),
                      Obx(
                        () => _CompletionAction(
                          label: 'onboarding.goToGenLink'.tr,
                          loading: controller.isSaving.value,
                          onPressed: controller.goToGenLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletionBrand extends StatelessWidget {
  const _CompletionBrand();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogoMark(size: 72),
        const SizedBox(height: AppSpacing.xs),
        AppWordmark(height: 18, color: semantic.primaryText),
      ],
    );
  }
}

class _CompletionBackdrop extends StatelessWidget {
  const _CompletionBackdrop();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 106,
            left: -118,
            child: _CompletionBlob(
              width: 360,
              height: 190,
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.12 : 0.06,
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -132,
            child: _CompletionBlob(
              width: 360,
              height: 220,
              color: AppColors.communityAccent.withValues(
                alpha: isDark ? 0.12 : 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -96,
            child: _CompletionBlob(
              width: 390,
              height: 190,
              color: semantic.primarySoft.withValues(
                alpha: isDark ? 0.88 : 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBlob extends StatelessWidget {
  const _CompletionBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xl * 3),
        ),
      ),
    );
  }
}

class _CompletionIllustration extends StatelessWidget {
  const _CompletionIllustration();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330, maxHeight: 330),
        child: SizedBox(
          height: 300,
          width: 330,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 30,
                left: 74,
                child: _CompletionIconTile(
                  icon: Icons.groups_rounded,
                  accent: AppColors.brandPrimary,
                  size: 92,
                ),
              ),
              Positioned(
                top: 78,
                right: 16,
                child: _CompletionIconTile(
                  icon: Icons.bar_chart_rounded,
                  accent: AppColors.financeAccent,
                  size: 82,
                ),
              ),
              Positioned(
                bottom: 54,
                left: 38,
                child: _CompletionIconTile(
                  icon: Icons.school_rounded,
                  accent: AppColors.productivityAccent,
                  size: 84,
                ),
              ),
              Positioned(
                right: 22,
                bottom: 16,
                child: _CompletionIconTile(
                  icon: Icons.rocket_launch_rounded,
                  accent: AppColors.growthAccent,
                  size: 58,
                ),
              ),
              Positioned(
                top: 4,
                left: 44,
                child: _Spark(color: AppColors.brandPrimary, rotation: -0.5),
              ),
              Positioned(
                top: 62,
                right: 0,
                child: _Spark(color: AppColors.growthAccent, rotation: 0.4),
              ),
              Positioned(
                bottom: 44,
                right: 78,
                child: _Spark(color: AppColors.communityAccent, rotation: -0.2),
              ),
              Positioned(
                left: 18,
                bottom: 0,
                child: AppGlassSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  radius: AppRadius.lg,
                  blurSigma: 10,
                  backgroundOpacity: isDark ? 0.78 : 0.88,
                  border: Border.all(color: semantic.borderSubtle),
                  boxShadow: const [],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: AppColors.brandPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'onboarding.moreOpportunities'.tr,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: semantic.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionIconTile extends StatelessWidget {
  const _CompletionIconTile({
    required this.icon,
    required this.accent,
    required this.size,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = GlassEffect(opacity: isDark ? 0.76 : 0.86, blur: 10);

    return AppGlassSurface(
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      blurSigma: glass.blur,
      backgroundOpacity: glass.opacity,
      border: Border.all(color: accent.withValues(alpha: 0.45)),
      boxShadow: semantic.cardShadow,
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.34 : 0.16),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Icon(icon, size: size * 0.46, color: accent),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.color, required this.rotation});

  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            height: 4,
            width: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionAction extends StatelessWidget {
  const _CompletionAction({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: semantic.primary,
          disabledBackgroundColor: semantic.primary.withValues(alpha: 0.55),
          foregroundColor: semantic.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: semantic.textInverse,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 22),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: semantic.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
}
