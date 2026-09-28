import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
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

  // 1. Entrance animation controller (900ms)
  late final AnimationController _entranceController;

  // 2. Subtle continuous micro-animation controllers
  late final AnimationController _orbitalController;
  late final AnimationController _floatController;
  late final AnimationController _backdropController;

  // Entrance animations
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _backdropScale;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoScale;

  late final Animation<double> _skipOpacity;

  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;

  late final Animation<double> _subOpacity;
  late final Animation<Offset> _subSlide;

  late final Animation<double> _orbitalOpacity;

  late final Animation<double> _learnOpacity;
  late final Animation<Offset> _learnSlide;
  late final Animation<double> _learnScale;

  late final Animation<double> _growOpacity;
  late final Animation<Offset> _growSlide;
  late final Animation<double> _growScale;

  late final Animation<double> _connectOpacity;
  late final Animation<Offset> _connectSlide;
  late final Animation<double> _connectScale;

  late final Animation<double> _togetherOpacity;
  late final Animation<Offset> _togetherSlide;
  late final Animation<double> _togetherScale;

  late final Animation<double> _benefitsCardOpacity;
  late final Animation<Offset> _benefitsCardSlide;
  late final Animation<double> _benefitsCardScale;

  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  // Continuous micro-animation outputs
  late final Animation<double> _orbitalProgress;
  late final Animation<double> _floatProgress;
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

    // 0ms: Background arrives smoothly (fade + scale 1.02 -> 1.0)
    _backdropOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
    );
    _backdropScale = Tween<double>(begin: 1.02, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // 80ms: Logo enters (fade + scale 0.85 -> 1.0 + slight upward slide)
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Skip button enters
    _skipOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOutCubic),
    );

    // 160ms: Headline enters (fade + upward slide)
    _headlineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // 220ms: Supporting text enters (fade + upward slide)
    _subOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.68, curve: Curves.easeOutCubic),
    );
    _subSlide = Tween<Offset>(
      begin: const Offset(0, 14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 260ms: Orbital system enters
    _orbitalOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.26, 0.70, curve: Curves.easeOutCubic),
    );

    // 300ms+: Staggered feature cards entrance: Learn -> Grow -> Connect -> Together
    // 1. Learn (Top-Left)
    _learnOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.74, curve: Curves.easeOutCubic),
    );
    _learnSlide = Tween<Offset>(
      begin: const Offset(-20, 12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.74, curve: Curves.easeOutCubic),
      ),
    );
    _learnScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Grow (Top-Right)
    _growOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.80, curve: Curves.easeOutCubic),
    );
    _growSlide = Tween<Offset>(
      begin: const Offset(20, 12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _growScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Connect (Bottom-Left)
    _connectOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.84, curve: Curves.easeOutCubic),
    );
    _connectSlide = Tween<Offset>(
      begin: const Offset(-20, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.84, curve: Curves.easeOutCubic),
      ),
    );
    _connectScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Together (Bottom-Right)
    _togetherOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
    );
    _togetherSlide = Tween<Offset>(
      begin: const Offset(20, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _togetherScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 580ms: Bottom Benefits Card enters from below
    _benefitsCardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.58, 0.92, curve: Curves.easeOutCubic),
    );
    _benefitsCardSlide = Tween<Offset>(
      begin: const Offset(0, 36),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.58, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _benefitsCardScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.58, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // 680ms: Get Started Button enters strictly from below
    _buttonOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 36),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // STAGE 2: Continuous micro-animations
    // ─────────────────────────────────────────────────────────────────────────
    // Orbital rotation & node movement loop (7s)
    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );
    _orbitalProgress = CurvedAnimation(
      parent: _orbitalController,
      curve: Curves.linear,
    );

    // Feature cards floating loop (4.2s, ±3.5px)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _floatProgress = CurvedAnimation(
      parent: _floatController,
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
      _orbitalController
        ..stop()
        ..value = 0.0;
      _floatController
        ..stop()
        ..value = 0.5;
      _backdropController
        ..stop()
        ..value = 0.0;
    } else {
      _orbitalController.repeat();
      _floatController.repeat(reverse: true);
      _backdropController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitalController.dispose();
    _floatController.dispose();
    _backdropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 720;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Living background (welcome.png) with theme-aware atmosphere
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _backdropProgress,
                    _backdropOpacity,
                    _backdropScale,
                  ]),
                  builder: (context, _) => _WelcomeBackdrop(
                    progress: _reducedMotion == true
                        ? 0.0
                        : _backdropProgress.value,
                    fade: _backdropOpacity.value,
                    scale: _backdropScale.value,
                  ),
                ),
              ),

              // 2. Foreground content layout wrapped in SafeArea
              SafeArea(
                child: Column(
                  children: [
                    // Top Header bar with Skip button
                    _buildTopBar(context),

                    // GenLink Logo Lockup (prominent brand anchor)
                    _buildLogo(compact),

                    SizedBox(height: compact ? 3 : 5),

                    // Welcome Headline with GenLink Brand Gradient
                    _buildHeadline(compact),

                    SizedBox(height: compact ? 4 : 6),

                    // Supporting Subtitle
                    _buildSupportingText(compact),

                    // Middle area: Orbital System + Angkor Wat framing + 4 Feature Cards
                    Expanded(
                      child: _buildMiddleStage(compact),
                    ),

                    // Bottom Benefits Card (refined translucent glass)
                    _buildBenefitsCard(compact),

                    SizedBox(height: compact ? 10 : 14),

                    // Get Started Button
                    _buildActionButton(compact),

                    SizedBox(
                      height: math.max(
                        bottomInset > 0 ? 4.0 : 12.0,
                        compact ? 6.0 : 10.0,
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

  // ───────────────────────────────────────────────────────────────────────────
  // Layout builders
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              if (_entranceController.isCompleted) return child!;
              return FadeTransition(opacity: _skipOpacity, child: child);
            },
            child: Obx(
              () => _WelcomeSkipButton(
                label: 'onboarding.skipForNow'.tr,
                onPressed: controller.isSaving.value ? null : controller.skip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool compact) {
    return AnimatedBuilder(
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
    );
  }

  Widget _buildHeadline(bool compact) {
    return AnimatedBuilder(
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
      child: _WelcomeHeadline(compact: compact),
    );
  }

  Widget _buildSupportingText(bool compact) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _subOpacity,
          child: Transform.translate(
            offset: _subSlide.value,
            child: child,
          ),
        );
      },
      child: _WelcomeSupportingText(compact: compact),
    );
  }

  Widget _buildMiddleStage(bool compact) {
    return LayoutBuilder(
      builder: (context, midConstraints) {
        final mw = midConstraints.maxWidth;
        final mh = midConstraints.maxHeight;

        // Identical responsive square card dimensions (84 - 94px)
        final cardSize = (mw * 0.23).clamp(84.0, 94.0);
        final sideMargin = (mw * 0.05).clamp(16.0, 26.0);

        // Guarantees non-overlapping vertical separation
        final topCardsY = (mh * (compact ? 0.01 : 0.03)).clamp(4.0, 24.0);
        final maxBottom = math.max(0.0, mh - cardSize - 4.0);
        final minBottom = math.min(topCardsY + cardSize + 12.0, maxBottom);
        final bottomCardsY =
            (mh * (compact ? 0.48 : 0.52)).clamp(minBottom, maxBottom);

        // Floating micro-movements (±3.5px) with phased offsets
        final floatTime =
            _reducedMotion == true ? 0.0 : _floatProgress.value;
        final floatScale = (mh / 260.0).clamp(0.0, 1.0);
        final floatLearn =
            math.sin(floatTime * 2 * math.pi) * 3.5 * floatScale;
        final floatGrow =
            math.sin((floatTime + 0.35) * 2 * math.pi) * 3.5 * floatScale;
        final floatConnect =
            math.sin((floatTime + 0.70) * 2 * math.pi) * 3.5 * floatScale;
        final floatTogether =
            math.sin((floatTime + 0.52) * 2 * math.pi) * 3.5 * floatScale;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Orbital system with moving nodes and silky translucent ribbon
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _orbitalProgress,
                  _entranceController,
                ]),
                builder: (context, _) => Opacity(
                  opacity: _orbitalOpacity.value,
                  child: _WelcomeOrbitalSystem(
                    progress: _reducedMotion == true
                        ? 0.0
                        : _orbitalProgress.value,
                    size: Size(mw, mh),
                  ),
                ),
              ),
            ),

            // 2. Learn Card (Top-Left)
            Positioned(
              left: sideMargin,
              top: topCardsY + floatLearn,
              child: _wrapEntrance(
                opacity: _learnOpacity,
                slide: _learnSlide,
                scale: _learnScale,
                child: _WelcomeFeatureBadge(
                  size: cardSize,
                  label: 'onboarding.featureLearn'.tr,
                  assetPath: 'assets/splash/learning.png',
                  fallbackIcon: Icons.school_rounded,
                  accentColor: const Color(0xFF2563EB),
                ),
              ),
            ),

            // 3. Grow Card (Top-Right)
            Positioned(
              right: sideMargin,
              top: topCardsY + floatGrow,
              child: _wrapEntrance(
                opacity: _growOpacity,
                slide: _growSlide,
                scale: _growScale,
                child: _WelcomeFeatureBadge(
                  size: cardSize,
                  label: 'onboarding.featureGrow'.tr,
                  assetPath: 'assets/splash/growth.png',
                  fallbackIcon: Icons.trending_up_rounded,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ),

            // 4. Connect Card (Bottom-Left)
            Positioned(
              left: sideMargin,
              top: bottomCardsY + floatConnect,
              child: _wrapEntrance(
                opacity: _connectOpacity,
                slide: _connectSlide,
                scale: _connectScale,
                child: _WelcomeFeatureBadge(
                  size: cardSize,
                  label: 'onboarding.featureConnect'.tr,
                  assetPath: 'assets/splash/community.png',
                  fallbackIcon: Icons.groups_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
            ),

            // 5. Together Card (Bottom-Right)
            Positioned(
              right: sideMargin,
              top: bottomCardsY + floatTogether,
              child: _wrapEntrance(
                opacity: _togetherOpacity,
                slide: _togetherSlide,
                scale: _togetherScale,
                child: _WelcomeFeatureBadge(
                  size: cardSize,
                  label: 'onboarding.featureTogether'.tr,
                  assetPath: null,
                  fallbackIcon: Icons.favorite_rounded,
                  accentColor: const Color(0xFFEC4899),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitsCard(bool compact) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _benefitsCardOpacity,
          child: Transform.translate(
            offset: _benefitsCardSlide.value,
            child: Transform.scale(
              scale: _benefitsCardScale.value,
              child: child,
            ),
          ),
        );
      },
      child: _WelcomeBenefitsCard(compact: compact),
    );
  }

  Widget _buildActionButton(bool compact) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _buttonOpacity,
          child: Transform.translate(
            offset: _buttonSlide.value,
            child: child,
          ),
        );
      },
      child: _WelcomeAction(
        label: 'onboarding.getStarted'.tr,
        onPressed: controller.start,
        height: compact ? 52.0 : 56.0,
      ),
    );
  }

  Widget _wrapEntrance({
    required Animation<double> opacity,
    required Animation<Offset> slide,
    required Animation<double> scale,
    required Widget child,
  }) {
    if (_entranceController.isCompleted) return child;
    return FadeTransition(
      opacity: opacity,
      child: Transform.translate(
        offset: slide.value,
        child: Transform.scale(
          scale: scale.value,
          child: child,
        ),
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
    this.scale = 1.0,
  });

  final double progress;
  final double fade;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shiftX =
        progress == 0.0 ? 0.0 : math.sin(progress * 2 * math.pi) * 3.0;
    final shiftY =
        progress == 0.0 ? 0.0 : math.cos(progress * 2 * math.pi) * 2.0;

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

            // Top soft gradient overlay for logo & headline readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0A1128).withValues(alpha: 0.72),
                            const Color(0xFF0A1128).withValues(alpha: 0.22),
                            Colors.transparent,
                          ]
                        : [
                            semantic.background.withValues(alpha: 0.55),
                            semantic.background.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.60, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom soft gradient overlay for benefits card & CTA readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0F172A).withValues(alpha: 0.78),
                            const Color(0xFF0F172A).withValues(alpha: 0.22),
                            Colors.transparent,
                          ]
                        : [
                            semantic.background.withValues(alpha: 0.60),
                            semantic.background.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Dark theme twilight atmosphere (preserves Angkor Wat in the middle)
            if (isDark)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A1128).withValues(alpha: 0.62), // Deep night sky
                        const Color(0xFF0F2042).withValues(alpha: 0.28), // Translucent over Angkor Wat
                        const Color(0xFF13152C).withValues(alpha: 0.65), // Deep navy water
                      ],
                      stops: const [0.0, 0.44, 1.0],
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

class _WelcomeBrand extends StatelessWidget {
  const _WelcomeBrand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // +25-28% prominent brand anchor sizing
    final markHeight = compact ? 58.0 : 70.0;
    final textHeight = compact ? 15.0 : 18.5;

    final logoAsset = isDark
        ? 'assets/splash/genlink-gl-dark.png'
        : 'assets/splash/genlink-gl-logo.png';

    return Semantics(
      label: 'GenLink KH logo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // GL Logo Mark
          Image.asset(
            logoAsset,
            height: markHeight,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                AppLogoMark(size: markHeight),
          ),
          const SizedBox(height: 6),
          // GENLINK [KH] wordmark
          if (isDark)
            ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: Image.asset(
                'assets/splash/genlink-kh-text.png',
                height: textHeight,
                fit: BoxFit.contain,
              ),
            )
          else
            Image.asset(
              'assets/splash/genlink-kh-text.png',
              height: textHeight,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isKhmer = Get.locale?.languageCode == 'km';

    final line1 = 'onboarding.welcomeHeadline1'.tr;
    final line2 = 'onboarding.welcomeHeadline2'.tr;

    final baseFamily = isKhmer
        ? AppTypography.khmerFontFamily
        : AppTypography.englishFontFamily;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Line 1: "Welcome to" / "ស្វាគមន៍មកកាន់"
        Text(
          line1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: semantic.primaryText,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 26 : 30,
            height: 1.15,
            letterSpacing: -0.5,
            fontFamily: baseFamily,
          ),
        ),
        const SizedBox(height: 2),
        // Line 2: "GenLink" with signature GenLink Blue -> Cyan/Teal Brand Gradient
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AppColors.brandGradient.createShader(bounds),
          child: Text(
            line2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, // Required for ShaderMask rendering
              fontWeight: FontWeight.w800,
              fontSize: compact ? 28 : 34,
              height: 1.15,
              letterSpacing: -0.5,
              fontFamily: baseFamily,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeSupportingText extends StatelessWidget {
  const _WelcomeSupportingText({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Get.locale?.languageCode == 'km';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        'onboarding.welcomeSub'.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : semantic.secondaryText,
          fontWeight: FontWeight.w400,
          fontSize: compact ? 12.5 : 13.5,
          height: 1.4,
          fontFamily: isKhmer
              ? AppTypography.khmerFontFamily
              : AppTypography.englishFontFamily,
        ),
      ),
    );
  }
}

class _WelcomeOrbitalSystem extends StatelessWidget {
  const _WelcomeOrbitalSystem({
    required this.progress,
    required this.size,
  });

  final double progress;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: _OrbitalPainter(progress: progress),
      ),
    );
  }
}

class _OrbitalPainter extends CustomPainter {
  const _OrbitalPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final center = Offset(w * 0.5, h * 0.46);
    final rx = w * 0.44;
    final ry = h * 0.28;
    const tilt = -0.16; // ~ -9 degrees tilt

    // 1. Draw glowing orbital ellipse
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0x3038BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      glowPaint,
    );

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = const LinearGradient(
        colors: [
          Color(0x6038BDF8),
          Color(0x70818CF8),
          Color(0x80F472B6),
          Color(0x6038BDF8),
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      strokePaint,
    );

    // 2. Draw 4 floating glowing orbital pearls
    const nodeColors = [
      Color(0xFF38BDF8), // Cyan
      Color(0xFF818CF8), // Indigo
      Color(0xFFF472B6), // Pink
      Color(0xFF34D399), // Emerald
    ];

    for (int i = 0; i < nodeColors.length; i++) {
      final angle = (progress + (i * 0.25)) * 2 * math.pi;
      final nx = rx * math.cos(angle);
      final ny = ry * math.sin(angle);

      // Node aura glow
      final nodeGlow = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(nx, ny), 5.5, nodeGlow);

      // Node solid bead
      final nodeCore = Paint()..color = nodeColors[i];
      canvas.drawCircle(Offset(nx, ny), 3.2, nodeCore);

      // Node specular highlight
      final nodeSpec = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(nx - 0.8, ny - 0.8), 1.0, nodeSpec);
    }

    canvas.restore();

    // 3. Draw soft translucent silk ribbon sweep across reflection pool
    final ribbonPath = Path();
    ribbonPath.moveTo(0, h * 0.88);
    ribbonPath.cubicTo(
      w * 0.35,
      h * 0.76,
      w * 0.65,
      h * 0.96,
      w,
      h * 0.82,
    );

    final ribbonGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = const Color(0x2538BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(ribbonPath, ribbonGlow);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [
          Color(0x3538BDF8),
          Color(0x45C084FC),
          Color(0x40F472B6),
          Color(0x1538BDF8),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25));
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WelcomeFeatureBadge extends StatelessWidget {
  const _WelcomeFeatureBadge({
    required this.size,
    required this.label,
    required this.accentColor,
    this.assetPath,
    this.fallbackIcon = Icons.star_rounded,
  });

  final double size;
  final String label;
  final Color accentColor;
  final String? assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Get.locale?.languageCode == 'km';

    // In Dark Mode: use refined translucent glass (rgba(255,255,255, 0.11))
    // In Light Mode: use white translucent glass
    final bgColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.11)
        : Colors.white.withValues(alpha: 0.90);

    // Visible translucent border with subtle accent tint in dark mode
    final borderColor = isDark
        ? Color.lerp(Colors.white.withValues(alpha: 0.32), accentColor, 0.18)!
        : Colors.white.withValues(alpha: 0.92);

    // Label color: high emphasis near-white in dark mode, branded in light mode
    final labelColor = isDark ? const Color(0xFFF8FAFC) : accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          // Soft outer colored glow
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.32 : 0.16),
            blurRadius: isDark ? 20 : 18,
            spreadRadius: isDark ? 1 : 0,
            offset: const Offset(0, 4),
          ),
          // Grounding depth shadow
          BoxShadow(
            color: (isDark ? const Color(0xFF020617) : Colors.black)
                .withValues(alpha: isDark ? 0.45 : 0.07),
            blurRadius: isDark ? 14 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Specular shine gradient across top-left
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.22 : 0.40),
                  accentColor.withValues(alpha: isDark ? 0.14 : 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon / Asset graphic with subtle backlight glow in dark mode
                Expanded(
                  child: Center(
                    child: _buildGraphic(size, isDark),
                  ),
                ),
                const SizedBox(height: 2),
                // Feature label (high-emphasis & crisp)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.0,
                      height: 1.15,
                      fontFamily: isKhmer
                          ? AppTypography.khmerFontFamily
                          : AppTypography.englishFontFamily,
                      shadows: [
                        Shadow(
                          color: isDark
                              ? accentColor.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.8),
                          blurRadius: isDark ? 4 : 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphic(double size, bool isDark) {
    final graphicSize = size * 0.48;

    Widget graphic;
    if (assetPath != null) {
      graphic = Image.asset(
        assetPath!,
        width: graphicSize,
        height: graphicSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(graphicSize, isDark),
      );
    } else {
      graphic = _buildFallbackIcon(graphicSize, isDark);
    }

    if (!isDark) return graphic;

    // In Dark Mode: subtle backlight aura so original artwork pops vibrantly
    return Container(
      width: graphicSize,
      height: graphicSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.38),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: graphic,
    );
  }

  Widget _buildFallbackIcon(double graphicSize, bool isDark) {
    return Container(
      width: graphicSize,
      height: graphicSize,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
            accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: isDark ? const Color(0xFFF8FAFC) : accentColor,
        size: graphicSize * 0.64,
      ),
    );
  }
}

class _WelcomeBenefitsCard extends StatelessWidget {
  const _WelcomeBenefitsCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Translucent dark glass in dark mode
    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.92);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.88);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF020617) : Colors.black)
                .withValues(alpha: isDark ? 0.45 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // Benefit 1: Real Opportunities
              Expanded(
                child: _BenefitColumn(
                  icon: Icons.work_outline_rounded,
                  iconBg: isDark
                      ? const Color(0xFF0284C7).withValues(alpha: 0.24)
                      : const Color(0xFFE0F2FE),
                  iconColor: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  line1: 'onboarding.benefitOpp1'.tr,
                  line2: 'onboarding.benefitOpp2'.tr,
                  compact: compact,
                ),
              ),
              _buildDivider(isDark),
              // Benefit 2: Practical Knowledge
              Expanded(
                child: _BenefitColumn(
                  icon: Icons.lightbulb_outline_rounded,
                  iconBg: isDark
                      ? const Color(0xFF9333EA).withValues(alpha: 0.24)
                      : const Color(0xFFF3E8FF),
                  iconColor: isDark
                      ? const Color(0xFFC084FC)
                      : const Color(0xFF9333EA),
                  line1: 'onboarding.benefitKnow1'.tr,
                  line2: 'onboarding.benefitKnow2'.tr,
                  compact: compact,
                ),
              ),
              _buildDivider(isDark),
              // Benefit 3: Meaningful Connections
              Expanded(
                child: _BenefitColumn(
                  icon: Icons.groups_rounded,
                  iconBg: isDark
                      ? const Color(0xFFDB2777).withValues(alpha: 0.24)
                      : const Color(0xFFFCE7F3),
                  iconColor: isDark
                      ? const Color(0xFFF472B6)
                      : const Color(0xFFDB2777),
                  line1: 'onboarding.benefitConn1'.tr,
                  line2: 'onboarding.benefitConn2'.tr,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
    );
  }
}

class _BenefitColumn extends StatelessWidget {
  const _BenefitColumn({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.line1,
    required this.line2,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String line1;
  final String line2;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Get.locale?.languageCode == 'km';
    final circleSize = compact ? 30.0 : 34.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: compact ? 16 : 18,
              ),
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line1,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFF8FAFC)
                        : semantic.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.0 : 12.0,
                    height: 1.15,
                    fontFamily: isKhmer
                        ? AppTypography.khmerFontFamily
                        : AppTypography.englishFontFamily,
                  ),
                ),
                Text(
                  line2,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : semantic.secondaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: compact ? 10.0 : 11.0,
                    height: 1.15,
                    fontFamily: isKhmer
                        ? AppTypography.khmerFontFamily
                        : AppTypography.englishFontFamily,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeAction extends StatefulWidget {
  const _WelcomeAction({
    required this.label,
    required this.onPressed,
    this.height = 56.0,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Get.locale?.languageCode == 'km';

    // Premium near-black in both modes
    final btnBg = isDark ? const Color(0xFF0B1329) : const Color(0xFF0F172A);
    const btnFg = Colors.white;

    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF1F6FEB).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              elevation: 0,
            ),
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: btnFg,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  letterSpacing: 0.2,
                  fontFamily: isKhmer
                      ? AppTypography.khmerFontFamily
                      : AppTypography.englishFontFamily,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark
        ? const Color(0xFFCBD5E1)
        : semantic.secondaryText;

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
              foregroundColor: textColor,
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
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
