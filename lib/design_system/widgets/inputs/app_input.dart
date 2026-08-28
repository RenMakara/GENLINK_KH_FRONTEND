import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

/// The app's text field.
///
/// Decoration comes from `InputDecorationTheme`, so this widget only adds
/// the label row, the obscure-text toggle, and sane keyboard defaults.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
  });

  /// Email field with the right keyboard and no autocapitalisation.
  const AppInput.email({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
  }) : obscure = false,
       maxLines = 1,
       maxLength = null,
       keyboardType = TextInputType.emailAddress,
       textCapitalization = TextCapitalization.none,
       inputFormatters = null;

  /// Password field with the obscure toggle enabled.
  const AppInput.password({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
  }) : obscure = true,
       maxLines = 1,
       maxLength = null,
       keyboardType = null,
       textCapitalization = TextCapitalization.none,
       inputFormatters = null,
       suffix = null;

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            counterText: '',
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
            suffixIcon: _suffixIcon(),
          ).applyDefaults(_decorationTheme(theme)),
        ),
      ],
    );
  }

  /// Single-line fields are pills; multi-line ones fall back to the
  /// squircle, because a pill around four lines of text reads as a blob
  /// and wastes the corners.
  InputDecorationThemeData _decorationTheme(ThemeData theme) {
    final base = theme.inputDecorationTheme;
    if (widget.maxLines <= 1 || widget.obscure) return base;

    InputBorder reshape(InputBorder? border) {
      if (border is! OutlineInputBorder) {
        return border ?? const OutlineInputBorder();
      }
      return border.copyWith(borderRadius: BorderRadius.circular(AppRadius.xl));
    }

    return base.copyWith(
      border: reshape(base.border),
      enabledBorder: reshape(base.enabledBorder),
      focusedBorder: reshape(base.focusedBorder),
      errorBorder: reshape(base.errorBorder),
      focusedErrorBorder: reshape(base.focusedErrorBorder),
      disabledBorder: reshape(base.disabledBorder),
    );
  }

  Widget? _suffixIcon() {
    if (widget.obscure) {
      return IconButton(
        icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      );
    }
    return widget.suffix;
  }
}
