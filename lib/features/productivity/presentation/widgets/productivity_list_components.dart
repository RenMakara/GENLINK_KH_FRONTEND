import 'package:flutter/material.dart';

import '../../../../design_system/widgets/buttons/app_back_button.dart';

/// Semantic colors helper for Productivity listing screens
class ListThemeColors {
  ListThemeColors(this.context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
    background = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    surfaceSecondary =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    textMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    ctaBackground = isDark ? Colors.white : const Color(0xFF181A1F);
    ctaForeground = isDark ? const Color(0xFF0F172A) : Colors.white;
  }

  final BuildContext context;
  late final bool isDark;
  late final Color background;
  late final Color surface;
  late final Color surfaceSecondary;
  late final Color border;
  late final Color textPrimary;
  late final Color textSecondary;
  late final Color textMuted;
  late final Color ctaBackground;
  late final Color ctaForeground;
}

/// 1. Top Screen Header with Circular Back Button, Bold Title, Subtitle, and Circular + Action
class ListScreenHeader extends StatelessWidget {
  const ListScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onAdd,
    this.addTooltip,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Back Button
          const AppBackButton(),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Circular Dark + Button
          Material(
            color: Colors.transparent,
            child: Tooltip(
              message: addTooltip ?? '',
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.ctaBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add_rounded,
                    color: colors.ctaForeground,
                    size: 22,
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

/// 2. Modern Gamified Hero Banner Card with 3D Illustration, Bold Headline, and Subtext
class ListHeroBanner extends StatelessWidget {
  const ListHeroBanner({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.titleColor,
    required this.subtitleColor,
    this.shadowColor,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color titleColor;
  final Color subtitleColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);
    final isDark = colors.isDark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  gradientColors.first.withValues(alpha: 0.30),
                  gradientColors.last.withValues(alpha: 0.18),
                ]
              : gradientColors,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : gradientColors.last.withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? gradientColors.last).withValues(
              alpha: isDark ? 0.20 : 0.15,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 3D illustration
          illustration,
          const SizedBox(width: 16),

          // Right: Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.70)
                        : subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

/// 3. Horizontal Pill Filter Carousel with Active Purple Pill & Checkmark
class PillFilterTabs<T> extends StatelessWidget {
  const PillFilterTabs({
    super.key,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.accentColor = const Color(0xFF8B5CF6),
  });

  final T selected;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(option),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accentColor : colors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        labelBuilder(option),
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.textPrimary,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

/// 4. Section Header with Title and Counter
class ListSectionHeader extends StatelessWidget {
  const ListSectionHeader({
    super.key,
    required this.title,
    required this.countText,
  });

  final String title;
  final String countText;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            countText,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Encouragement / Empty State Card with Centered 3D Vector & Black Pill CTA Button
class ListEncouragementCard extends StatelessWidget {
  const ListEncouragementCard({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onAction,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered 3D illustration
          illustration,
          const SizedBox(height: 16),

          // Title with emoji
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Black Squircle Pill CTA Button
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: colors.ctaBackground,
              foregroundColor: colors.ctaForeground,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: colors.ctaForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  buttonLabel,
                  style: TextStyle(
                    color: colors.ctaForeground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
