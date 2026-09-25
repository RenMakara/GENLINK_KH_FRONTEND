import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

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
    this.radius,
  });

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
    this.radius,
  }) : obscure = false,
       maxLines = 1,
       maxLength = null,
       keyboardType = TextInputType.emailAddress,
       textCapitalization = TextCapitalization.none,
       inputFormatters = null;

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
    this.radius,
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
  final double? radius;

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
          obscuringCharacter: '●',
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

  InputDecorationThemeData _decorationTheme(ThemeData theme) {
    final base = theme.inputDecorationTheme;

    InputBorder reshape(InputBorder? border) {
      if (border is! OutlineInputBorder) {
        return border ?? const OutlineInputBorder();
      }
      final r = widget.radius ??
          (widget.maxLines > 1 && !widget.obscure
              ? AppRadius.xl
              : AppRadius.pill);
      return border.copyWith(borderRadius: BorderRadius.circular(r));
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
      final theme = Theme.of(context);
      return GestureDetector(
        onTap: () => setState(() => _obscured = !_obscured),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _obscured ? 'common.show'.tr : 'common.hide'.tr,
                style: theme.inputDecorationTheme.hintStyle,
              ),
            ],
          ),
        ),
      );
    }
    return widget.suffix;
  }
}
