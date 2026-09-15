import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/glass/glass_effect.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  AuthBrandLockup(markSize: 26, wordmarkHeight: 14),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: Text('common.skip'.tr),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.slides.length,
                itemBuilder: (context, index) =>
                    _Slide(slide: OnboardingController.slides[index]),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Obx(
                  () => Column(
                    children: [
                      _OnboardingAction(
                        label: controller.isLastPage
                            ? 'onboarding.getStarted'.tr
                            : 'common.next'.tr,
                        onPressed: () => controller.next(),
                      ),
                      AppButton.text(
                        label: 'onboarding.skipForNow'.tr,
                        muted: true,
                        onPressed: controller.finish,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);
    final title = slide.titleKey.tr;
    final lines = title.split('\n');
    final titleStyle = (theme.textTheme.headlineLarge ?? const TextStyle())
        .copyWith(color: semantic.primaryText, fontWeight: FontWeight.w700);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 600;
        final visualHeight = compact ? 218.0 : 270.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    for (var index = 0; index < lines.length; index++) ...[
                      TextSpan(
                        text: lines[index],
                        style: titleStyle.copyWith(
                          color: index == lines.length - 1
                              ? AppColors.brandPrimary
                              : semantic.primaryText,
                        ),
                      ),
                      if (index != lines.length - 1) const TextSpan(text: '\n'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                slide.bodyKey.tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: semantic.secondaryText,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              _SlideVisual(slide: slide, height: visualHeight),
              const SizedBox(height: AppSpacing.md),
              const Center(child: _Dots()),
            ],
          ),
        );
      },
    );
  }
}

class _SlideVisual extends StatelessWidget {
  const _SlideVisual({required this.slide, required this.height});

  final OnboardingSlide slide;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (slide.visual) {
      OnboardingVisual.network => _NetworkVisual(
        rows: slide.rows,
        height: height,
      ),
      OnboardingVisual.growth => _GrowthVisual(
        rows: slide.rows,
        height: height,
      ),
      OnboardingVisual.impact => _ImpactVisual(
        rows: slide.rows,
        height: height,
      ),
      OnboardingVisual.future => _FutureVisual(
        rows: slide.rows,
        height: height,
      ),
    };
  }
}

class _VisualFrame extends StatelessWidget {
  const _VisualFrame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = GlassEffect(opacity: isDark ? 0.9 : 0.94, blur: 14);

    return AppGlassSurface(
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      blurSigma: glass.blur,
      backgroundOpacity: glass.opacity,
      border: Border.all(
        color: semantic.borderSubtle,
        width: glass.borderWidth,
      ),
      boxShadow: semantic.cardShadow,
      child: SizedBox(height: height, width: double.infinity, child: child),
    );
  }
}

class _NetworkVisual extends StatelessWidget {
  const _NetworkVisual({required this.rows, required this.height});

  final List<OnboardingRow> rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _VisualFrame(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: ColoredBox(color: semantic.primarySoft)),
          Positioned(
            top: -48,
            right: -30,
            child: _SoftCircle(
              size: 170,
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.14 : 0.08,
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: 30,
            child: _SoftCircle(
              size: 150,
              color: AppColors.communityAccent.withValues(
                alpha: isDark ? 0.2 : 0.14,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: height * 0.2,
            child: Icon(
              Icons.account_balance_outlined,
              size: height * 0.48,
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.32 : 0.2,
              ),
            ),
          ),
          Positioned(left: 16, top: 16, child: _FeaturePill(row: rows.first)),
          Positioned(
            right: 14,
            bottom: height * 0.18,
            child: _FeaturePill(row: rows[1]),
          ),
          Positioned(
            left: 18,
            bottom: 0,
            child: _PeopleGroup(height: height * 0.7),
          ),
        ],
      ),
    );
  }
}

class _GrowthVisual extends StatelessWidget {
  const _GrowthVisual({required this.rows, required this.height});

  final List<OnboardingRow> rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _VisualFrame(
      height: height,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: semantic.primarySoft,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColors.financeAccent.withValues(
                      alpha: isDark ? 0.24 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 19,
                    color: AppColors.financeAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'onboarding.growthSnapshot'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: semantic.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final row in rows) ...[
              _PreviewRow(row: row, compact: true),
              if (row != rows.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImpactVisual extends StatelessWidget {
  const _ImpactVisual({required this.rows, required this.height});

  final List<OnboardingRow> rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _VisualFrame(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ColoredBox(color: semantic.backgroundSecondary),
          ),
          Positioned(
            left: -38,
            bottom: -54,
            child: _SoftCircle(
              size: 230,
              color: AppColors.communityAccent.withValues(
                alpha: isDark ? 0.18 : 0.12,
              ),
            ),
          ),
          Positioned(
            right: -26,
            bottom: -72,
            child: _SoftCircle(
              size: 245,
              color: AppColors.growthAccent.withValues(
                alpha: isDark ? 0.18 : 0.12,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 10,
            child: Icon(
              Icons.account_balance_rounded,
              size: height * 0.47,
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.38 : 0.22,
              ),
            ),
          ),
          Positioned(left: 14, top: 18, child: _FeaturePill(row: rows[0])),
          Positioned(
            right: 12,
            top: height * 0.32,
            child: _FeaturePill(row: rows[1]),
          ),
          Positioned(
            left: 42,
            bottom: height * 0.15,
            child: _FeaturePill(row: rows[2]),
          ),
        ],
      ),
    );
  }
}

class _FutureVisual extends StatelessWidget {
  const _FutureVisual({required this.rows, required this.height});

  final List<OnboardingRow> rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final globeSize = height * 0.7;

    return _VisualFrame(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: ColoredBox(color: semantic.primarySoft)),
          Positioned(
            right: -28,
            top: -54,
            child: _SoftCircle(
              size: 190,
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: height * 0.1,
            child: Container(
              height: globeSize,
              width: globeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.24 : 0.12,
                ),
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(
                    alpha: isDark ? 0.7 : 0.38,
                  ),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.public_rounded,
                size: globeSize * 0.65,
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.9 : 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: height * 0.18,
            child: _FloatingAvatar(accent: rows[0].accent, size: 46),
          ),
          Positioned(
            left: 8,
            bottom: height * 0.18,
            child: _FloatingAvatar(accent: rows[1].accent, size: 40),
          ),
          Positioned(
            right: height * 0.56,
            bottom: height * 0.08,
            child: _FloatingAvatar(accent: rows[2].accent, size: 38),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _FutureBadge(label: 'onboarding.togetherWeGrow'.tr),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.row});

  final OnboardingRow row;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppGlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      radius: AppRadius.pill,
      blurSigma: 8,
      backgroundOpacity: isDark ? 0.84 : 0.9,
      border: Border.all(color: semantic.borderSubtle),
      boxShadow: const [],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: row.accent.withValues(alpha: isDark ? 0.24 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(row.icon, size: 15, color: row.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            row.titleKey.tr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: semantic.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleGroup extends StatelessWidget {
  const _PeopleGroup({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PersonIllustration(height: height, accent: AppColors.communityAccent),
        const SizedBox(width: AppSpacing.sm),
        _PersonIllustration(
          height: height * 0.86,
          accent: AppColors.productivityAccent,
        ),
      ],
    );
  }
}

class _PersonIllustration extends StatelessWidget {
  const _PersonIllustration({required this.height, required this.accent});

  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final headSize = height * 0.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: headSize,
          width: headSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: semantic.surface,
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2),
          ),
          child: Icon(
            Icons.person_rounded,
            size: headSize * 0.68,
            color: accent,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: height * 0.62,
          width: height * 0.45,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            border: Border.all(
              color: semantic.surface.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: height * 0.16,
            color: semantic.textInverse,
          ),
        ),
      ],
    );
  }
}

class _FloatingAvatar extends StatelessWidget {
  const _FloatingAvatar({required this.accent, required this.size});

  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: semantic.surface,
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
        boxShadow: semantic.cardShadow,
      ),
      child: Icon(Icons.person_rounded, size: size * 0.58, color: accent),
    );
  }
}

class _FutureBadge extends StatelessWidget {
  const _FutureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: semantic.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.row, this.compact = false});

  final OnboardingRow row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: semantic.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: compact ? 28 : 32,
                width: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: row.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Icon(
                  row.icon,
                  size: compact ? 15 : 17,
                  color: row.accent,
                ),
              ),
              SizedBox(width: compact ? AppSpacing.sm : AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.titleKey.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? theme.textTheme.labelMedium
                                  : theme.textTheme.titleSmall)
                              ?.copyWith(color: semantic.primaryText),
                    ),
                    if (row.progress == null)
                      Text(
                        row.detailKey.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? theme.textTheme.labelSmall
                                    : theme.textTheme.bodySmall)
                                ?.copyWith(color: semantic.secondaryText),
                      ),
                  ],
                ),
              ),
              if (row.progress != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  row.detailKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? theme.textTheme.labelSmall
                              : theme.textTheme.bodySmall)
                          ?.copyWith(color: semantic.secondaryText),
                ),
              ],
            ],
          ),
          if (row.progress != null) ...[
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: row.progress,
                minHeight: compact ? 2 : 3,
                backgroundColor: semantic.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(row.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Obx(
      () => Row(
        children: List.generate(
          OnboardingController.slides.length,
          (index) => _Dot(active: controller.currentPage.value == index),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(right: AppSpacing.xs + 2),
      height: 6,
      width: active ? 24 : 6,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : semantic.borderStrong,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _OnboardingAction extends StatelessWidget {
  const _OnboardingAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: semantic.primary,
          foregroundColor: semantic.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: Row(
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
