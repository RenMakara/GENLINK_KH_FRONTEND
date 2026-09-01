import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.tooltip});

  final VoidCallback? onPressed;
  final String? tooltip;

  static const _height = 40.0;
  static const _width = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final button = SizedBox(
      height: _height,
      width: _width,
      child: Material(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
        shape: const StadiumBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          // Falls back to popping the current route so callers usually
          // pass nothing.
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.arrow_back,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    return Container(
      height: _height,
      width: _width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
        child: button,
      ),
    );
  }
}
