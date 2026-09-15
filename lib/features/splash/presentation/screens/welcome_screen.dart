import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../controllers/welcome_controller.dart';

class WelcomeScreen extends GetView<WelcomeController> {
  const WelcomeScreen({super.key});

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
                const Positioned.fill(child: _WelcomeBackdrop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      const _WelcomeBrand(),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      Text(
                        'onboarding.welcomeMessage'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: semantic.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                          ),
                          child: const _WelcomeIllustration(),
                        ),
                      ),
                      const _WelcomePageIndicators(),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      _WelcomeAction(
                        label: 'onboarding.getStarted'.tr,
                        onPressed: controller.start,
                      ),
                      Obx(
                        () => TextButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.skip,
                          style: TextButton.styleFrom(
                            foregroundColor: semantic.secondaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          child: Text('onboarding.skipForNow'.tr),
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

class _WelcomeBrand extends StatelessWidget {
  const _WelcomeBrand();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogoMark(size: 104),
        const SizedBox(height: AppSpacing.xs),
        AppWordmark(height: 23, color: semantic.primaryText),
      ],
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/images/onboard-image.png',
            width: constraints.maxWidth,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            semanticLabel: 'GenLink students and Angkor Wat illustration',
          ),
        );
      },
    );
  }
}

class _WelcomePageIndicators extends StatelessWidget {
  const _WelcomePageIndicators();

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Semantics(
      label: 'Step 1 of $_totalSteps',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _totalSteps,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(
              right: index == _totalSteps - 1 ? 0 : AppSpacing.xs,
            ),
            height: 6,
            width: index == 0 ? 24 : 7,
            decoration: BoxDecoration(
              color: index == 0
                  ? AppColors.brandPrimary
                  : semantic.borderStrong,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              semantic.background,
              isDark
                  ? AppColors.brandPrimary.withValues(alpha: 0.08)
                  : semantic.background,
              semantic.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 108,
              left: -120,
              child: _BackdropBlob(
                width: 370,
                height: 190,
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.12 : 0.05,
                ),
              ),
            ),
            Positioned(
              top: 240,
              right: -140,
              child: _BackdropBlob(
                width: 370,
                height: 220,
                color: AppColors.communityAccent.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              left: -128,
              child: _BackdropBlob(
                width: 410,
                height: 190,
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.14 : 0.07,
                ),
              ),
            ),
            Positioned(
              bottom: -88,
              right: -100,
              child: _BackdropBlob(
                width: 350,
                height: 190,
                color: semantic.primarySoft.withValues(
                  alpha: isDark ? 0.9 : 0.94,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({
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

class _WelcomeAction extends StatelessWidget {
  const _WelcomeAction({required this.label, required this.onPressed});

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
