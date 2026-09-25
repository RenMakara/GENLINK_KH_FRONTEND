import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Minimal, sleek loading progress indicator with shimmer animation.
///
/// Avoids generic circular spinners in favor of a subtle branded progress capsule.
class SplashLoadingIndicator extends StatefulWidget {
  const SplashLoadingIndicator({
    super.key,
    this.caption = 'MORE OPPORTUNITIES AHEAD',
    this.reducedMotion = false,
  });

  final String? caption;
  final bool reducedMotion;

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (!widget.reducedMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SplashLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFF1F6FEB).withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sleek progress pill
        Container(
          width: 140,
          height: 4.5,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: widget.reducedMotion
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 70,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final indicatorWidth = w * 0.45;
                        final maxOffset = w - indicatorWidth;
                        final offset = t * maxOffset;

                        return Stack(
                          children: [
                            Positioned(
                              left: offset,
                              top: 0,
                              bottom: 0,
                              width: indicatorWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1F6FEB),
                                      Color(0xFF00D2B4),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1F6FEB).withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),

        if (widget.caption != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.caption!,
            style: TextStyle(
              fontFamily: AppTypography.englishFontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: isDark ? semantic.textMuted : semantic.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}
