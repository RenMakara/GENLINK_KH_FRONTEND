import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import '../../spacing/app_spacing.dart';

/// Shared top header used by the primary application screens.
///
/// The header owns the common spacing, responsive typography, action-button
/// treatment, and semantic light/dark colors. Screen-specific actions remain
/// supplied by each feature so navigation and behavior stay unchanged.
class AppScreenHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.actions = const <Widget>[],
    this.horizontalPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
    ),
    this.includeSafeArea = true,
    this.maxWidth = 760,
    this.toolbarHeight = 52,
  });

  static const double standardHeight = 52;

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry horizontalPadding;
  final bool includeSafeArea;
  final double maxWidth;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final width = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = width < 335;
    final isNarrow = width < 360;
    final titleFontSize = isVeryNarrow
        ? 21.0
        : (isNarrow ? 22.5 : 24.0);
    final titleLetterSpacing = isVeryNarrow
        ? -0.3
        : (isNarrow ? -0.4 : -0.5);
    final actionGap = isVeryNarrow ? 4.0 : (isNarrow ? 6.0 : 8.0);

    final toolbar = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          height: toolbarHeight,
          padding: horizontalPadding,
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: leading),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: titleWidget ??
                    _HeaderTitle(
                      title: title,
                      subtitle: subtitle,
                      fontSize: titleFontSize,
                      letterSpacing: titleLetterSpacing,
                      textColor: semantic.primaryText,
                      secondaryTextColor: semantic.secondaryText,
                    ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0) SizedBox(width: actionGap),
                      actions[index],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final content = includeSafeArea
        ? SafeArea(bottom: false, child: toolbar)
        : toolbar;

    return Container(color: semantic.background, child: content);
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.title,
    required this.subtitle,
    required this.fontSize,
    required this.letterSpacing,
    required this.textColor,
    required this.secondaryTextColor,
  });

  final String title;
  final String? subtitle;
  final double fontSize;
  final double letterSpacing;
  final Color textColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: letterSpacing,
            height: 1.2,
          ) ??
          TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: letterSpacing,
            height: 1.2,
          ),
    );

    if (subtitle == null || subtitle!.trim().isEmpty) return titleText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        const SizedBox(height: 2),
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ) ??
              TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

/// Consistent tactile action button used in all primary screen headers.
class AppHeaderActionButton extends StatelessWidget {
  const AppHeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.hasBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final width = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = width < 335;
    final isNarrow = width < 360;
    final buttonSize = isVeryNarrow ? 36.0 : (isNarrow ? 38.0 : 40.0);
    final iconSize = isVeryNarrow ? 19.0 : (isNarrow ? 20.0 : 20.5);
    final borderRadius = BorderRadius.circular(buttonSize * 0.30);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Ink(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: semantic.surface,
                borderRadius: borderRadius,
                border: Border.all(color: semantic.borderSubtle, width: 0.8),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: iconSize, color: semantic.primaryText),
                    if (hasBadge)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 7.5,
                          height: 7.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.danger,
                            border: Border.all(
                              color: semantic.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
