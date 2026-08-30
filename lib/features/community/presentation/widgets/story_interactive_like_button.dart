import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

/// Clean, minimal, and friendly Story Like Button.
///
/// Fast 180ms subtle micro-scale transition (0.95 → 1.06 → 1.0) with zero glow,
/// zero bounce, and zero particle clutter, matching GenLink's clean black/white UI.
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

  @override
  void initState() {
    super.initState();

    // Fast, crisp 180ms animation
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Subtle 0.95 -> 1.06 -> 1.0 scale animation with smooth easing and no bounce
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(covariant StoryInteractiveLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger subtle pop animation on like / unlike transitions
    if (oldWidget.isLiked != widget.isLiked) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
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
        child: Container(
          width: widget.showCount ? null : 38,
          height: 38,
          padding: widget.showCount
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: widget.showCount ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                widget.showCount ? BorderRadius.circular(19) : null,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.6,
            ),
          ),
          child: widget.showCount
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeart(iconSize: 18),
                    const SizedBox(width: 6),
                    Text(
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
                  ],
                )
              : Center(
                  child: _buildHeart(iconSize: 20),
                ),
        ),
      ),
    );
  }

  Widget _buildHeart({required double iconSize}) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.isLiked
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: widget.isLiked ? AppColors.likedAccent : Colors.white,
        size: iconSize,
      ),
    );
  }
}
