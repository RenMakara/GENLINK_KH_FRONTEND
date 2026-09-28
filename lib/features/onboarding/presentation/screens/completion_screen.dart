import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/completion_controller.dart';

/// GenLink KH — Onboarding Step 3
/// "You're All Set" — Final Onboarding Celebration Screen
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
  CompletionController get controller => Get.find<CompletionController>();

  // 1. Entrance animation controller (900ms)
  late final AnimationController _entranceController;

  // 2. Continuous micro-animation controllers
  late final AnimationController _orbitalController;
  late final AnimationController _floatController;
  late final AnimationController _sparkleController;

  // Entrance animations
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _backdropScale;

  late final Animation<double> _topBarOpacity;
  late final Animation<double> _progressSegment3Fill;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _orbitalOpacity;

  late final Animation<double> _learnOpacity;
  late final Animation<double> _learnScale;
  late final Animation<Offset> _learnSlide;

  late final Animation<double> _growOpacity;
  late final Animation<double> _growScale;
  late final Animation<Offset> _growSlide;

  late final Animation<double> _connectOpacity;
  late final Animation<double> _connectScale;
  late final Animation<Offset> _connectSlide;

  late final Animation<double> _togetherOpacity;
  late final Animation<double> _togetherScale;
  late final Animation<Offset> _togetherSlide;

  late final Animation<double> _bottomCardOpacity;
  late final Animation<Offset> _bottomCardSlide;
  late final Animation<double> _bottomCardScale;

  late final Animation<double> _ctaOpacity;
  late final Animation<Offset> _ctaSlide;

  // Continuous micro-animation outputs
  late final Animation<double> _orbitalProgress;
  late final Animation<double> _floatProgress;
  late final Animation<double> _sparkleProgress;

  bool? _reducedMotion;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    // ─────────────────────────────────────────────────────────────────────────
    // Entrance Sequence (900ms)
    // ─────────────────────────────────────────────────────────────────────────
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Background arrives smoothly (fade + scale 1.02 -> 1.0)
    _backdropOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );
    _backdropScale = Tween<double>(begin: 1.02, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Top Bar (Back button, Step 3 of 3)
    _topBarOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    // Progress bar: Segment 3 fills into active state
    _progressSegment3Fill = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 0.40, curve: Curves.easeInOutCubic),
    );

    // Title: "You're all set!" fade + slide upward
    _titleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.48, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle: "Let's build a brighter future..."
    _subtitleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.54, curve: Curves.easeOutCubic),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 0.54, curve: Curves.easeOutCubic),
      ),
    );

    // Central GenLink Logo Card (scale 0.85 -> 1.0, fade, upward slide)
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.65, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Orbital system lines fade in
    _orbitalOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.24, 0.68, curve: Curves.easeOut),
    );

    // 4 Feature Badges (Learn, Grow, Connect, Together) staggered
    _learnOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
    );
    _learnScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOutBack),
      ),
    );
    _learnSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _growOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.76, curve: Curves.easeOutCubic),
    );
    _growScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.76, curve: Curves.easeOutBack),
      ),
    );
    _growSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.76, curve: Curves.easeOutCubic),
      ),
    );

    _connectOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
    );
    _connectScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.82, curve: Curves.easeOutBack),
      ),
    );
    _connectSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _togetherOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
    );
    _togetherScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutBack),
      ),
    );
    _togetherSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // Bottom Info Card enters from below
    _bottomCardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.56, 0.92, curve: Curves.easeOutCubic),
    );
    _bottomCardSlide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.56, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _bottomCardScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.56, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // Go to GenLink CTA button
    _ctaOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.66, 1.0, curve: Curves.easeOutCubic),
    );
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Continuous micro-animation controllers
    // ─────────────────────────────────────────────────────────────────────────
    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );
    _orbitalProgress = CurvedAnimation(
      parent: _orbitalController,
      curve: Curves.linear,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _floatProgress = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _sparkleProgress = CurvedAnimation(
      parent: _sparkleController,
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
    final shouldReduce = !widget.animate ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false) ||
        !TickerMode.valuesOf(context).enabled ||
        isTesting;

    if (_reducedMotion == shouldReduce) return;
    _reducedMotion = shouldReduce;

    if (shouldReduce) {
      _entranceController.value = 1.0;
      _orbitalController
        ..stop()
        ..value = 0.0;
      _floatController
        ..stop()
        ..value = 0.5;
      _sparkleController
        ..stop()
        ..value = 0.5;
    } else {
      _orbitalController.repeat();
      _floatController.repeat(reverse: true);
      _sparkleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitalController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  bool _computeIsDark(BuildContext context) {
    if (Get.isRegistered<ThemeController>()) {
      final mode = Get.find<ThemeController>().themeMode.value;
      if (mode == ThemeMode.dark) return true;
      if (mode == ThemeMode.light) return false;
    }
    return Theme.of(context).brightness == Brightness.dark ||
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<ThemeController>()) {
      return Obx(() {
        // Explicitly read reactive theme mode so that any theme switch triggers rebuild
        Get.find<ThemeController>().themeMode.value;
        final isDark = _computeIsDark(context);
        return _buildScaffold(context, isDark);
      });
    }

    final isDark = _computeIsDark(context);
    return _buildScaffold(context, isDark);
  }

  Widget _buildScaffold(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1128) : const Color(0xFFF0F7FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 720;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Living Background: welcome.png with subtle atmospheric overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _backdropOpacity,
                    _backdropScale,
                    _floatProgress,
                  ]),
                  builder: (context, _) => _CompletionBackdrop(
                    fade: _backdropOpacity.value,
                    scale: _backdropScale.value,
                    floatProgress: _reducedMotion == true
                        ? 0.0
                        : _floatProgress.value,
                    isDark: isDark,
                  ),
                ),
              ),

              // 2. Foreground content layout wrapped in SafeArea
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Navigation Bar (Back Button + Step 3 of 3)
                    _buildTopBar(compact, isDark),

                    // 3-Segment Progress Indicator (all 3 segments completed)
                    _buildProgressIndicator(compact, isDark),

                    SizedBox(height: compact ? 6 : 10),

                    // Header Title: "You're all set!" (Brand Gradient on "all set!")
                    _buildTitle(compact, isDark),

                    SizedBox(height: compact ? 4 : 6),

                    // Supporting Subtitle: "Let's build a brighter future..."
                    _buildSubtitle(compact, isDark),

                    // Visual gap between Supporting text and Hero visual
                    SizedBox(height: compact ? 12 : 20),

                    // Center Celebration Stage: Central Logo + 4 Orbiting Badges
                    Expanded(
                      child: _buildCelebrationStage(compact, isDark),
                    ),

                    // Visual gap between Hero visual and Bottom Information Card
                    SizedBox(height: compact ? 14 : 20),

                    // Bottom Information Card: "More opportunities ahead"
                    _buildBottomInfoCard(compact, isDark),

                    // Visual gap between Information Card and CTA
                    SizedBox(height: compact ? 14 : 18),

                    // Final CTA: "Go to GenLink" (NO ARROW ICON)
                    _buildCtaButton(compact, isDark),

                    SizedBox(
                      height: math.max(
                        bottomInset > 0 ? 8.0 : 16.0,
                        compact ? 8.0 : 12.0,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Top Bar: Back Button + Step 3 of 3
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool compact, bool isDark) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(opacity: _topBarOpacity, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Back button to Step 2
            AppBackButton(
              size: 42,
              iconSize: 20,
              onPressed: () => Get.offNamed<void>(AppRoutes.languageSelect),
            ),

            // Right: Step 3 of 3
            Text(
              'onboarding.step3Of3'.tr,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12.5 : 13.5,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3-Segment Progress Indicator (All 3 segments active/completed)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProgressIndicator(bool compact, bool isDark) {
    final activeColor = AppColors.brandPrimary;
    final inactiveColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final fillVal =
            _reducedMotion == true ? 1.0 : _progressSegment3Fill.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              // Segment 1: Completed
              Expanded(
                child: Container(
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Segment 2: Completed
              Expanded(
                child: Container(
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Segment 3: Completing smoothly
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: inactiveColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fillVal.clamp(0.0, 1.0),
                      child: Container(
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Title with Brand Gradient
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTitle(bool compact, bool isDark) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km' ||
        Get.locale?.languageCode == 'km';

    final text1 = 'onboarding.allSet1'.tr; // You're / រួចរាល់
    final text2 = 'onboarding.allSet2'.tr; // all set! / ហើយ!

    final baseStyle = TextStyle(
      fontSize: compact ? 30.0 : 36.0,
      fontWeight: FontWeight.w800,
      height: 1.12,
      letterSpacing: -0.6,
      fontFamily: isKhmer
          ? AppTypography.khmerFontFamily
          : AppTypography.englishFontFamily,
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
    );

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _titleOpacity,
          child: Transform.translate(
            offset: _titleSlide.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              text1,
              textAlign: TextAlign.center,
              style: baseStyle,
            ),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.brandGradient.createShader(bounds),
              child: Text(
                text2,
                textAlign: TextAlign.center,
                style: baseStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subtitle
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSubtitle(bool compact, bool isDark) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km' ||
        Get.locale?.languageCode == 'km';

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _subtitleOpacity,
          child: Transform.translate(
            offset: _subtitleSlide.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          'onboarding.allSetBody'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontWeight: FontWeight.w400,
            fontSize: compact ? 13.5 : 15.0,
            height: 1.35,
            fontFamily: isKhmer
                ? AppTypography.khmerFontFamily
                : AppTypography.englishFontFamily,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Middle Celebration Stage
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCelebrationStage(bool compact, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Responsive sizing:
          // Keep the central logo prominent and large as requested:
          // ("no shrink everything", "maintain central logo visibility")
          // Clear space around logo: ~16-24+ px minimum between central card and surrounding cards.
          final isVeryCompact = h < 240;
          final logoPlateSize =
              (w * 0.32).clamp(isVeryCompact ? 108.0 : 118.0, 134.0);
          final badgeSize =
              (w * 0.195).clamp(isVeryCompact ? 64.0 : 70.0, 78.0);
          final sideMargin = (w * 0.05).clamp(16.0, 24.0);

          // Dedicated vertical margins within hero stage
          final topRowY = (h * 0.04).clamp(4.0, 18.0);
          final bottomRowY = (h * 0.04).clamp(4.0, 18.0);

          // Micro-floating with phased offsets, scaled so smaller screens stay perfectly bounded
          final floatScale = (h / 280.0).clamp(0.6, 1.0);
          final floatTime =
              _reducedMotion == true ? 0.0 : _floatProgress.value;
          final floatLogo =
              math.sin(floatTime * 2 * math.pi) * 2.0 * floatScale;
          final floatLearn =
              math.sin(floatTime * 2 * math.pi) * 3.0 * floatScale;
          final floatGrow =
              math.sin((floatTime + 0.33) * 2 * math.pi) * 3.0 * floatScale;
          final floatConnect =
              math.sin((floatTime + 0.66) * 2 * math.pi) * 3.0 * floatScale;
          final floatTogether =
              math.sin((floatTime + 0.50) * 2 * math.pi) * 3.0 * floatScale;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // 1. Orbital System Background (Behind Cards)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _orbitalProgress,
                    _entranceController,
                  ]),
                  builder: (context, _) => Opacity(
                    opacity: _reducedMotion == true
                        ? 1.0
                        : _orbitalOpacity.value,
                    child: _CompletionOrbitalSystem(
                      progress: _reducedMotion == true
                          ? 0.0
                          : _orbitalProgress.value,
                      size: Size(w, h),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              // 2. Celebration Sparkles & Confetti Ribbons
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sparkleProgress,
                  builder: (context, _) => _CelebrationSparklesLayer(
                    progress: _reducedMotion == true
                        ? 0.5
                        : _sparkleProgress.value,
                    isDark: isDark,
                  ),
                ),
              ),

              // 3. Central GenLink Logo Card (Main Visual Anchor - Centered)
              Positioned(
                left: (w - logoPlateSize) / 2,
                top: (h - logoPlateSize) / 2 + floatLogo,
                width: logoPlateSize,
                height: logoPlateSize,
                child: AnimatedBuilder(
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
                  child: _CentralLogoPlate(
                    key: const ValueKey('central_logo_plate'),
                    size: logoPlateSize,
                    isDark: isDark,
                    compact: compact,
                  ),
                ),
              ),

              // 4. Feature Card: Learn (Top-Left)
              Positioned(
                left: sideMargin,
                top: topRowY + floatLearn,
                width: badgeSize,
                height: badgeSize,
                child: _buildBadgeEntrance(
                  opacity: _learnOpacity,
                  scale: _learnScale,
                  slide: _learnSlide,
                  child: _FeatureBadgeCard(
                    key: const ValueKey('feature_badge_learn'),
                    size: badgeSize,
                    label: 'onboarding.featureLearn'.tr,
                    accentColor: const Color(0xFF2563EB),
                    assetPath: 'assets/splash/learning.png',
                    fallbackIcon: Icons.school_rounded,
                    isDark: isDark,
                  ),
                ),
              ),

              // 5. Feature Card: Grow (Top-Right)
              Positioned(
                right: sideMargin,
                top: topRowY + floatGrow,
                width: badgeSize,
                height: badgeSize,
                child: _buildBadgeEntrance(
                  opacity: _growOpacity,
                  scale: _growScale,
                  slide: _growSlide,
                  child: _FeatureBadgeCard(
                    key: const ValueKey('feature_badge_grow'),
                    size: badgeSize,
                    label: 'onboarding.featureGrow'.tr,
                    accentColor: const Color(0xFF10B981),
                    assetPath: 'assets/splash/growth.png',
                    fallbackIcon: Icons.trending_up_rounded,
                    isDark: isDark,
                  ),
                ),
              ),

              // 6. Feature Card: Connect (Bottom-Left)
              Positioned(
                left: sideMargin,
                bottom: bottomRowY + floatConnect,
                width: badgeSize,
                height: badgeSize,
                child: _buildBadgeEntrance(
                  opacity: _connectOpacity,
                  scale: _connectScale,
                  slide: _connectSlide,
                  child: _FeatureBadgeCard(
                    key: const ValueKey('feature_badge_connect'),
                    size: badgeSize,
                    label: 'onboarding.featureConnect'.tr,
                    accentColor: const Color(0xFF8B5CF6),
                    assetPath: 'assets/splash/community.png',
                    fallbackIcon: Icons.groups_rounded,
                    isDark: isDark,
                  ),
                ),
              ),

              // 7. Feature Card: Together (Bottom-Right)
              Positioned(
                right: sideMargin,
                bottom: bottomRowY + floatTogether,
                width: badgeSize,
                height: badgeSize,
                child: _buildBadgeEntrance(
                  opacity: _togetherOpacity,
                  scale: _togetherScale,
                  slide: _togetherSlide,
                  child: _FeatureBadgeCard(
                    key: const ValueKey('feature_badge_together'),
                    size: badgeSize,
                    label: 'onboarding.featureTogether'.tr,
                    accentColor: const Color(0xFFEC4899),
                    assetPath: null,
                    fallbackIcon: Icons.favorite_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeEntrance({
    required Animation<double> opacity,
    required Animation<double> scale,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
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
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Information Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomInfoCard(bool compact, bool isDark) {
    final cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.90);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _bottomCardOpacity,
          child: Transform.translate(
            offset: _bottomCardSlide.value,
            child: Transform.scale(
              scale: _bottomCardScale.value,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          key: const ValueKey('bottom_info_card'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF020617) : Colors.black)
                    .withValues(alpha: isDark ? 0.35 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: compact ? 9 : 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row: Sparkle Icon + "More opportunities ahead"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'onboarding.moreOpportunities'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 13.0 : 14.0,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Secondary Subtitle: "Learn. Connect. Grow. Together."
                    Text(
                      'onboarding.allSetSecondary'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: compact ? 11.0 : 12.0,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 9),

                    // 3 Columns: Explore / Learn / Grow
                    Row(
                      children: [
                        // Column 1: Explore
                        Expanded(
                          child: _BottomPillarItem(
                            icon: Icons.work_outline_rounded,
                            iconColor: const Color(0xFF0284C7),
                            iconBg: const Color(0xFFE0F2FE),
                            title: 'onboarding.explore'.tr,
                            desc: 'onboarding.exploreDesc'.tr,
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 34,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFE2E8F0),
                        ),

                        // Column 2: Learn
                        Expanded(
                          child: _BottomPillarItem(
                            icon: Icons.lightbulb_outline_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            iconBg: const Color(0xFFEDE9FE),
                            title: 'onboarding.featureLearn'.tr,
                            desc: 'onboarding.learnDesc'.tr,
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 34,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFE2E8F0),
                        ),

                        // Column 3: Grow
                        Expanded(
                          child: _BottomPillarItem(
                            icon: Icons.group_outlined,
                            iconColor: const Color(0xFFEC4899),
                            iconBg: const Color(0xFFFCE7F3),
                            title: 'onboarding.featureGrow'.tr,
                            desc: 'onboarding.growDesc'.tr,
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Final CTA Button ("Go to GenLink" — NO ARROW ICON)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCtaButton(bool compact, bool isDark) {
    final buttonBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final buttonFg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _ctaOpacity,
          child: Transform.translate(
            offset: _ctaSlide.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          height: compact ? 52 : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              if (isDark) ...[
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ] else ...[
                BoxShadow(
                  color: (const Color(0xFF0F172A)).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ],
          ),
          child: Obx(
            () {
              final loading = controller.isSaving.value;

              return Listener(
                onPointerDown: (_) {
                  if (!loading) setState(() => _isButtonPressed = true);
                },
                onPointerUp: (_) {
                  if (!loading) setState(() => _isButtonPressed = false);
                },
                onPointerCancel: (_) {
                  if (!loading) setState(() => _isButtonPressed = false);
                },
                child: AnimatedScale(
                  scale: _isButtonPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: FilledButton(
                    key: const ValueKey('cta_button'),
                    onPressed: loading ? null : controller.goToGenLink,
                    style: FilledButton.styleFrom(
                      backgroundColor: buttonBg,
                      disabledBackgroundColor:
                          buttonBg.withValues(alpha: 0.65),
                      foregroundColor: buttonFg,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.90)
                              : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: buttonFg,
                            ),
                          )
                        : Text(
                            'onboarding.goToGenLink'.tr,
                            style: TextStyle(
                              color: buttonFg,
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 15.5 : 16.5,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background with Parallax & Atmosphere Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBackdrop extends StatelessWidget {
  const _CompletionBackdrop({
    required this.fade,
    required this.scale,
    required this.floatProgress,
    required this.isDark,
  });

  final double fade;
  final double scale;
  final double floatProgress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shiftX =
        floatProgress == 0.0 ? 0.0 : math.sin(floatProgress * 2 * math.pi) * 3.0;
    final shiftY =
        floatProgress == 0.0 ? 0.0 : math.cos(floatProgress * 2 * math.pi) * 2.0;

    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // welcome.png as cover
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

            // Top soft gradient overlay for title readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 250,
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
                            Colors.white.withValues(alpha: 0.65),
                            Colors.white.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.60, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom soft gradient overlay for bottom info card & button readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0F172A).withValues(alpha: 0.80),
                            const Color(0xFF0F172A).withValues(alpha: 0.25),
                            Colors.transparent,
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.75),
                            Colors.white.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // In Dark Mode: twilight atmosphere keeping Angkor Wat visible
            if (isDark)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A1128).withValues(alpha: 0.62),
                        const Color(0xFF0F2042).withValues(alpha: 0.28),
                        const Color(0xFF13152C).withValues(alpha: 0.65),
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

// ─────────────────────────────────────────────────────────────────────────────
// Central Logo Plate (Anchor Card)
// ─────────────────────────────────────────────────────────────────────────────

class _CentralLogoPlate extends StatelessWidget {
  const _CentralLogoPlate({
    super.key,
    required this.size,
    required this.isDark,
    required this.compact,
  });

  final double size;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.80)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.26)
        : Colors.white.withValues(alpha: 0.98);

    final logoAsset = isDark
        ? 'assets/splash/genlink-gl-dark.png'
        : 'assets/splash/genlink-gl-logo.png';

    final markHeight = size * 0.46;
    final textHeight = size * 0.13;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          // Ambient cyan glow
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          // Deep drop shadow
          BoxShadow(
            color: (isDark ? const Color(0xFF020617) : Colors.black)
                .withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.22 : 0.50),
                  const Color(0xFF0284C7).withValues(alpha: isDark ? 0.12 : 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // GL 3D Logo Mark
                Image.asset(
                  logoAsset,
                  height: markHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.hub_rounded, size: 48),
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
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature Badge Card (Learn, Grow, Connect, Together)
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureBadgeCard extends StatelessWidget {
  const _FeatureBadgeCard({
    super.key,
    required this.size,
    required this.label,
    required this.accentColor,
    required this.isDark,
    this.assetPath,
    required this.fallbackIcon,
  });

  final double size;
  final String label;
  final Color accentColor;
  final bool isDark;
  final String? assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km' ||
        Get.locale?.languageCode == 'km';

    final bgColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.12)
        : Colors.white.withValues(alpha: 0.90);
    final borderColor = isDark
        ? Color.lerp(Colors.white.withValues(alpha: 0.30), accentColor, 0.20)!
        : Colors.white.withValues(alpha: 0.92);
    final labelColor = isDark ? const Color(0xFFF8FAFC) : accentColor;

    final graphicSize = size * 0.46;

    Widget graphic;
    if (assetPath != null) {
      graphic = Image.asset(
        assetPath!,
        width: graphicSize,
        height: graphicSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: graphicSize, color: accentColor),
      );
    } else {
      graphic = Icon(fallbackIcon, size: graphicSize, color: accentColor);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          // Outer colored glow
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.32 : 0.16),
            blurRadius: isDark ? 18 : 16,
            offset: const Offset(0, 4),
          ),
          // Grounding shadow
          BoxShadow(
            color: (isDark ? const Color(0xFF020617) : Colors.black)
                .withValues(alpha: isDark ? 0.40 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.20 : 0.40),
                  accentColor.withValues(alpha: isDark ? 0.14 : 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: graphic,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      fontFamily: isKhmer
                          ? AppTypography.khmerFontFamily
                          : AppTypography.englishFontFamily,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Orbital System (Translucent Elliptical Ribbon with Moving Beads)
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionOrbitalSystem extends StatelessWidget {
  const _CompletionOrbitalSystem({
    required this.progress,
    required this.size,
    required this.isDark,
  });

  final double progress;
  final Size size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: _CompletionOrbitalPainter(
          progress: progress,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _CompletionOrbitalPainter extends CustomPainter {
  const _CompletionOrbitalPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final center = Offset(w * 0.5, h * 0.46);
    final rx = w * 0.44;
    final ry = h * 0.28;
    const tilt = -0.16; // ~ -9 degrees tilt

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);

    // Glowing orbital ellipse
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

    // Moving orbital pearls
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

      final nodeGlow = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(nx, ny), 5.5, nodeGlow);

      final nodeCore = Paint()..color = nodeColors[i];
      canvas.drawCircle(Offset(nx, ny), 3.2, nodeCore);

      final nodeSpec = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(nx - 0.8, ny - 0.8), 1.0, nodeSpec);
    }

    canvas.restore();

    // Silky translucent ribbon sweep across the bottom
    final ribbonPath = Path();
    ribbonPath.moveTo(0, h * 0.86);
    ribbonPath.cubicTo(
      w * 0.35,
      h * 0.74,
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
  bool shouldRepaint(covariant _CompletionOrbitalPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Celebration Sparkles & Subtle Floating Ribbons
// ─────────────────────────────────────────────────────────────────────────────

class _CelebrationSparklesLayer extends StatelessWidget {
  const _CelebrationSparklesLayer({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmer = math.sin(progress * 2 * math.pi);

    return IgnorePointer(
      child: Stack(
        children: [
          // Sparkle 1: Top-Left Cyan (✦)
          Positioned(
            top: 24 + (shimmer * 3),
            left: 28,
            child: Opacity(
              opacity: (0.75 + 0.25 * shimmer).clamp(0.0, 1.0),
              child: const Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 16,
                  shadows: [
                    Shadow(color: Color(0x8038BDF8), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),

          // Sparkle 2: Top-Right Gold (✦)
          Positioned(
            top: 36 - (shimmer * 3),
            right: 32,
            child: Opacity(
              opacity: (0.70 - 0.20 * shimmer).clamp(0.0, 1.0),
              child: const Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 14,
                  shadows: [
                    Shadow(color: Color(0x80FBBF24), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),

          // Sparkle 3: Mid-Right Pink (✦)
          Positioned(
            bottom: 48 + (shimmer * 4),
            right: 20,
            child: Opacity(
              opacity: (0.80 + 0.20 * shimmer).clamp(0.0, 1.0),
              child: const Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFFF472B6),
                  fontSize: 15,
                  shadows: [
                    Shadow(color: Color(0x80F472B6), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),

          // Floating Confetti Ribbon 1: Cyan
          Positioned(
            top: 60 + (shimmer * 5),
            left: 80,
            child: Transform.rotate(
              angle: -0.4 + (shimmer * 0.08),
              child: Container(
                width: 12,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Floating Confetti Ribbon 2: Gold
          Positioned(
            bottom: 40 - (shimmer * 4),
            left: 100,
            child: Transform.rotate(
              angle: 0.35 + (shimmer * 0.06),
              child: Container(
                width: 14,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Floating Confetti Ribbon 3: Pink
          Positioned(
            top: 70 - (shimmer * 4),
            right: 86,
            child: Transform.rotate(
              angle: 0.5 - (shimmer * 0.08),
              child: Container(
                width: 13,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF472B6).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Pillar Item (Explore / Learn / Grow columns)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPillarItem extends StatelessWidget {
  const _BottomPillarItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.isDark,
    required this.compact,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String desc;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.22) : iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: compact ? 15 : 17,
              color: isDark ? iconColor : iconColor,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11.0 : 12.0,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              desc,
              maxLines: 1,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                fontSize: compact ? 9.5 : 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
