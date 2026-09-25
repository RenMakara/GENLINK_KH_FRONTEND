import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

class OtpCodeDisplay extends StatefulWidget {
  const OtpCodeDisplay({
    super.key,
    required this.code,
    this.length = 6,
    this.errorText,
    this.errorTitle,
    this.errorDescription,
  });

  final String code;
  final int length;
  final String? errorText;
  final String? errorTitle;
  final String? errorDescription;

  @override
  State<OtpCodeDisplay> createState() => _OtpCodeDisplayState();
}

class _OtpCodeDisplayState extends State<OtpCodeDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _errorCardController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );

    _errorCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _errorCardController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _errorCardController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _errorCardController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      _shakeController.forward(from: 0.0);
      _errorCardController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OtpCodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hadError =
        oldWidget.errorText != null && oldWidget.errorText!.isNotEmpty;

    if (hasError && (!hadError || widget.errorText != oldWidget.errorText)) {
      _shakeController.forward(from: 0.0);
      _errorCardController.forward();
    } else if (!hasError && hadError) {
      _errorCardController.reverse();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _errorCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.code.length < widget.length
        ? widget.code.length
        : widget.length - 1;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final resolvedTitle = widget.errorTitle != null &&
            widget.errorTitle!.isNotEmpty
        ? widget.errorTitle!
        : (widget.errorText != null && widget.errorText!.isNotEmpty
            ? widget.errorText!
            : 'auth.otpInvalidTitle'.tr);

    final resolvedDescription =
        widget.errorDescription != null && widget.errorDescription!.isNotEmpty
            ? widget.errorDescription!
            : 'auth.otpInvalidDescription'.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gaps = AppSpacing.sm * (widget.length - 1);
              final share = (constraints.maxWidth - gaps) / widget.length;
              final boxWidth = share.clamp(0.0, _OtpDigitCell.maxWidth);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  for (var index = 0; index < widget.length; index++)
                    SizedBox(
                      width: boxWidth,
                      child: _OtpDigitCell(
                        key: ValueKey('otp-cell-$index'),
                        index: index,
                        digit: index < widget.code.length
                            ? widget.code[index]
                            : null,
                        isActive: index == activeIndex,
                        hasError: hasError,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _errorCardController,
          builder: (context, child) {
            if (_errorCardController.isDismissed && !hasError) {
              return const SizedBox.shrink();
            }
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: OtpErrorMessage(
            title: resolvedTitle,
            description: resolvedDescription,
          ),
        ),
      ],
    );
  }
}

class OtpErrorMessage extends StatelessWidget {
  const OtpErrorMessage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isKhmer = Get.locale?.languageCode == 'km' ||
        Localizations.maybeLocaleOf(context)?.languageCode == 'km';
    final primaryFont = isKhmer
        ? AppTypography.khmerFontFamily
        : AppTypography.englishFontFamily;
    final fallbackFonts = isKhmer
        ? const [AppTypography.englishFontFamily, 'Sora']
        : const [AppTypography.khmerFontFamily, 'KantumruyPro'];

    return Container(
      key: const ValueKey('otp-error'),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1417) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.6)
              : const Color(0xFFFECDD3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x0E991B1B),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const ValueKey('otp-error-icon-container'),
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
                  title,
                  key: const ValueKey('otp-error-title'),
                  style: TextStyle(
                    fontFamily: primaryFont,
                    fontFamilyFallback: fallbackFonts,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFFECDD3)
                        : const Color(0xFF881337),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  key: const ValueKey('otp-error-description'),
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
    );
  }
}

class _OtpDigitCell extends StatelessWidget {
  const _OtpDigitCell({
    super.key,
    required this.index,
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final int index;
  final String? digit;
  final bool isActive;
  final bool hasError;

  static const height = 64.0;
  static const maxWidth = 59.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color strokeColor;
    final double strokeWidth;
    final Color fillColor;

    if (hasError) {
      if (isActive) {
        // Focused / last-edited invalid cell
        strokeColor = const Color(0xFFE11D48);
        strokeWidth = 1.5;
        fillColor =
            isDark ? const Color(0xFF2B1417) : const Color(0xFFFFF1F2);
      } else {
        // Other invalid cells remain neutral
        strokeColor =
            isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E7EB);
        strokeWidth = 1.0;
        fillColor = isDark ? const Color(0xFF242526) : Colors.white;
      }
    } else {
      if (isActive) {
        // Focused normal cell
        strokeColor = AppColors.brandPrimary;
        strokeWidth = 1.5;
        fillColor = isDark ? const Color(0xFF242526) : Colors.white;
      } else {
        // Unfocused normal cell
        strokeColor =
            isDark ? const Color(0xFF323436) : const Color(0xFFE5E7EB);
        strokeWidth = 1.0;
        fillColor = isDark ? const Color(0xFF242526) : Colors.white;
      }
    }

    final isKhmer = Get.locale?.languageCode == 'km' ||
        Localizations.maybeLocaleOf(context)?.languageCode == 'km';
    final primaryFont = isKhmer
        ? AppTypography.khmerFontFamily
        : AppTypography.englishFontFamily;
    final fallbackFonts = isKhmer
        ? const [AppTypography.englishFontFamily, 'Sora']
        : const [AppTypography.khmerFontFamily, 'KantumruyPro'];

    return Semantics(
      label: digit == null
          ? 'auth.otpEmptyDigit'.trParams({'position': '${index + 1}'})
          : 'auth.otpEnteredDigit'.trParams({
              'position': '${index + 1}',
              'digit': digit!,
            }),
      selected: isActive,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: height,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: strokeColor, width: strokeWidth),
        ),
        alignment: Alignment.center,
        child: digit == null
            ? _OtpCursor(
                color:
                    hasError ? const Color(0xFFE11D48) : AppColors.brandPrimary,
                visible: isActive,
              )
            : Text(
                digit!,
                style: TextStyle(
                  fontFamily: primaryFont,
                  fontFamilyFallback: fallbackFonts,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _OtpCursor extends StatelessWidget {
  const _OtpCursor({required this.color, this.visible = true});

  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: visible ? 1 : 0,
      child: Container(
        key: visible ? const ValueKey('otp-active-cursor') : null,
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class OtpNumericKeypad extends StatelessWidget {
  const OtpNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.onSymbolPressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onSymbolPressed;

  static const _keyHeight = 54.0;
  static const _rows = <List<String>>[
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['backspace', '0', '*'],
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          key: const ValueKey('otp-keypad'),
          children: [
            for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                spacing: AppSpacing.sm,
                children: [
                  for (final value in _rows[rowIndex])
                    Expanded(
                      child: _OtpKey(
                        key: ValueKey('otp-key-$value'),
                        label: value,
                        height: _keyHeight,
                        onPressed: switch (value) {
                          'backspace' => onBackspacePressed,
                          '*' => onSymbolPressed,
                          _ => () => onDigitPressed(value),
                        },
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OtpKey extends StatelessWidget {
  const _OtpKey({
    super.key,
    required this.label,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isBackspace = label == 'backspace';
    final isSymbol = label == '*';
    final isBlank = isSymbol && onPressed == null;
    final semanticsLabel = isBackspace
        ? 'common.delete'.tr
        : isSymbol
        ? 'auth.otpSymbol'.tr
        : label;

    final keyBg = isBlank
        ? Colors.transparent
        : (isDark
            ? (onPressed == null
                ? const Color(0xFF1E1F20)
                : const Color(0xFF28292A))
            : (onPressed == null
                ? const Color(0xFFF0F2F5)
                : Colors.white));

    return Semantics(
      button: !isBlank,
      enabled: onPressed != null,
      label: semanticsLabel,
      child: Material(
        color: keyBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: !isBlank && !isDark && onPressed != null ? 0.5 : 0,
        shadowColor: const Color(0x0A000000),
        child: InkWell(
          onTap: onPressed,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? scheme.primary.withValues(alpha: 0.12)
                : null,
          ),
          child: SizedBox(
            height: height,
            child: Center(
              child: isBackspace
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: scheme.onSurface,
                    )
                  : isBlank
                  ? const SizedBox.shrink()
                  : Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTypography.englishFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: onPressed == null
                            ? scheme.onSurface.withValues(alpha: 0.32)
                            : scheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

