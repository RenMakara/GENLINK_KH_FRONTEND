import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/glass/glass_effect.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';
import '../controllers/completion_controller.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({
    super.key,
    this.animate = true,
  });

  final bool animate;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 750);
  static const _orbitDuration = Duration(seconds: 22);

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: _entranceDuration,
  );

  late final AnimationController _orbitController = AnimationController(
    vsync: this,
    duration: _orbitDuration,
  );

  late final Animation<double> _logoEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _titleEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.12, 0.76, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _bodyEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.24, 0.86, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _illustrationEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.18, 0.88, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _ctaEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.36, 1.0, curve: Curves.easeOutCubic),
  );

  bool? _reduceMotion;

  CompletionController get controller => Get.find<CompletionController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final shouldReduceMotion =
        !widget.animate ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    if (_reduceMotion == shouldReduceMotion) return;
    _reduceMotion = shouldReduceMotion;

    if (shouldReduceMotion) {
      _entranceController.value = 1.0;
      _orbitController
        ..stop()
        ..value = 0.0;
    } else {
      if (!_entranceController.isCompleted && !_entranceController.isAnimating) {
        _entranceController.forward();
      }
      if (!_orbitController.isAnimating) {
        _orbitController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

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
                Positioned.fill(
                  child: RepaintBoundary(
                    child: _CompletionBackdrop(orbitAnimation: _orbitController),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      _CompletionBrand(entranceAnimation: _logoEntrance),
                      SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                      AnimatedBuilder(
                        animation: _titleEntrance,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, 14 * (1.0 - _titleEntrance.value)),
                          child: Opacity(
                            opacity: _titleEntrance.value,
                            child: child,
                          ),
                        ),
                        child: Text(
                          'onboarding.allSet'.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: semantic.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedBuilder(
                        animation: _bodyEntrance,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, 14 * (1.0 - _bodyEntrance.value)),
                          child: Opacity(
                            opacity: _bodyEntrance.value,
                            child: child,
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 310),
                          child: Text(
                            'onboarding.allSetBody'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: semantic.secondaryText),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? AppSpacing.sm : AppSpacing.md,
                          ),
                          child: AnimatedBuilder(
                            animation: _illustrationEntrance,
                            builder: (context, child) => Transform.scale(
                              scale: 0.94 + 0.06 * _illustrationEntrance.value,
                              child: Opacity(
                                opacity: _illustrationEntrance.value,
                                child: child,
                              ),
                            ),
                            child: RepaintBoundary(
                              child: _CompletionIllustration(
                                orbitAnimation: _orbitController,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _ctaEntrance,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, 16 * (1.0 - _ctaEntrance.value)),
                          child: Opacity(
                            opacity: _ctaEntrance.value,
                            child: child,
                          ),
                        ),
                        child: Obx(
                          () => _CompletionAction(
                            label: 'onboarding.goToGenLink'.tr,
                            loading: controller.isSaving.value,
                            onPressed: controller.goToGenLink,
                            orbitAnimation: _orbitController,
                          ),
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
  const _CompletionBrand({required this.entranceAnimation});

  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entranceAnimation,
      builder: (context, child) => Transform.scale(
        scale: 0.96 + 0.04 * entranceAnimation.value,
        child: Opacity(
          opacity: entranceAnimation.value,
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogoMark(size: 72),
          const SizedBox(height: AppSpacing.xs),
          const AppWordmark(height: 18),

        ],
      ),
    );
  }
}

class _CompletionBackdrop extends StatelessWidget {
  const _CompletionBackdrop({required this.orbitAnimation});

  final Animation<double> orbitAnimation;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: orbitAnimation,
        builder: (context, child) {
          final t = orbitAnimation.value;
          final tau = 2 * math.pi;

          // Subtle ambient floating drift for background shapes (strictly 0 at t=0)
          final dx1 = 6.0 * math.sin(tau * t);
          final dy1 = 5.0 * (1.0 - math.cos(tau * t));
          final s1 = 1.0 + 0.025 * math.sin(tau * t);

          final dx2 = -5.0 * math.sin(tau * t);
          final dy2 = 6.0 * (1.0 - math.cos(tau * t));
          final s2 = 1.0 + 0.025 * math.sin(tau * t);

          final dx3 = 4.0 * math.sin(tau * t);
          final dy3 = -4.0 * (1.0 - math.cos(tau * t));
          final s3 = 1.0 + 0.02 * math.sin(tau * t);

          return Stack(
            children: [
              Positioned(
                top: 106 + dy1,
                left: -118 + dx1,
                child: Transform.scale(
                  scale: s1,
                  child: _CompletionBlob(
                    width: 360,
                    height: 190,
                    color: AppColors.brandPrimary.withValues(
                      alpha: isDark ? 0.12 : 0.06,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 220 + dy2,
                right: -132 - dx2,
                child: Transform.scale(
                  scale: s2,
                  child: _CompletionBlob(
                    width: 360,
                    height: 220,
                    color: AppColors.communityAccent.withValues(
                      alpha: isDark ? 0.12 : 0.07,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -70 - dy3,
                left: -96 + dx3,
                child: Transform.scale(
                  scale: s3,
                  child: _CompletionBlob(
                    width: 390,
                    height: 190,
                    color: semantic.primarySoft.withValues(
                      alpha: isDark ? 0.88 : 0.9,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
  const _CompletionIllustration({required this.orbitAnimation});

  final Animation<double> orbitAnimation;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cache static cards so they are not rebuilt on animation ticks
    final communityCard = const _CompletionIconTile(
      icon: Icons.groups_rounded,
      accent: AppColors.brandPrimary,
      size: 92,
    );

    final growthCard = const _CompletionIconTile(
      icon: Icons.bar_chart_rounded,
      accent: AppColors.financeAccent,
      size: 82,
    );

    final learningCard = const _CompletionIconTile(
      icon: Icons.school_rounded,
      accent: AppColors.productivityAccent,
      size: 84,
    );

    final opportunityCard = const _CompletionIconTile(
      icon: Icons.rocket_launch_rounded,
      accent: AppColors.growthAccent,
      size: 58,
    );

    final pillContent = AppGlassSurface(
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
          _ShimmeringSparkle(orbitAnimation: orbitAnimation),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'onboarding.moreOpportunities'.tr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330, maxHeight: 330),
        child: SizedBox(
          height: 300,
          width: 330,
          child: AnimatedBuilder(
            animation: orbitAnimation,
            builder: (context, child) {
              final t = orbitAnimation.value;
              final tau = 2 * math.pi;

              // -------------------------------------------------------------
              // 1. SLOW ORBITAL ANIMATION FOR 4 FEATURE CARDS
              // Each card orbits smoothly along its own celestial path
              // with phase offsets, radii, and vertical micro-floating.
              // Strictly 0 at t=0 and t=1 for seamless loop and deterministic resting state.
              // Kept strictly upright (no self-rotation).
              // -------------------------------------------------------------

              // Blue: Community (top: 30, left: 74, size: 92)
              const theta0Community = 0.0;
              final thetaCommunity = theta0Community + tau * t + 0.14 * math.sin(tau * t);
              final dxCommunity = 22.0 * (math.cos(thetaCommunity) - math.cos(theta0Community));
              final dyCommunity = 18.0 * (math.sin(thetaCommunity) - math.sin(theta0Community)) + 3.5 * math.sin(2 * tau * t);

              // Green: Growth (top: 78, right: 16, size: 82)
              const theta0Growth = math.pi / 2;
              final thetaGrowth = theta0Growth + tau * t + 0.12 * math.sin(tau * t);
              final dxGrowth = 24.0 * (math.cos(thetaGrowth) - math.cos(theta0Growth));
              final dyGrowth = 19.0 * (math.sin(thetaGrowth) - math.sin(theta0Growth)) + 4.0 * math.sin(2 * tau * t);

              // Purple: Learning (bottom: 54, left: 38, size: 84)
              const theta0Learning = math.pi;
              final thetaLearning = theta0Learning + tau * t + 0.13 * math.sin(tau * t);
              final dxLearning = 20.0 * (math.cos(thetaLearning) - math.cos(theta0Learning));
              final dyLearning = 17.0 * (math.sin(thetaLearning) - math.sin(theta0Learning)) + 3.8 * math.sin(2 * tau * t);

              // Gold: Opportunity (right: 22, bottom: 16, size: 58)
              const theta0Opportunity = 3 * math.pi / 2;
              final thetaOpportunity = theta0Opportunity + tau * t + 0.15 * math.sin(tau * t);
              final dxOpportunity = 25.0 * (math.cos(thetaOpportunity) - math.cos(theta0Opportunity));
              final dyOpportunity = 20.0 * (math.sin(thetaOpportunity) - math.sin(theta0Opportunity)) + 4.2 * math.sin(2 * tau * t);

              // -------------------------------------------------------------
              // 2. CONNECTING DECORATIVE STROKES
              // -------------------------------------------------------------
              final spark1Dx = 4.0 * math.sin(tau * t);
              final spark1Dy = 3.0 * (1.0 - math.cos(tau * t));
              final spark1Opacity = 1.0 - 0.22 * math.pow(math.sin(tau * t), 2);
              final spark1Rot = -0.5 + 0.08 * math.sin(tau * t);

              final spark2Dx = 3.5 * math.sin(tau * t);
              final spark2Dy = 4.0 * (1.0 - math.cos(tau * t));
              final spark2Opacity = 1.0 - 0.25 * math.pow(math.sin(tau * t), 2);
              final spark2Rot = 0.4 + 0.07 * math.sin(tau * t);

              final spark3Dx = 4.5 * math.sin(tau * t);
              final spark3Dy = -3.5 * (1.0 - math.cos(tau * t));
              final spark3Opacity = 1.0 - 0.20 * math.pow(math.sin(tau * t), 2);
              final spark3Rot = -0.2 + 0.09 * math.sin(tau * t);

              // -------------------------------------------------------------
              // 3. MORE OPPORTUNITIES PILL
              // -------------------------------------------------------------
              final pillDy = 4.0 * math.sin(5 * tau * t);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blue: Community
                  Positioned(
                    top: 30 + dyCommunity,
                    left: 74 + dxCommunity,
                    child: communityCard,
                  ),

                  // Green: Growth
                  Positioned(
                    top: 78 + dyGrowth,
                    right: 16 - dxGrowth,
                    child: growthCard,
                  ),

                  // Purple: Learning
                  Positioned(
                    bottom: 54 - dyLearning,
                    left: 38 + dxLearning,
                    child: learningCard,
                  ),

                  // Gold: Opportunity
                  Positioned(
                    right: 22 - dxOpportunity,
                    bottom: 16 - dyOpportunity,
                    child: opportunityCard,
                  ),

                  // Decorative Sparks
                  Positioned(
                    top: 4 + spark1Dy,
                    left: 44 + spark1Dx,
                    child: Opacity(
                      opacity: spark1Opacity,
                      child: _Spark(
                        color: AppColors.brandPrimary,
                        rotation: spark1Rot,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 62 + spark2Dy,
                    right: 0 - spark2Dx,
                    child: Opacity(
                      opacity: spark2Opacity,
                      child: _Spark(
                        color: AppColors.growthAccent,
                        rotation: spark2Rot,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 44 + spark3Dy,
                    right: 78 - spark3Dx,
                    child: Opacity(
                      opacity: spark3Opacity,
                      child: _Spark(
                        color: AppColors.communityAccent,
                        rotation: spark3Rot,
                      ),
                    ),
                  ),

                  // "More opportunities ahead" Pill
                  Positioned(
                    left: 18,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(0, pillDy),
                      child: pillContent,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ShimmeringSparkle extends StatelessWidget {
  const _ShimmeringSparkle({required this.orbitAnimation});

  final Animation<double> orbitAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbitAnimation,
      builder: (context, child) {
        final t = orbitAnimation.value;
        final shimmer = math.pow(math.sin(5 * 2 * math.pi * t), 2).toDouble();
        final opacity = 1.0 - 0.28 * shimmer;
        final scale = 1.0 + 0.06 * shimmer;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 18,
        color: AppColors.brandPrimary,
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
    required this.orbitAnimation,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Animation<double> orbitAnimation;

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
                  AnimatedBuilder(
                    animation: orbitAnimation,
                    builder: (context, child) {
                      final t = orbitAnimation.value;
                      // Subtle 2.5px drift to the right and return (~2.75s cycle)
                      final arrowDx = 1.25 * (1.0 - math.cos(8 * 2 * math.pi * t));
                      return Transform.translate(
                        offset: Offset(arrowDx, 0),
                        child: child,
                      );
                    },
                    child: const Icon(Icons.arrow_forward_rounded, size: 22),
                  ),
                ],
              ),
      ),
    );
  }
}
