import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';

/// Read-only, six-cell representation of an OTP entered through
/// [OtpNumericKeypad]. It deliberately contains no editable field, so the
/// platform keyboard cannot cover the verification screen.
class OtpCodeDisplay extends StatelessWidget {
  const OtpCodeDisplay({
    super.key,
    required this.code,
    this.length = 6,
    this.errorText,
  });

  final String code;
  final int length;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIndex = code.length < length ? code.length : length - 1;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gaps = AppSpacing.sm * (length - 1);
            final share = (constraints.maxWidth - gaps) / length;
            final boxWidth = share.clamp(0.0, _OtpDigitCell.maxWidth);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                for (var index = 0; index < length; index++)
                  SizedBox(
                    width: boxWidth,
                    child: _OtpDigitCell(
                      key: ValueKey('otp-cell-$index'),
                      index: index,
                      digit: index < code.length ? code[index] : null,
                      isActive: index == activeIndex,
                      hasError: hasError,
                    ),
                  ),
              ],
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            key: const ValueKey('otp-error'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
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
    final strokeColor = hasError
        ? scheme.error
        : isActive
        ? scheme.primary
        : scheme.outlineVariant;

    return Semantics(
      label: digit == null
          ? 'auth.otpEmptyDigit'.trParams({'position': '${index + 1}'})
          : 'auth.otpEnteredDigit'.trParams({
              'position': '${index + 1}',
              'digit': digit!,
            }),
      selected: isActive,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: height,
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.06)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: strokeColor, width: isActive ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: digit == null
            ? _OtpCursor(color: scheme.primary, visible: isActive)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(digit!, style: theme.textTheme.titleLarge),
                  if (isActive) ...[
                    const SizedBox(width: 2),
                    _OtpCursor(color: scheme.primary),
                  ],
                ],
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

/// A platform-keyboard replacement laid out as 1–9, *, 0, backspace.
///
/// [onSymbolPressed] is optional so callers can explicitly opt into symbol
/// handling. It remains visible but disabled for numeric-only OTP flows.
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

  static const _keyHeight = 52.0;
  static const _rows = <List<String>>[
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', 'backspace'],
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
    final isBackspace = label == 'backspace';
    final semanticsLabel = isBackspace
        ? 'common.delete'.tr
        : label == '*'
        ? 'auth.otpSymbol'.tr
        : label;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      child: Material(
        color: onPressed == null
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? scheme.primary.withValues(alpha: 0.16)
                : null,
          ),
          child: SizedBox(
            height: height,
            child: Center(
              child: isBackspace
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 24,
                      color: scheme.onSurface,
                    )
                  : Text(
                      label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: onPressed == null
                            ? scheme.onSurface.withValues(alpha: 0.32)
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
