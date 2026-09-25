import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/typography/app_typography.dart';

class AuthFloatingErrorBanner extends StatefulWidget {
  const AuthFloatingErrorBanner({
    super.key,
    required this.message,
    this.triggerKey,
    this.title,
    this.description,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  final String? message;
  final Object? triggerKey;
  final String? title;
  final String? description;
  final Duration duration;
  final VoidCallback? onDismissed;

  @override
  State<AuthFloatingErrorBanner> createState() =>
      _AuthFloatingErrorBannerState();
}

class _AuthFloatingErrorBannerState extends State<AuthFloatingErrorBanner>
    with TickerProviderStateMixin {
  late final AnimationController _visibilityController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _hideAndDismiss();
      }
    });

    if (widget.message != null && widget.message!.isNotEmpty) {
      _startShowing();
    }
  }

  @override
  void didUpdateWidget(covariant AuthFloatingErrorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasNewMessage = widget.message != null && widget.message!.isNotEmpty;
    final messageChanged = widget.message != oldWidget.message;
    final triggerChanged = widget.triggerKey != oldWidget.triggerKey;

    if (hasNewMessage && (messageChanged || triggerChanged)) {
      _startShowing();
    } else if (!hasNewMessage && oldWidget.message != null) {
      _progressController.stop();
      _visibilityController.reverse();
    }
  }

  void _startShowing() {
    _visibilityController.forward();
    _progressController.reverse(from: 1.0);
  }

  void _hideAndDismiss() {
    _visibilityController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  void _onCloseTapped() {
    _progressController.stop();
    _visibilityController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        if (_visibilityController.isDismissed) {
          return const SizedBox.shrink();
        }
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, _) {
          return _buildCard(context, _progressController.value);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, double progress) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = widget.title ??
        (widget.message != null && widget.message!.isNotEmpty
            ? widget.message!
            : 'auth.loginErrorTitle'.tr);

    final resolvedDescription =
        widget.description ?? 'auth.loginErrorDescription'.tr;

    final isKhmer = Get.locale?.languageCode == 'km' ||
        Localizations.maybeLocaleOf(context)?.languageCode == 'km';
    final primaryFont = isKhmer
        ? AppTypography.khmerFontFamily
        : AppTypography.englishFontFamily;
    final fallbackFonts = isKhmer
        ? const [AppTypography.englishFontFamily, 'Sora']
        : const [AppTypography.khmerFontFamily, 'KantumruyPro'];

    return Container(
      key: const ValueKey('login-error-popup'),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1417) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.6)
              : const Color(0xFFFECDD3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x18991B1B),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0x0A000000),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      key: const ValueKey('login-error-icon-container'),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            resolvedTitle,
                            key: const ValueKey('login-error-title'),
                            style: TextStyle(
                              fontFamily: primaryFont,
                              fontFamilyFallback: fallbackFonts,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFECDD3)
                                  : const Color(0xFF881337),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resolvedDescription,
                            key: const ValueKey('login-error-description'),
                            style: TextStyle(
                              fontFamily: primaryFont,
                              fontFamilyFallback: fallbackFonts,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF5A1E24),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'common.close'.tr,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    key: const ValueKey('login-error-close-button'),
                    onTap: _onCloseTapped,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFFDA4AF).withValues(alpha: 0.8)
                            : const Color(0xFF9F1239).withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              key: const ValueKey('login-error-progress'),
              height: 3.5,
              color: isDark
                  ? const Color(0xFF4C0519).withValues(alpha: 0.6)
                  : const Color(0xFFFECDD3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFFB7185)
                          : const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
