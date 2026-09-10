import 'package:flutter/material.dart';
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
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final bool hasVoted = widget.options.any((o) => o.isVoted);
    final bool showResults = !widget.hideResultsUntilVote || hasVoted;

    int totalVotes = widget.options.fold(0, (sum, opt) => sum + opt.votes);

    final String voteText = totalVotes == 1 ? "1 vote" : "$totalVotes votes";
    final String durationText = widget.duration != null
        ? "Ends ${widget.duration}"
        : "Ended";

    final bool isEnded = widget.duration?.toLowerCase() == 'ended';
    final bool canVote = !hasVoted && !isEnded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style:
                theme.textTheme.titleMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.35,
                ) ??
                TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),

          ...widget.options.map((opt) {
            final double pctRatio = totalVotes > 0
                ? (opt.votes / totalVotes).clamp(0.0, 1.0)
                : 0.0;
            final int pctValue = (pctRatio * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PollOptionWidget(
                option: opt,
                pctRatio: pctRatio,
                pctValue: pctValue,
                showResults: showResults,
                isDark: isDark,
                onTap: canVote
                    ? () {
                        setState(() {
                          opt.isVoted = true;
                          opt.votes += 1;
                        });
                      }
                    : null,
              ),
            );
          }),

          const SizedBox(height: 8),

          Text(
            "$voteText • $durationText",
            style:
                theme.textTheme.bodySmall?.copyWith(
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
  final bool isDark;
  final VoidCallback? onTap;

  const PollOptionWidget({
    super.key,
    required this.option,
    required this.pctRatio,
    required this.pctValue,
    required this.showResults,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<PollOptionWidget> createState() => _PollOptionWidgetState();
}

class _PollOptionWidgetState extends State<PollOptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _scaleController.forward(from: 0.0);
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVoted = widget.option.isVoted;

    final Color unselectedBg = widget.isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF3F4F6);
    final Color selectedBg = widget.isDark
        ? Colors.white
        : const Color(0xFFF3F4F6);

    final Color unselectedBorder = widget.isDark
        ? Colors.white12
        : Colors.black12;
    final Color selectedBorder = widget.isDark
        ? Colors.transparent
        : Colors.black12;

    final Color unselectedText = widget.isDark ? Colors.white : Colors.black87;
    final Color selectedText = Colors.black;

    final Color unselectedFill = widget.isDark
        ? Colors.white12
        : Colors.black12;
    final Color selectedFill = Colors.black12;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Semantics(
          label: isVoted
              ? "Selected poll option ${widget.option.text}, ${widget.pctValue} percent"
              : "Poll option ${widget.option.text}, ${widget.pctValue} percent",
          button: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 48,
            decoration: BoxDecoration(
              color: isVoted ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isVoted ? selectedBorder : unselectedBorder,
                width: 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.showResults)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        widthFactor: widget.pctRatio,
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isVoted ? selectedFill : unselectedFill,
                            borderRadius: BorderRadius.circular(
                              13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isVoted) ...[
                              const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                widget.option.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: isVoted
                                          ? selectedText
                                          : unselectedText,
                                      fontWeight: isVoted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ) ??
                                    TextStyle(
                                      color: isVoted
                                          ? selectedText
                                          : unselectedText,
                                      fontWeight: isVoted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showResults)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            "${widget.pctValue}%",
                            style:
                                theme.textTheme.labelMedium?.copyWith(
                                  color: isVoted
                                      ? selectedText
                                      : unselectedText,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                TextStyle(
                                  color: isVoted
                                      ? selectedText
                                      : unselectedText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
