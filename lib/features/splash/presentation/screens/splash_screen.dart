import 'package:flutter/material.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_loading_indicator.dart';
import '../widgets/splash_orbit_system.dart';
import '../widgets/splash_tagline.dart';
import '../widgets/splash_wordmark.dart';

/// The redesigned GenLink Splash Screen.
///
/// Features:
/// - iOS-inspired, modern GenZ aesthetics with calm ambient glows.
/// - 3D orbital ecosystem with the 4 upright feature icons (Community, Growth, Learning, Opportunity).
/// - Central GL logo with subtle breathing animation.
/// - 5-phase smooth entrance animation.
/// - Responsive layout adapting smoothly to compact and large devices.
/// - Dark Mode and Reduced Motion support.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _orbitController;
  late final AnimationController _breathingController;
  late final AnimationController _ambientController;

  // Staggered Entrance Animations (Phase 1 to Phase 5)
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _glScale;
  late final Animation<double> _glFade;
  late final Animation<double> _orbitScale;
  late final Animation<double> _orbitFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loadingFade;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller (Duration: ~1100ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Phase 1: Wordmark fades in (0% -> 35%)
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Phase 2: Central GL Logo scales 0.92 -> 1.0 with fade (15% -> 55%)
    _glScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _glFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
      ),
    );

    // Phase 3: Orbit ecosystem tiles fade & scale in (35% -> 75%)
    _orbitScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack),
      ),
    );
    _orbitFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
      ),
    );

    // Phase 4: Tagline slides upward & fades in (55% -> 85%)
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    // Phase 5: Loading indicator fades in (75% -> 100%)
    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous Orbit Controller (Duration: ~22s smooth loop)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    // 3. Central GL Logo Breathing Controller (Duration: ~4.5s reverse loop)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // 4. Ambient Background Controller (Duration: ~18s loop)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    // Launch animations
    _entranceController.forward();
    _orbitController.repeat();
    _breathingController.repeat(reverse: true);
    _ambientController.repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    _breathingController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reducedMotion) {
      if (_orbitController.isAnimating) _orbitController.stop();
      if (_breathingController.isAnimating) _breathingController.stop();
      if (_ambientController.isAnimating) _ambientController.stop();
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Layer
          SplashBackground(
            animation: _ambientController,
            reducedMotion: reducedMotion,
          ),

          // 2. Main Content Layer with Safe Areas and responsive layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final compact = height < 700;
                final veryCompact = height < 580;

                // Regression protection against 0 or negative heights
                final minHeight = constraints.hasBoundedHeight
                    ? (height - (AppSpacing.md + AppSpacing.lg))
                        .clamp(0.0, double.infinity)
                    : 0.0;

                // Scale orbit and tiles responsively
                final tileScale = veryCompact
                    ? 0.75
                    : compact
                        ? 0.88
                        : 1.0;
                final centerPlateSize = veryCompact
                    ? 105.0
                    : compact
                        ? 120.0
                        : 140.0;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.md : AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Section: Wordmark (Phase 1)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: reducedMotion
                                    ? 1.0
                                    : _wordmarkFade.value,
                                child: child,
                              );
                            },
                            child: SplashWordmark(
                              height: compact ? 22 : 25,
                            ),
                          ),
                        ),

                        // Center Section: Orbit System & Central GL Logo (Phase 2 & 3)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? AppSpacing.sm : AppSpacing.md,
                          ),
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return SplashOrbitSystem(
                                orbitAnimation: _orbitController,
                                breathingAnimation: _breathingController,
                                entranceScale: reducedMotion
                                    ? 1.0
                                    : (_glScale.value * _orbitScale.value),
                                entranceOpacity: reducedMotion
                                    ? 1.0
                                    : (_glFade.value * _orbitFade.value),
                                reducedMotion: reducedMotion,
                                centerPlateSize: centerPlateSize,
                                tileScale: tileScale,
                              );
                            },
                          ),
                        ),

                        // Bottom Section: Tagline & Loading Indicator (Phase 4 & 5)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tagline: Connect Grow Thrive
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: reducedMotion
                                      ? 1.0
                                      : _taglineFade.value,
                                  child: SlideTransition(
                                    position: reducedMotion
                                        ? const AlwaysStoppedAnimation(
                                            Offset.zero,
                                          )
                                        : _taglineSlide,
                                    child: child,
                                  ),
                                );
                              },
                              child: SplashTagline(compact: compact),
                            ),

                            SizedBox(
                              height: compact ? AppSpacing.lg : AppSpacing.xl,
                            ),

                            // Loading Progress Indicator
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: reducedMotion
                                      ? 1.0
                                      : _loadingFade.value,
                                  child: child,
                                );
                              },
                              child: SplashLoadingIndicator(
                                reducedMotion: reducedMotion,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
