import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/config/app_config.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/glass/glass_effect.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final glass = GlassEffect(
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.9 : 0.86,
      blur: 18,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final logoSize = compact ? 148.0 : 176.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppWordmark(
                        height: 18,
                        color: semantic.primaryText,
                      ),
                    ),
                    Column(
                      children: [
                        AppGlassSurface(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          radius: AppRadius.xl,
                          blurSigma: glass.blur,
                          backgroundOpacity: glass.opacity,
                          border: Border.all(
                            color: semantic.borderSubtle,
                            width: glass.borderWidth,
                          ),
                          boxShadow: semantic.cardShadow,
                          child: AppLogoPlate(size: logoSize),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        Text(
                          AppConfig.tagline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: semantic.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppConfig.appName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: semantic.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        children: [
                          const _LoadingBar(),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'common.loadingShort'.tr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: semantic.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 5,
        child: LinearProgressIndicator(
          backgroundColor: semantic.borderSubtle,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}
