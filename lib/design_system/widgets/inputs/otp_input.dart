import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../spacing/app_spacing.dart';

/// Six-box OTP entry.
///
/// One [TextField] per digit, auto-advancing forward on input and back on
/// delete. Pasting a full code into any box distributes it across all of
/// them, which is what happens when the user taps an SMS/email autofill
/// suggestion.
///
/// The joined value is reported through [onChanged]; [onCompleted] fires
/// once every box is filled so the caller can submit without a tap.
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
    // A multi-character value means a paste or an autofill suggestion:
    // spread the digits across the remaining boxes.
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _distribute(digits, from: index);
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection =
        TextSelection.collapsed(offset: digits.length);

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
    final lastFilled =
        (from + digits.length).clamp(0, widget.length) - 1;
    _nodes[lastFilled.clamp(0, widget.length - 1)].requestFocus();
    setState(() {});
    _report();
  }

  /// Backspace on an empty box steps back and clears the previous one, so
  /// deleting never strands the caret.
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < widget.length; i++)
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == widget.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: _OtpBox(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    autofocus: widget.autofocus && i == 0,
                    hasError: widget.errorText != null,
                    onChanged: (value) => _onChanged(i, value),
                    onKey: (event) => _onKey(i, event),
                  ),
                ),
              ),
          ],
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

  // Figma spec for a single box.
  static const width = 59.0;
  static const height = 65.0;
  static const radius = 26.0;

  /// Fill and stroke opacities from the design's glass treatment.
  static const _fillOpacity = 0.85;
  static const _strokeOpacity = 0.20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AspectRatio(
      // 59 x 65 in the design.
      aspectRatio: _OtpBox.width / _OtpBox.height,
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
          style: theme.textTheme.headlineMedium,
          // The single-digit maxLength would otherwise show "0/1".
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            // Glass fill: the surface at 85%, so the page tints through.
            fillColor: scheme.surface.withValues(alpha: _fillOpacity),
            contentPadding: EdgeInsets.zero,
            enabledBorder: _border(_strokeColor(scheme, hasError)),
            // Same border on focus — the caret and fill carry the state,
            // consistent with the other inputs.
            focusedBorder: _border(_strokeColor(scheme, hasError)),
            border: _border(_strokeColor(scheme, hasError)),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Color _strokeColor(ColorScheme scheme, bool hasError) => hasError
      ? scheme.error
      : scheme.onSurface.withValues(alpha: _strokeOpacity);

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color),
    );
  }
}
