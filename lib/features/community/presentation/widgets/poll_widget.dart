import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../../domain/models/community_post_model.dart';

class PollWidget extends StatefulWidget {
  final String question;
  final List<PollOptionModel> options;
  final String? duration;
  final bool hideResultsUntilVote;

  const PollWidget({
    super.key,
    required this.question,
    required this.options,
    this.duration,
    this.hideResultsUntilVote = true,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final bool hasVoted = widget.options.any((o) => o.isVoted);
    final bool showResults = !widget.hideResultsUntilVote || hasVoted;

    int totalVotes = widget.options.fold(0, (sum, opt) => sum + opt.votes);
    if (totalVotes == 0) totalVotes = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Question Title
          Text(
            widget.question,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ) ??
                TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),

          // 2. Poll Option Progress Cards
          ...widget.options.map((opt) {
            final double pctRatio = (opt.votes / totalVotes).clamp(0.0, 1.0);
            final int pctValue = (pctRatio * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PollOptionWidget(
                option: opt,
                pctRatio: pctRatio,
                pctValue: pctValue,
                showResults: showResults,
                onTap: () {
                  setState(() {
                    opt.isVoted = !opt.isVoted;
                    opt.votes += opt.isVoted ? 1 : -1;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 6),

          // 3. Footer Subtitle
          Text(
            "${widget.options.fold(0, (sum, o) => sum + o.votes)} votes • Ends in ${widget.duration ?? '3 days'}",
            style: theme.textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class PollOptionWidget extends StatefulWidget {
  final PollOptionModel option;
  final double pctRatio;
  final int pctValue;
  final bool showResults;
  final VoidCallback onTap;

  const PollOptionWidget({
    super.key,
    required this.option,
    required this.pctRatio,
    required this.pctValue,
    required this.showResults,
    required this.onTap,
  });

  @override
  State<PollOptionWidget> createState() => _PollOptionWidgetState();
}

class _PollOptionWidgetState extends State<PollOptionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;

    final bool isVoted = widget.option.isVoted;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: isVoted
                ? AppColors.communityAccent.withValues(alpha: 0.30)
                : surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isVoted
                  ? AppColors.communityAccent
                  : borderSubtle,
              width: isVoted ? 1.5 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Smooth Fill Animation Bar
              if (widget.showResults)
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  widthFactor: widget.pctRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isVoted
                          ? AppColors.communityAccent.withValues(alpha: 0.30)
                          : (isDark ? AppColors.darkSurfacePrimary.withValues(alpha: 0.5) : AppColors.lightSurfaceSecondary),
                      borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                    ),
                  ),
                ),

              // Option Title & Percentage Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isVoted) ...[
                          const Icon(Icons.check_circle_rounded, color: AppColors.communityAccent, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                        ] else if (!widget.showResults) ...[
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: textSecondary, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.option.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: isVoted ? AppColors.communityAccent : textPrimary,
                                fontWeight: isVoted ? FontWeight.bold : FontWeight.w500,
                              ) ??
                              TextStyle(
                                color: isVoted ? AppColors.communityAccent : textPrimary,
                                fontWeight: isVoted ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                    if (widget.showResults)
                      Text(
                        "${widget.pctValue}%",
                        style: theme.textTheme.labelMedium?.copyWith(
                              color: isVoted ? AppColors.communityAccent : textSecondary,
                              fontWeight: FontWeight.bold,
                            ) ??
                            TextStyle(
                              color: isVoted ? AppColors.communityAccent : textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
