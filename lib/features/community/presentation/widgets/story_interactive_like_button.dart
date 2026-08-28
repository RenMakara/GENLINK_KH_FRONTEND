import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

/// Natural, responsive, and lightweight Story Like Button.
///
/// Features a subtle 240ms heart pop (scale 1.0 → 1.15 → 1.0) with a soft radial
/// glow on Like, and an understated smooth transition on Unlike.
class StoryInteractiveLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final bool showCount;
  final VoidCallback onTap;

  const StoryInteractiveLikeButton({
    super.key,
    required this.isLiked,
    this.likesCount = 0,
    this.showCount = false,
    required this.onTap,
  });

  @override
  State<StoryInteractiveLikeButton> createState() =>
      _StoryInteractiveLikeButtonState();
}

class _StoryInteractiveLikeButtonState
    extends State<StoryInteractiveLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowOpacityAnimation;
  late Animation<double> _glowRadiusAnimation;

  @override
  void initState() {
    super.initState();

    // 240ms natural subtle pop & soft glow
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // 1.0 -> 1.15 -> 1.0 scale
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_popController);

    // Soft glow opacity (0.0 -> 0.30 -> 0.0)
    _glowOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.30)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.30, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_popController);

    // Soft glow expansion radius (8.0 -> 22.0)
    _glowRadiusAnimation = Tween<double>(begin: 8.0, end: 22.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant StoryInteractiveLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External like trigger (e.g. from canvas double-tap)
    if (!oldWidget.isLiked && widget.isLiked) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isLiked) {
      _popController.forward(from: 0.0);
    }
    widget.onTap();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isLiked ? 'Unlike story' : 'Like story',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: widget.showCount ? null : 44,
          height: widget.showCount ? 38 : 44,
          padding: widget.showCount
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: widget.showCount ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                widget.showCount ? BorderRadius.circular(19) : null,
            border: Border.all(
              color: widget.isLiked
                  ? AppColors.likedAccent.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isLiked
                    ? AppColors.likedAccent.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.showCount
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeartWithGlow(iconSize: 20),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.20),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _formatCount(widget.likesCount),
                        key: ValueKey<int>(widget.likesCount),
                        style: TextStyle(
                          color: widget.isLiked
                              ? AppColors.likedAccent
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: _buildHeartWithGlow(iconSize: 22),
                ),
        ),
      ),
    );
  }

  Widget _buildHeartWithGlow({required double iconSize}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Subtle Soft Pulse / Glow Halo (Visible only during Like pop)
        AnimatedBuilder(
          animation: _popController,
          builder: (context, _) {
            final opacity = _glowOpacityAnimation.value;
            if (opacity <= 0.001) return const SizedBox.shrink();

            final radius = _glowRadiusAnimation.value;
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.likedAccent.withValues(alpha: opacity),
              ),
            );
          },
        ),

        // Pop Scale Animated Heart Icon
        ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isLiked ? AppColors.likedAccent : Colors.white,
            size: iconSize,
          ),
        ),
      ],
    );
  }
}
