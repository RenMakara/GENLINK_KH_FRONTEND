import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../controllers/welcome_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  WelcomeController get controller => Get.find<WelcomeController>();

  // 1. Coordinated entrance controller (900ms)
  late final AnimationController _entranceController;

  // 2. Subtle continuous micro-animation controllers
  late final AnimationController _floatController;
  late final AnimationController _swooshController;
  late final AnimationController _badgeFloatController;
  late final AnimationController _backdropController;

  // Entrance animations
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoScale;

  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;

  late final Animation<double> _skipOpacity;
  late final Animation<Offset> _skipSlide;

  late final Animation<double> _learnOpacity;
  late final Animation<Offset> _learnSlide;

  late final Animation<double> _connectOpacity;
  late final Animation<Offset> _connectSlide;

  late final Animation<double> _growOpacity;
  late final Animation<Offset> _growSlide;

  late final Animation<double> _togetherOpacity;
  late final Animation<Offset> _togetherSlide;

  late final Animation<double> _characterOpacity;
  late final Animation<Offset> _characterSlide;
  late final Animation<double> _characterScale;

  late final Animation<double> _planeOpacity;
  late final Animation<Offset> _planeSlide;
  late final Animation<double> _planeRotation;

  late final Animation<double> _bottomCardOpacity;
  late final Animation<Offset> _bottomCardSlide;

  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonScale;

  // Continuous loop animations
  late final Animation<double> _floatOffset;
  late final Animation<double> _swooshPulse;
  late final Animation<double> _badgeFloatProgress;
  late final Animation<double> _backdropProgress;

  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();

    // ─────────────────────────────────────────────────────────────────────────
    // STAGE 1: Coordinated entrance sequence (900ms)
    // ─────────────────────────────────────────────────────────────────────────
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 0ms: Background appears smoothly
    _backdropOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    // 100ms: Logo enters (fade + scale 96% -> 100% + upward movement)
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 200ms: Headline enters (fade + slide upward)
    _headlineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.70, curve: Curves.easeOutCubic),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    // Skip button enters from top-right
    _skipOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
    );
    _skipSlide = Tween<Offset>(
      begin: const Offset(16, -6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 300ms+: Feature badges staggered entrance
    _learnOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.75, curve: Curves.easeOutCubic),
    );
    _learnSlide = Tween<Offset>(
      begin: const Offset(-28, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _connectOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
    );
    _connectSlide = Tween<Offset>(
      begin: const Offset(-28, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _growOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.82, curve: Curves.easeOutCubic),
    );
    _growSlide = Tween<Offset>(
      begin: const Offset(28, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _togetherOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
    );
    _togetherSlide = Tween<Offset>(
      begin: const Offset(28, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 400ms: Character illustration layer enters
    _characterOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );
    _characterSlide = Tween<Offset>(
      begin: const Offset(0, 18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _characterScale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 500ms: Decorative paper plane enters
    _planeOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
    );
    _planeSlide = Tween<Offset>(
      begin: const Offset(24, -12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _planeRotation = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 550ms: Bottom card enters STRICTLY FROM BELOW
    _bottomCardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
    );
    _bottomCardSlide = Tween<Offset>(
      begin: const Offset(0, 48),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // 720ms: Get Started button enters STRICTLY FROM BELOW
    _buttonOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 52),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _buttonScale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // STAGE 2: Continuous subtle micro-animations
    // ─────────────────────────────────────────────────────────────────────────
    // Characters floating loop (3.6s, +/-2.5px)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _floatOffset = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Blue swoosh connecting ring aura glow loop (4.2s)
    _swooshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _swooshPulse = CurvedAnimation(
      parent: _swooshController,
      curve: Curves.easeInOut,
    );

    // Feature badges & decorative elements continuous floating loop (4.5s)
    _badgeFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _badgeFloatProgress = CurvedAnimation(
      parent: _badgeFloatController,
      curve: Curves.easeInOut,
    );

    // Ambient background motion loop (10s)
    _backdropController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _backdropProgress = CurvedAnimation(
      parent: _backdropController,
      curve: Curves.easeInOutSine,
    );

    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final shouldReduce = (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false) ||
        !TickerMode.valuesOf(context).enabled ||
        isTesting;

    if (_reducedMotion == shouldReduce) return;
    _reducedMotion = shouldReduce;

    if (shouldReduce) {
      _floatController
        ..stop()
        ..value = 0.5;
      _swooshController
        ..stop()
        ..value = 0.0;
      _badgeFloatController
        ..stop()
        ..value = 0.0;
      _backdropController
        ..stop()
        ..value = 0.0;
    } else {
      _floatController.repeat(reverse: true);
      _swooshController.repeat(reverse: true);
      _badgeFloatController.repeat(reverse: true);
      _backdropController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _swooshController.dispose();
    _badgeFloatController.dispose();
    _backdropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Living background (welcome.png) with subtle parallax
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _backdropProgress,
                    _backdropOpacity,
                  ]),
                  builder: (context, _) => _WelcomeBackdrop(
                    progress: _reducedMotion == true
                        ? 0.0
                        : _backdropProgress.value,
                    fade: _backdropOpacity.value,
                  ),
                ),
              ),

              // 2. Foreground content layout
              SafeArea(
                child: Column(
                  children: [
                    // Top Header bar with Skip button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              if (_entranceController.isCompleted) {
                                return child!;
                              }
                              return FadeTransition(
                                opacity: _skipOpacity,
                                child: Transform.translate(
                                  offset: _skipSlide.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Obx(
                              () => _WelcomeSkipButton(
                                label: 'onboarding.skipForNow'.tr,
                                onPressed: controller.isSaving.value
                                    ? null
                                    : controller.skip,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Logo entrance
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        if (_entranceController.isCompleted) return child!;
                        return FadeTransition(
                          opacity: _logoOpacity,
                          child: Transform.translate(
                            offset: _logoSlide.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _WelcomeBrand(compact: compact),
                    ),
                    SizedBox(height: compact ? 4 : AppSpacing.xs),

                    // Headline entrance
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        if (_entranceController.isCompleted) return child!;
                        return FadeTransition(
                          opacity: _headlineOpacity,
                          child: Transform.translate(
                            offset: _headlineSlide.value,
                            child: child,
                          ),
                        );
                      },
                      child: const _WelcomeHeadline(),
                    ),

                    // Middle area: Living character illustration + floating feature badges
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Character illustration layer & blue connecting ring aura
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _entranceController,
                              _floatController,
                              _swooshController,
                            ]),
                            builder: (context, _) {
                              final floatY = _reducedMotion == true
                                  ? 0.0
                                  : _floatOffset.value;
                              final swooshAlpha = _reducedMotion == true
                                  ? 0.0
                                  : math.sin(_swooshPulse.value * math.pi);

                              final illustration = _WelcomeIllustration(
                                floatOffset: floatY,
                                swooshAlpha: swooshAlpha,
                              );

                              if (_entranceController.isCompleted) {
                                return illustration;
                              }

                              return FadeTransition(
                                opacity: _characterOpacity,
                                child: Transform.translate(
                                  offset: _characterSlide.value,
                                  child: Transform.scale(
                                    scale: _characterScale.value,
                                    child: illustration,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Floating feature badges & paper plane
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _entranceController,
                              _badgeFloatProgress,
                            ]),
                            builder: (context, _) {
                              final badgeTime = _reducedMotion == true
                                  ? 0.0
                                  : _badgeFloatProgress.value;

                              return LayoutBuilder(
                                builder: (context, midConstraints) {
                                  final w = midConstraints.maxWidth;
                                  final h = midConstraints.maxHeight;

                                  // Identical responsive card dimension (84-92px)
                                  final cardSize = (w * 0.225).clamp(84.0, 92.0);
                                  final sideMargin = (w * 0.045).clamp(14.0, 20.0);

                                  // Independent floating micro-movements (3-5px)
                                  final floatLearn = _reducedMotion == true
                                      ? 0.0
                                      : math.sin(badgeTime * 2 * math.pi) * 3.5;
                                  final floatConnect = _reducedMotion == true
                                      ? 0.0
                                      : math.sin(
                                              (badgeTime + 0.25) * 2 * math.pi) *
                                          4.0;
                                  final floatGrow = _reducedMotion == true
                                      ? 0.0
                                      : math.sin(
                                              (badgeTime + 0.50) * 2 * math.pi) *
                                          3.8;
                                  final floatTogether = _reducedMotion == true
                                      ? 0.0
                                      : math.sin(
                                              (badgeTime + 0.75) * 2 * math.pi) *
                                          4.2;

                                  final floatPlane = _reducedMotion == true
                                      ? 0.0
                                      : math.sin(
                                              (badgeTime + 0.33) * 2 * math.pi) *
                                          3.5;
                                  final rotPlane = _reducedMotion == true
                                      ? 0.0
                                      : math.cos(
                                              (badgeTime + 0.33) * 2 * math.pi) *
                                          0.02;

                                  // Maximum vertical coordinate allowing full card height
                                  final maxTop = math.max(0.0, h - cardSize);
                                  final floatScale = (h / 300.0).clamp(0.0, 1.0);

                                  // Learn & Connect (Left side) - guaranteed non-overlapping
                                  final maxLearnTop = math.max(0.0, maxTop - cardSize - 4.0);
                                  final learnTop =
                                      (h * (compact ? 0.02 : 0.04)).clamp(0.0, maxLearnTop);
                                  final minConnectTop =
                                      math.min(learnTop + cardSize + 6.0, maxTop);
                                  final connectTop = (h * (compact ? 0.38 : 0.44))
                                      .clamp(minConnectTop, maxTop);

                                  // Grow & Together (Right side) - guaranteed non-overlapping
                                  final maxGrowTop = math.max(0.0, maxTop - cardSize - 4.0);
                                  final growTop =
                                      (h * (compact ? 0.34 : 0.38)).clamp(0.0, maxGrowTop);
                                  final minTogetherTop =
                                      math.min(growTop + cardSize + 6.0, maxTop);
                                  final togetherTop = (h * (compact ? 0.68 : 0.72))
                                      .clamp(minTogetherTop, maxTop);

                                  return Stack(
                                    children: [
                                      // 1. Learn Badge (Top-Left)
                                      Positioned(
                                        left: sideMargin,
                                        top: learnTop + floatLearn * floatScale,
                                        child: _wrapEntrance(
                                          opacity: _learnOpacity,
                                          slide: _learnSlide,
                                          child: _WelcomeFeatureBadge(
                                            size: cardSize,
                                            icon: Icons.school_rounded,
                                            label:
                                                'onboarding.featureLearn'.tr,
                                            iconColor: AppColors.brandPrimary,
                                          ),
                                        ),
                                      ),

                                      // 2. Connect Badge (Mid-Left)
                                      Positioned(
                                        left: sideMargin,
                                        top: connectTop + floatConnect * floatScale,
                                        child: _wrapEntrance(
                                          opacity: _connectOpacity,
                                          slide: _connectSlide,
                                          child: _WelcomeFeatureBadge(
                                            size: cardSize,
                                            icon: Icons.groups_rounded,
                                            label:
                                                'onboarding.featureConnect'.tr,
                                            iconColor:
                                                AppColors.communityAccent,
                                          ),
                                        ),
                                      ),

                                      // 3. Paper Plane Decorative Element (Top-Right)
                                      Positioned(
                                        right: sideMargin,
                                        top: (h * (compact ? 0.01 : 0.03)).clamp(0.0, 25.0) +
                                            floatPlane * floatScale,
                                        child: _wrapEntrance(
                                          opacity: _planeOpacity,
                                          slide: _planeSlide,
                                          rotation: _planeRotation,
                                          extraRotation: rotPlane,
                                          child: const _WelcomePaperPlane(),
                                        ),
                                      ),

                                      // 4. Grow Badge (Mid-Right)
                                      Positioned(
                                        right: sideMargin,
                                        top: growTop + floatGrow * floatScale,
                                        child: _wrapEntrance(
                                          opacity: _growOpacity,
                                          slide: _growSlide,
                                          child: _WelcomeFeatureBadge(
                                            size: cardSize,
                                            icon: Icons.trending_up_rounded,
                                            label:
                                                'onboarding.featureGrow'.tr,
                                            iconColor:
                                                const Color(0xFF6366F1),
                                          ),
                                        ),
                                      ),

                                      // 5. Together Badge (Lower-Right)
                                      Positioned(
                                        right: sideMargin,
                                        top: togetherTop + floatTogether * floatScale,
                                        child: _wrapEntrance(
                                          opacity: _togetherOpacity,
                                          slide: _togetherSlide,
                                          child: _WelcomeFeatureBadge(
                                            size: cardSize,
                                            icon: Icons.favorite_rounded,
                                            label:
                                                'onboarding.featureTogether'.tr,
                                            iconColor:
                                                const Color(0xFFEC4899),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Bottom Sheet Card (enters strictly from below)
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        if (_entranceController.isCompleted) return child!;
                        return FadeTransition(
                          opacity: _bottomCardOpacity,
                          child: Transform.translate(
                            offset: _bottomCardSlide.value,
                            child: child,
                          ),
                        );
                      },
                      child: _WelcomeBottomCard(
                        onStart: controller.start,
                        buttonSlide: _buttonSlide,
                        buttonOpacity: _buttonOpacity,
                        buttonScale: _buttonScale,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _wrapEntrance({
    required Animation<double> opacity,
    required Animation<Offset> slide,
    Animation<double>? rotation,
    double extraRotation = 0.0,
    required Widget child,
  }) {
    if (_entranceController.isCompleted && extraRotation == 0.0) {
      return child;
    }

    Widget current = child;
    final rotVal = (rotation?.value ?? 0.0) + extraRotation;
    if (rotVal != 0.0) {
      current = Transform.rotate(angle: rotVal, child: current);
    }

    if (_entranceController.isCompleted) {
      return current;
    }

    return FadeTransition(
      opacity: opacity,
      child: Transform.translate(
        offset: slide.value,
        child: current,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop({
    this.progress = 0.0,
    this.fade = 1.0,
  });

  final double progress;
  final double fade;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shiftX = progress == 0.0 ? 0.0 : math.sin(progress * 2 * math.pi) * 4.0;
    final shiftY = progress == 0.0 ? 0.0 : math.cos(progress * 2 * math.pi) * 3.0;
    final scale = progress == 0.0
        ? 1.0
        : 1.0 + (math.sin(progress * 2 * math.pi) * 0.015).abs();

    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient parallax background image
            Transform.translate(
              offset: Offset(shiftX, shiftY),
              child: Transform.scale(
                scale: scale,
                child: Image.asset(
                  'assets/images/welcome.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

            // Top soft gradient for header text contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      semantic.background.withValues(alpha: isDark ? 0.85 : 0.65),
                      semantic.background.withValues(alpha: isDark ? 0.45 : 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Soft dark theme overlay
            if (isDark)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBrand extends StatelessWidget {
  const _WelcomeBrand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: compact ? 72 : 92),
        SizedBox(height: compact ? 2 : AppSpacing.xs),
        AppWordmark(
          height: compact ? 18 : 22,
        ),

      ],
    );
  }
}

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final message = 'onboarding.welcomeMessage'.tr;
    final lines = message.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0] : '';
    final secondLine = lines.length > 1 ? lines[1] : '';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: firstLine,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.25,
                ),
          ),
          if (secondLine.isNotEmpty) ...[
            const TextSpan(text: '\n'),
            TextSpan(
              text: secondLine,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.25,
                  ),
            ),
          ],
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({
    this.floatOffset = 0.0,
    this.swooshAlpha = 0.0,
  });

  final double floatOffset;
  final double swooshAlpha;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Semantics(
          label: 'GenLink students and Angkor Wat illustration',
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle glowing aura behind the blue energy ribbon
              if (swooshAlpha > 0.02)
                Positioned(
                  bottom: constraints.maxHeight * 0.08,
                  child: Transform.translate(
                    offset: Offset(0, floatOffset * 0.6),
                    child: Container(
                      width: constraints.maxWidth * 0.88,
                      height: constraints.maxHeight * 0.38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brandPrimary.withValues(
                              alpha: (swooshAlpha * 0.28).clamp(0.0, 1.0),
                            ),
                            AppColors.communityAccent.withValues(
                              alpha: (swooshAlpha * 0.16).clamp(0.0, 1.0),
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              // Characters gentle floating reference
              Positioned(
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: const SizedBox(width: 1, height: 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeFeatureBadge extends StatelessWidget {
  const _WelcomeFeatureBadge({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.size = 88.0,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semantic = context.semanticColors;

    final bgColor = isDark
        ? semantic.surface.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.90);
    final containerBg = iconColor.withValues(alpha: 0.14);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: containerBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.15,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePaperPlane extends StatelessWidget {
  const _WelcomePaperPlane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(28, 20),
              painter: _PaperPlaneTrailPainter(
                color: AppColors.brandPrimary.withValues(alpha: 0.65),
              ),
            ),
            Transform.rotate(
              angle: 0.15,
              child: const Icon(
                Icons.send_rounded,
                size: 22,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Connect.\nLearn.\nGrow.\nTogether.',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.brandPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1.15,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaperPlaneTrailPainter extends CustomPainter {
  const _PaperPlaneTrailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.3,
      size.height * 1.1,
      size.width * 0.6,
      0,
      size.width,
      size.height * 0.4,
    );

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? 3.5 : 3.0;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PaperPlaneTrailPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WelcomeBottomCard extends StatelessWidget {
  const _WelcomeBottomCard({
    required this.onStart,
    required this.buttonSlide,
    required this.buttonOpacity,
    required this.buttonScale,
    required this.compact,
  });

  final VoidCallback onStart;
  final Animation<Offset> buttonSlide;
  final Animation<double> buttonOpacity;
  final Animation<double> buttonScale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final titleParts = 'onboarding.bottomTitle'.tr.split('\n');
    final firstLine = titleParts.isNotEmpty ? titleParts[0] : '';
    final secondLine = titleParts.length > 1 ? titleParts[1] : '';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        math.max(bottomInset, compact ? 12.0 : 18.0),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 14 : 18,
        20,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? semantic.surface.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title: "A brighter future\nstarts with you"
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: firstLine,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: semantic.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 18 : 21,
                        height: 1.25,
                      ),
                ),
                if (secondLine.isNotEmpty) ...[
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: secondLine,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 18 : 21,
                          height: 1.25,
                        ),
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 4 : 6),

          // Subtitle description
          Text(
            'onboarding.bottomBody'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: semantic.secondaryText,
                  fontSize: compact ? 12 : 13,
                  height: 1.35,
                ),
          ),
          SizedBox(height: compact ? 8 : 12),

          // Pagination indicators
          const _WelcomePageIndicators(),
          SizedBox(height: compact ? 10 : 14),

          // Get Started button (rises strictly from bottom inside card)
          AnimatedBuilder(
            animation: buttonSlide,
            builder: (context, child) {
              return FadeTransition(
                opacity: buttonOpacity,
                child: Transform.translate(
                  offset: buttonSlide.value,
                  child: Transform.scale(
                    scale: buttonScale.value,
                    child: child,
                  ),
                ),
              );
            },
            child: _WelcomeAction(
              label: 'onboarding.getStarted'.tr,
              onPressed: onStart,
            ),
          ),
        ],
      ),
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
            duration: const Duration(milliseconds: 240),
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

class _WelcomeAction extends StatefulWidget {
  const _WelcomeAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_WelcomeAction> createState() => _WelcomeActionState();
}

class _WelcomeActionState extends State<_WelcomeAction> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: semantic.primary,
              foregroundColor: semantic.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              elevation: 0,
            ),
            // Centered text only. NO arrow icon.
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: semantic.textInverse,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSkipButton extends StatefulWidget {
  const _WelcomeSkipButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_WelcomeSkipButton> createState() => _WelcomeSkipButtonState();
}

class _WelcomeSkipButtonState extends State<_WelcomeSkipButton> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: semantic.secondaryText,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: semantic.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: semantic.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
