import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.size = 36.0,
    this.iconSize = 19.0,
    this.hasShadow = true,
  });

  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final button = SizedBox(
      height: size,
      width: size,
      child: Material(
        color: theme.colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ]
            : null,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Tooltip(
        message: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
        child: button,
      ),
    );
  }
}
