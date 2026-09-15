import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import '../../domain/models/community_post_model.dart';

class PollWidget extends StatefulWidget {
  final String? postId;
  final String question;
  final List<PollOptionModel> options;
  final int? totalVotes;
  final bool? hasVoted;
  final String? myOptionId;
  final String? duration;
  final bool hideResultsUntilVote;
  final Future<void> Function(String optionId)? onVote;

  const PollWidget({
    super.key,
    this.postId,
    required this.question,
    required this.options,
    this.totalVotes,
    this.hasVoted,
    this.myOptionId,
    this.duration,
    this.hideResultsUntilVote = true,
    this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  String? _votingOptionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final bool userHasVoted = (widget.hasVoted == true) ||
        widget.options.any((o) => o.isVoted) ||
        (widget.myOptionId != null && widget.myOptionId!.isNotEmpty);

    final bool showResults = !widget.hideResultsUntilVote || userHasVoted;

    final int computedVotes = widget.options.fold(0, (sum, opt) => sum + opt.votes);
    final int totalVotes = (widget.totalVotes != null && widget.totalVotes! > 0)
        ? widget.totalVotes!
        : computedVotes;

    final String voteWord = totalVotes == 1
        ? ('community.pollVote'.tr.isNotEmpty && 'community.pollVote'.tr != 'community.pollVote'
            ? 'community.pollVote'.tr
            : 'vote')
        : ('community.pollVotes'.tr.isNotEmpty && 'community.pollVotes'.tr != 'community.pollVotes'
            ? 'community.pollVotes'.tr
            : 'votes');
    final String voteText = '$totalVotes $voteWord';

    final String durationText = widget.duration != null && widget.duration!.isNotEmpty
        ? ('community.pollEndsIn'.tr.isNotEmpty && 'community.pollEndsIn'.tr != 'community.pollEndsIn'
            ? '${'community.pollEndsIn'.tr} ${widget.duration}'
            : 'Ends ${widget.duration}')
        : ('community.pollEnded'.tr.isNotEmpty && 'community.pollEnded'.tr != 'community.pollEnded'
            ? 'community.pollEnded'.tr
            : 'Ended');

    final bool isEnded = widget.duration?.toLowerCase() == 'ended';
    final bool isBusy = _votingOptionId != null;

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
            style: theme.textTheme.titleMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  height: 1.35,
                ) ??
                TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),

          ...widget.options.map((opt) {
            final double pctRatio = totalVotes > 0
                ? (opt.votes / totalVotes).clamp(0.0, 1.0)
                : 0.0;
            final int pctValue = (pctRatio * 100).round();

            final bool isThisOptionSelected = opt.isVoted ||
                (widget.myOptionId != null &&
                    widget.myOptionId!.isNotEmpty &&
                    (opt.id == widget.myOptionId ||
                        opt.text == widget.myOptionId));

            final bool isThisOptionVoting = _votingOptionId == opt.id;

            final bool canTapThisOption = !isEnded && !isBusy && !isThisOptionSelected;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PollOptionWidget(
                option: opt,
                pctRatio: pctRatio,
                pctValue: pctValue,
                showResults: showResults,
                isVoted: isThisOptionSelected,
                isLoading: isThisOptionVoting,
                isDark: isDark,
                onTap: canTapThisOption
                    ? () => _handleVote(opt)
                    : null,
              ),
            );
          }),

          const SizedBox(height: 6),

          Text(
            "$voteText • $durationText",
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

  Future<void> _handleVote(PollOptionModel option) async {
    if (widget.onVote == null) {
      // Fallback for isolated widget testing or demo mode without callback
      setState(() {
        for (final o in widget.options) {
          if (o.id == option.id || (o.id.isEmpty && o.text == option.text)) {
            o.isVoted = true;
            o.votes += 1;
          } else if (o.isVoted && o.votes > 0) {
            o.isVoted = false;
            o.votes -= 1;
          }
        }
      });
      return;
    }

    final targetId = option.id.isNotEmpty ? option.id : option.text;

    setState(() {
      _votingOptionId = option.id;
    });

    try {
      await widget.onVote!(targetId);
    } catch (e) {
      if (mounted) {
        final errorMsg = 'community.pollVoteFailed'.tr.isNotEmpty &&
                'community.pollVoteFailed'.tr != 'community.pollVoteFailed'
            ? 'community.pollVoteFailed'.tr
            : 'Could not submit vote. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _votingOptionId = null;
        });
      }
    }
  }
}

class PollOptionWidget extends StatefulWidget {
  final PollOptionModel option;
  final double pctRatio;
  final int pctValue;
  final bool showResults;
  final bool isVoted;
  final bool isLoading;
  final bool isDark;
  final VoidCallback? onTap;

  const PollOptionWidget({
    super.key,
    required this.option,
    required this.pctRatio,
    required this.pctValue,
    required this.showResults,
    required this.isVoted,
    this.isLoading = false,
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
      duration: const Duration(milliseconds: 140),
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
    final isVoted = widget.isVoted;

    // Light mode colors
    final Color lightUnselectedBg = const Color(0xFFF7F8FA);
    final Color lightSelectedBg = const Color(0xFFEBF5FF);
    final Color lightUnselectedBorder = const Color(0xFFE2E5E9);
    final Color lightSelectedBorder = const Color(0xFF1E88E5);
    final Color lightUnselectedText = Colors.black87;
    final Color lightSelectedText = const Color(0xFF0D47A1);
    final Color lightUnselectedFill = Colors.black.withValues(alpha: 0.05);
    final Color lightSelectedFill = const Color(0xFF1E88E5).withValues(alpha: 0.16);

    // Dark mode colors
    final Color darkUnselectedBg = const Color(0xFF1A1D22);
    final Color darkSelectedBg = const Color(0xFF162536);
    final Color darkUnselectedBorder = const Color(0xFF2C323B);
    final Color darkSelectedBorder = const Color(0xFF1E88E5);
    final Color darkUnselectedText = Colors.white;
    final Color darkSelectedText = const Color(0xFF90CAF9);
    final Color darkUnselectedFill = Colors.white.withValues(alpha: 0.07);
    final Color darkSelectedFill = const Color(0xFF1E88E5).withValues(alpha: 0.28);

    final Color bgColor = widget.isDark
        ? (isVoted ? darkSelectedBg : darkUnselectedBg)
        : (isVoted ? lightSelectedBg : lightUnselectedBg);

    final Color borderColor = widget.isDark
        ? (isVoted ? darkSelectedBorder : darkUnselectedBorder)
        : (isVoted ? lightSelectedBorder : lightUnselectedBorder);

    final Color textColor = widget.isDark
        ? (isVoted ? darkSelectedText : darkUnselectedText)
        : (isVoted ? lightSelectedText : lightUnselectedText);

    final Color fillColor = widget.isDark
        ? (isVoted ? darkSelectedFill : darkUnselectedFill)
        : (isVoted ? lightSelectedFill : lightUnselectedFill);

    final primaryBlue = const Color(0xFF1E88E5);

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
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isVoted ? 1.4 : 0.9,
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
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        widthFactor: widget.pctRatio,
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(13),
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
                            if (widget.isLoading) ...[
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else if (isVoted) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                color: widget.isDark ? const Color(0xFF64B5F6) : primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                widget.option.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textColor,
                                      fontWeight: isVoted
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ) ??
                                    TextStyle(
                                      color: textColor,
                                      fontWeight: isVoted
                                          ? FontWeight.w700
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
                            style: theme.textTheme.labelMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ) ??
                                TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
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
