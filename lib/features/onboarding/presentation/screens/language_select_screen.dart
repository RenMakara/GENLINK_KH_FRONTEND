import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/language_select_controller.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen>
    with TickerProviderStateMixin {
  LanguageSelectController get controller => Get.find<LanguageSelectController>();

  // Coordinated entrance animation controller (750ms)
  late final AnimationController _entranceController;

  // Continuous micro-floating animation controller (6s loop)
  late final AnimationController _floatController;

  // Staggered entrance animations
  late final Animation<double> _topBarOpacity;
  late final Animation<Offset> _topBarSlide;

  late final Animation<double> _progressOpacity;
  late final Animation<double> _progressFill;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;

  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _illustrationScale;

  late final Animation<double> _languageCardOpacity;
  late final Animation<Offset> _languageCardSlide;

  late final Animation<double> _appearanceCardOpacity;
  late final Animation<Offset> _appearanceCardSlide;

  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // 0ms - 350ms: Top navigation bar
    _topBarOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _topBarSlide = Tween<Offset>(
      begin: const Offset(0, -10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // 60ms - 450ms: Progress segments fill
    _progressOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.50, curve: Curves.easeOut),
    );
    _progressFill = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    );

    // 100ms - 520ms: Header title & description
    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.62, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // 140ms - 560ms: Decorative settings illustration
    _illustrationOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.16, 0.66, curve: Curves.easeOut),
    );
    _illustrationScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.16, 0.66, curve: Curves.easeOutBack),
      ),
    );

    // 200ms - 640ms: Language Card
    _languageCardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.24, 0.74, curve: Curves.easeOut),
    );
    _languageCardSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.24, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    // 280ms - 720ms: Appearance Card
    _appearanceCardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.82, curve: Curves.easeOut),
    );
    _appearanceCardSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.32, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // 360ms - 750ms: Continue Button
    _buttonOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.95, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.95, curve: Curves.easeOutCubic),
      ),
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
      _entranceController.value = 1.0;
      _floatController
        ..stop()
        ..value = 0.5;
    } else {
      if (!_entranceController.isAnimating && !_entranceController.isCompleted) {
        _entranceController.forward();
      }
      if (!_floatController.isAnimating) {
        _floatController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final compact = size.height < 700;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Soft atmospheric gradient background
          _buildAtmosphericBackground(isDark),

          // 2. Main content area inside SafeArea
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (Back Button + Step 2 of 3)
                _buildTopNavigation(compact, isDark),

                // 3-Segment Progress Indicator
                _buildProgressIndicator(compact, isDark),

                // Scrollable Central Cards (Header + Language + Appearance)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: compact ? 8 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (Title, Description & Decorative 3D Illustration)
                        _buildHeader(compact, isDark),
                        SizedBox(height: compact ? 12 : 16),

                        // Section 1: Language Glass Card
                        _buildLanguageSection(compact, isDark),
                        SizedBox(height: compact ? 12 : 16),

                        // Section 2: Appearance Glass Card
                        _buildAppearanceSection(compact, isDark),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button (Continue — NO arrow icon)
                _buildContinueButton(compact, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Atmospheric Background
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAtmosphericBackground(bool isDark) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle top-right atmospheric blue glow
          Positioned(
            top: -60,
            right: -60,
            width: 280,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1F6FEB).withValues(alpha: 0.28),
                          const Color(0xFF0284C7).withValues(alpha: 0.12),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFF38BDF8).withValues(alpha: 0.22),
                          const Color(0xFF818CF8).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Subtle bottom-left glow
          Positioned(
            bottom: 40,
            left: -80,
            width: 260,
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A).withValues(alpha: 0.50),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFE0F2FE).withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top Navigation Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopNavigation(bool compact, bool isDark) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _topBarOpacity,
          child: Transform.translate(
            offset: _topBarSlide.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Back button
            AppBackButton(
              size: 42,
              iconSize: 20,
              onPressed: controller.previous,
            ),

            // Right: Step 2 of 3 text
            Text(
              'onboarding.step2Of3'.tr,
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
  // 3-Segment Progress Indicator
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProgressIndicator(bool compact, bool isDark) {
    final inactiveColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final activeColor = AppColors.brandPrimary;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final fillVal =
            _reducedMotion == true ? 1.0 : _progressFill.value;
        final opacityVal =
            _reducedMotion == true ? 1.0 : _progressOpacity.value;

        return Opacity(
          opacity: opacityVal,
          child: Padding(
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

                // Segment 2: Active (fills smoothly on screen entrance)
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
                const SizedBox(width: 8),

                // Segment 3: Inactive
                Expanded(
                  child: Container(
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: inactiveColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Title, Description & Decorative 3D Illustration
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool compact, bool isDark) {
    final semantic = context.semanticColors;
    final isKhmer = Localizations.localeOf(context).languageCode == 'km' ||
        Get.locale?.languageCode == 'km';

    final title1 = 'onboarding.personalizeTitle1'.tr; // Personalize / កំណត់ផ្ទាល់ខ្លួន
    final title2 = 'onboarding.personalizeTitle2'.tr; // your / នូវ
    final title3 = 'onboarding.personalizeTitle3'.tr; // experience / បទពិសោធន៍របស់អ្នក

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Text Hierarchy
        Expanded(
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              if (_entranceController.isCompleted) return child!;
              return FadeTransition(
                opacity: _headerOpacity,
                child: Transform.translate(
                  offset: _headerSlide.value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: "Personalize" / "កំណត់ផ្ទាល់ខ្លួន"
                Text(
                  title1,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF8FAFC) : semantic.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 25 : 29,
                    height: 1.15,
                    letterSpacing: -0.5,
                    fontFamily: isKhmer
                        ? AppTypography.khmerFontFamily
                        : AppTypography.englishFontFamily,
                  ),
                ),
                const SizedBox(height: 2),

                // Line 2: "your experience" (with GenLink brand gradient on "experience")
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!isKhmer) ...[
                      Text(
                        '$title2 ',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 25 : 29,
                          height: 1.15,
                          letterSpacing: -0.5,
                          fontFamily: AppTypography.englishFontFamily,
                        ),
                      ),
                    ],
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      child: Text(
                        title3,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 25 : 29,
                          height: 1.15,
                          letterSpacing: -0.5,
                          fontFamily: isKhmer
                              ? AppTypography.khmerFontFamily
                              : AppTypography.englishFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description: "Choose your language and appearance. You can change these anytime in Settings."
                Text(
                  '${'onboarding.personalizeDesc1'.tr}\n${'onboarding.personalizeDesc2'.tr}',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : semantic.secondaryText,
                    fontWeight: FontWeight.w400,
                    fontSize: compact ? 12.0 : 13.0,
                    height: 1.35,
                    fontFamily: isKhmer
                        ? AppTypography.khmerFontFamily
                        : AppTypography.englishFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Right Column: Decorative 3D Settings Illustration
        AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _floatController]),
          builder: (context, child) {
            final floatProgress =
                _reducedMotion == true ? 0.0 : _floatController.value;

            return Opacity(
              opacity: _reducedMotion == true ? 1.0 : _illustrationOpacity.value,
              child: Transform.scale(
                scale: _reducedMotion == true ? 1.0 : _illustrationScale.value,
                child: _DecorativeSettingsGraphic(
                  floatProgress: floatProgress,
                  isDark: isDark,
                  compact: compact,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 1: Language Glass Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLanguageSection(bool compact, bool isDark) {
    final semantic = context.semanticColors;

    final cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.92);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _languageCardOpacity,
          child: Transform.translate(
            offset: _languageCardSlide.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF020617) : Colors.black)
                  .withValues(alpha: isDark ? 0.40 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(compact ? 13 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header: Globe Icon + Title + Subtitle
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                              : const Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.language_rounded,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'onboarding.languageTitle'.tr,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : semantic.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 15.5 : 16.5,
                              ),
                            ),
                            Text(
                              'onboarding.languageSubtitle'.tr,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : semantic.secondaryText,
                                fontWeight: FontWeight.w400,
                                fontSize: compact ? 11.5 : 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // Language Options (Khmer & English side-by-side)
                  Obx(
                    () => Row(
                      children: [
                        // Khmer Option
                        Expanded(
                          child: _LanguageOptionCard(
                            flag: '🇰🇭',
                            title: 'onboarding.khmerTitle'.tr,
                            subtitle: 'onboarding.khmerSubtitle'.tr,
                            selected: controller.selected.value ==
                                LocalizationService.khmer,
                            onTap: () =>
                                controller.select(LocalizationService.khmer),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // English Option
                        Expanded(
                          child: _LanguageOptionCard(
                            flag: '🇺🇸',
                            title: 'onboarding.englishTitle'.tr,
                            subtitle: 'onboarding.englishSubtitle'.tr,
                            selected: controller.selected.value ==
                                LocalizationService.english,
                            onTap: () =>
                                controller.select(LocalizationService.english),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),

                  // Language Info Card: "Both languages are supported throughout the app."
                  _InfoBanner(
                    icon: Icons.translate_rounded,
                    message: 'onboarding.bothLanguages'.tr,
                    isDark: isDark,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section 2: Appearance Glass Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAppearanceSection(bool compact, bool isDark) {
    final semantic = context.semanticColors;

    final cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.92);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isCompleted) return child!;
        return FadeTransition(
          opacity: _appearanceCardOpacity,
          child: Transform.translate(
            offset: _appearanceCardSlide.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF020617) : Colors.black)
                  .withValues(alpha: isDark ? 0.40 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(compact ? 13 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header: Moon Icon + Title + Subtitle
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF818CF8).withValues(alpha: 0.22)
                              : const Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.nightlight_round,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'onboarding.appearanceTitle'.tr,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : semantic.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 15.5 : 16.5,
                              ),
                            ),
                            Text(
                              'onboarding.appearanceSubtitle'.tr,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : semantic.secondaryText,
                                fontWeight: FontWeight.w400,
                                fontSize: compact ? 11.5 : 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // 3 Theme Options (Light, Dark, System default)
                  Obx(
                    () => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Option 1: Light
                        Expanded(
                          child: _ThemePreviewOption(
                            mode: ThemeMode.light,
                            label: 'onboarding.themeLight'.tr,
                            selected: controller.selectedTheme.value ==
                                ThemeMode.light,
                            onTap: () =>
                                controller.selectTheme(ThemeMode.light),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Option 2: Dark
                        Expanded(
                          child: _ThemePreviewOption(
                            mode: ThemeMode.dark,
                            label: 'onboarding.themeDark'.tr,
                            selected: controller.selectedTheme.value ==
                                ThemeMode.dark,
                            onTap: () =>
                                controller.selectTheme(ThemeMode.dark),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Option 3: System default (ENFORCED ON ONE LINE)
                        Expanded(
                          child: _ThemePreviewOption(
                            mode: ThemeMode.system,
                            label: 'onboarding.themeSystem'.tr,
                            selected: controller.selectedTheme.value ==
                                ThemeMode.system,
                            onTap: () =>
                                controller.selectTheme(ThemeMode.system),
                            isDark: isDark,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),

                  // Appearance Info Card: "Automatically matches your device settings."
                  _InfoBanner(
                    icon: Icons.devices_rounded,
                    message: 'onboarding.autoMatchesDevice'.tr,
                    isDark: isDark,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Continue Button (NO arrow icon)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContinueButton(bool compact, bool isDark) {
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            compact ? 8 : 14,
          ),
          child: Obx(
            () => _PersonalizeActionButton(
              label: 'onboarding.continue'.tr,
              loading: controller.isSaving.value,
              onPressed: controller.continueToCompletion,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative 3D Settings Illustration
// ─────────────────────────────────────────────────────────────────────────────

class _DecorativeSettingsGraphic extends StatelessWidget {
  const _DecorativeSettingsGraphic({
    required this.floatProgress,
    required this.isDark,
    required this.compact,
  });

  final double floatProgress;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(floatProgress * 2 * math.pi) * 3.5;
    final w = compact ? 82.0 : 96.0;
    final h = compact ? 90.0 : 104.0;

    return Semantics(
      excludeSemantics: true,
      child: Transform.translate(
        offset: Offset(0, floatY),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Ambient soft glowing orb behind
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: compact ? 65 : 75,
                  height: compact ? 65 : 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8)
                            .withValues(alpha: isDark ? 0.32 : 0.22),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main tilted translucent glass device slab
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateZ(-0.08),
                alignment: Alignment.center,
                child: Container(
                  width: compact ? 58 : 68,
                  height: compact ? 76 : 88,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.90),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A)
                            .withValues(alpha: isDark ? 0.40 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Translate icon circle with gradient
                            Container(
                              width: compact ? 26 : 30,
                              height: compact ? 26 : 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF1F6FEB),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1F6FEB)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.translate_rounded,
                                color: Colors.white,
                                size: compact ? 15 : 18,
                              ),
                            ),
                            const Spacer(),
                            // Translucent row skeleton 1
                            Container(
                              height: 4,
                              width: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Translucent row skeleton 2
                            Container(
                              height: 4,
                              width: 26,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Floating glass mini card with cyan globe
              Positioned(
                left: compact ? 0 : 2,
                top: compact ? 10 : 12,
                child: Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.78)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.40)
                          : Colors.white,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.language_rounded,
                    color: const Color(0xFF0284C7),
                    size: compact ? 17 : 20,
                  ),
                ),
              ),

              // 4. Floating mini split pill with sun ☀️ and moon 🌙
              Positioned(
                right: 0,
                bottom: compact ? 4 : 6,
                child: Container(
                  height: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFEF3C7),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.wb_sunny_rounded,
                          size: 10,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E293B),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.nightlight_round,
                          size: 10,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Four-point sparkle star (✦)
              Positioned(
                right: compact ? 4 : 8,
                top: 0,
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _SparkleStarPainter(
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
              Positioned(
                left: compact ? 4 : 8,
                bottom: 2,
                child: CustomPaint(
                  size: const Size(10, 10),
                  painter: _SparkleStarPainter(
                    color: const Color(0xFFC084FC),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sparkle Star Painter (✦)
// ─────────────────────────────────────────────────────────────────────────────

class _SparkleStarPainter extends CustomPainter {
  const _SparkleStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.5, h * 0.35, w * 0.65, h * 0.5, w, h * 0.5)
      ..cubicTo(w * 0.65, h * 0.5, w * 0.5, h * 0.65, w * 0.5, h)
      ..cubicTo(w * 0.5, h * 0.65, w * 0.35, h * 0.5, 0, h * 0.5)
      ..cubicTo(w * 0.35, h * 0.5, w * 0.5, h * 0.35, w * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Option Card
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.compact,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final bgColor = selected
        ? (isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.28)
            : const Color(0xFFEFF6FF))
        : (isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.40)
            : Colors.white);

    final borderColor = selected
        ? AppColors.brandPrimary
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE2E8F0));

    return Semantics(
      button: true,
      selected: selected,
      label: '$title $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.8 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Flag Container
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 22 : 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    flag,
                    style: TextStyle(fontSize: compact ? 16 : 18),
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : semantic.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 12.5 : 13.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : semantic.secondaryText,
                          fontWeight: FontWeight.w400,
                          fontSize: compact ? 10.5 : 11.5,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Selection Indicator Circle
                _SelectionCircle(
                  selected: selected,
                  isDark: isDark,
                  size: compact ? 20 : 22,
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
// Theme Preview Option Card (Light, Dark, System Default)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePreviewOption extends StatelessWidget {
  const _ThemePreviewOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.compact,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final bgColor = selected
        ? (isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.28)
            : const Color(0xFFEFF6FF))
        : (isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.40)
            : Colors.white);

    final borderColor = selected
        ? AppColors.brandPrimary
        : (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFE2E8F0));

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: selected ? 1.0 : 0.98,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(compact ? 5 : 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Miniature UI Preview Box
                  _buildPreviewBox(),
                  SizedBox(height: compact ? 4 : 6),

                  // Theme Label — STRICTLY ENFORCED ON ONE LINE!
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : semantic.primaryText,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: compact ? 11.0 : 12.0,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),

                  // Selection Indicator Circle
                  _SelectionCircle(
                    selected: selected,
                    isDark: isDark,
                    size: compact ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBox() {
    final previewHeight = compact ? 56.0 : 66.0;

    if (mode == ThemeMode.system) {
      // Split Preview: Left Light, Right Dark
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: previewHeight,
          child: Row(
            children: [
              // Left half: Light
              Expanded(
                child: _buildPane(
                  bgColor: const Color(0xFFF8FAFC),
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFF0284C7),
                  barColor: const Color(0xFFE2E8F0),
                  accentColor: const Color(0xFFBFDBFE),
                  cardColor: Colors.white,
                  isDarkPane: false,
                  isSplit: true,
                ),
              ),
              // Thin vertical divider line
              Container(width: 1, color: const Color(0xFFCBD5E1)),
              // Right half: Dark
              Expanded(
                child: _buildPane(
                  bgColor: const Color(0xFF0F172A),
                  icon: Icons.nightlight_round,
                  iconColor: const Color(0xFF38BDF8),
                  barColor: const Color(0xFF1E293B),
                  accentColor: const Color(0xFF1D4ED8),
                  cardColor: const Color(0xFF1E293B),
                  isDarkPane: true,
                  isSplit: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDarkOption = mode == ThemeMode.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: previewHeight,
        child: _buildPane(
          bgColor: isDarkOption
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          icon: isDarkOption
              ? Icons.nightlight_round
              : Icons.wb_sunny_rounded,
          iconColor: isDarkOption
              ? const Color(0xFF38BDF8)
              : const Color(0xFF0284C7),
          barColor: isDarkOption
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
          accentColor: isDarkOption
              ? const Color(0xFF1D4ED8)
              : const Color(0xFFBFDBFE),
          cardColor: isDarkOption
              ? const Color(0xFF1E293B)
              : Colors.white,
          isDarkPane: isDarkOption,
          isSplit: false,
        ),
      ),
    );
  }

  Widget _buildPane({
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required Color barColor,
    required Color accentColor,
    required Color cardColor,
    required bool isDarkPane,
    required bool isSplit,
  }) {
    return Container(
      color: bgColor,
      padding: EdgeInsets.all(isSplit ? 3 : 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Center Icon
          Icon(icon, size: compact ? 13 : 15, color: iconColor),
          SizedBox(height: compact ? 3 : 4),

          // Miniature App Bar Line
          Container(
            height: 3.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: compact ? 4 : 5),

          // Miniature Card Blocks
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (!isSplit) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isDarkPane
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selection Circle Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({
    required this.selected,
    required this.isDark,
    required this.size,
  });

  final bool selected;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brandPrimary : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.brandPrimary
              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          width: selected ? 1.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: size * 0.65,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Soft Information Banner
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.isDark,
    required this.compact,
  });

  final IconData icon;
  final String message;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.60)
        : const Color(0xFFF0F7FF);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFDBEAFE).withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: compact ? 26 : 28,
            height: compact ? 26 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppColors.brandPrimary,
              size: compact ? 15 : 17,
            ),
          ),
          const SizedBox(width: 10),

          // Message Text
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w400,
                fontSize: compact ? 11.0 : 12.0,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Continue Button (NO arrow icon)
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalizeActionButton extends StatefulWidget {
  const _PersonalizeActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.isDark,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  State<_PersonalizeActionButton> createState() =>
      _PersonalizeActionButtonState();
}

class _PersonalizeActionButtonState extends State<_PersonalizeActionButton> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnBg =
        widget.isDark ? const Color(0xFF0B1329) : const Color(0xFF0F172A);
    const btnFg = Colors.white;

    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: widget.isDark
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
            onPressed: widget.loading ? null : widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              elevation: 0,
            ),
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: btnFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
