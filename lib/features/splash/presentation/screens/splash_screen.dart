import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/splash_controller.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_loading_indicator.dart';
import '../widgets/splash_orbit_system.dart';
import '../widgets/splash_tagline.dart';
import '../widgets/splash_wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;
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

  // Exit Animations
  late final Animation<double> _surroundingExitFade;

  bool _hasNavigated = false;
  String? _destinationRoute;

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

    // 5. Exit Animation Controller (Duration: ~1400ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Surrounding UI fades out during Phase 4 (0.36 -> 0.54)
    _surroundingExitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.36, 0.54, curve: Curves.easeOut),
      ),
    );

    _exitController.addListener(_onExitTick);
    _exitController.addStatusListener(_onExitStatus);

    // Register callback with SplashController if available
    if (Get.isRegistered<SplashController>()) {
      final controller = Get.find<SplashController>();
      controller.onReadyToExit = _startExitSequence;
      if (controller.resolvedDestination != null) {
        _startExitSequence(controller.resolvedDestination!);
      }
    }

    // Launch entrance and continuous animations
    _entranceController.forward();
    _orbitController.repeat();
    _breathingController.repeat(reverse: true);
    _ambientController.repeat();
  }

  void _startExitSequence(String route) {
    if (!mounted || _hasNavigated) return;
    _destinationRoute = route;

    final reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reducedMotion) {
      _hasNavigated = true;
      Get.offAllNamed<void>(route, arguments: const {'fromSplash': true});
      return;
    }

    if (!_exitController.isAnimating && _exitController.value == 0.0) {
      _exitController.forward();
    }
  }

  void _onExitTick() {
    if (_hasNavigated || !mounted) return;
    // When logo hits pulse peak at t >= 0.55, trigger the custom route transition
    if (_exitController.value >= 0.55 && _destinationRoute != null) {
      _hasNavigated = true;
      Get.offAllNamed<void>(
        _destinationRoute!,
        arguments: const {'fromSplash': true},
      );
    }
  }

  void _onExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasNavigated && mounted) {
      _hasNavigated = true;
      final target = _destinationRoute ?? AppRoutes.welcome;
      Get.offAllNamed<void>(target, arguments: const {'fromSplash': true});
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<SplashController>()) {
      final controller = Get.find<SplashController>();
      if (controller.onReadyToExit == _startExitSequence) {
        controller.onReadyToExit = null;
      }
    }
    _exitController.removeListener(_onExitTick);
    _exitController.removeStatusListener(_onExitStatus);
    _entranceController.dispose();
    _exitController.dispose();
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
                        // Top Section: Wordmark (Phase 1 Entrance, Phase 4 Exit Fade)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _entranceController,
                              _exitController,
                            ]),
                            builder: (context, child) {
                              return Opacity(
                                opacity: reducedMotion
                                    ? 1.0
                                    : (_wordmarkFade.value *
                                        _surroundingExitFade.value),
                                child: child,
                              );
                            },
                            child: SplashWordmark(
                              height: compact ? 22 : 25,
                            ),
                          ),
                        ),

                        // Center Section: Orbit System & Central GL Logo (Phase 2 & 3 Entrance & Exit)
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
                                exitAnimation: _exitController,
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

                        // Bottom Section: Tagline & Loading Indicator (Phase 4 & 5 Entrance, Phase 4 Exit Fade)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tagline: Connect Grow Thrive
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _entranceController,
                                _exitController,
                              ]),
                              builder: (context, child) {
                                return Opacity(
                                  opacity: reducedMotion
                                      ? 1.0
                                      : (_taglineFade.value *
                                          _surroundingExitFade.value),
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
                              animation: Listenable.merge([
                                _entranceController,
                                _exitController,
                              ]),
                              builder: (context, child) {
                                return Opacity(
                                  opacity: reducedMotion
                                      ? 1.0
                                      : (_loadingFade.value *
                                          _surroundingExitFade.value),
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

