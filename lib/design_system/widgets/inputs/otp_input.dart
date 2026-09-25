import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.errorText,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final String? errorText;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers = List.generate(
    widget.length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    widget.length,
    (_) => FocusNode(),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _report() {
    final value = _value;
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted?.call(value);
    }
  }

  void _onChanged(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _distribute(digits, from: index);
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.collapsed(
      offset: digits.length,
    );

    if (digits.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    _report();
  }

  void _distribute(String digits, {required int from}) {
    for (var i = 0; i < widget.length; i++) {
      final digitIndex = i - from;
      if (i >= from && digitIndex < digits.length) {
        _controllers[i].text = digits[digitIndex];
      }
    }
    final lastFilled = (from + digits.length).clamp(0, widget.length) - 1;
    _nodes[lastFilled.clamp(0, widget.length - 1)].requestFocus();
    setState(() {});
    _report();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }
    _controllers[index - 1].clear();
    _nodes[index - 1].requestFocus();
    _report();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gaps = AppSpacing.xs * (widget.length - 1);
            final share = (constraints.maxWidth - gaps) / widget.length;
            final boxWidth = share.clamp(0.0, _OtpBox.maxWidth);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < widget.length; i++)
                  SizedBox(
                    width: boxWidth,
                    child: _OtpBox(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      autofocus: widget.autofocus && i == 0,
                      hasError: widget.errorText != null,
                      onChanged: (value) => _onChanged(i, value),
                      onKey: (event) => _onKey(i, event),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.errorText!,
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.hasError,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKey;

  static const height = 64.0;
  static const maxWidth = 59.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: height,
      child: Focus(
        onKeyEvent: (_, event) => onKey(event),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 1,
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: scheme.surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: _border(_strokeColor(scheme, hasError)),
            focusedBorder: _border(_strokeColor(scheme, hasError)),
            border: _border(_strokeColor(scheme, hasError)),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Color _strokeColor(ColorScheme scheme, bool hasError) =>
      hasError ? scheme.error : scheme.outlineVariant;

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      borderSide: BorderSide(color: color),
    );
  }
}
