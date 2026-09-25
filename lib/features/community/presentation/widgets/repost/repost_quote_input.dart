import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';

/// Quote input card with real-time character counter (0/500), tap-to-focus,
/// multiline support, and subtle focus styling.
class RepostQuoteInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int maxLength;

  const RepostQuoteInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.maxLength = 500,
  });

  @override
  State<RepostQuoteInput> createState() => _RepostQuoteInputState();
}

class _RepostQuoteInputState extends State<RepostQuoteInput> {
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant RepostQuoteInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _effectiveFocusNode.dispose();
      } else {
        _effectiveFocusNode.removeListener(_onFocusChanged);
      }
      _effectiveFocusNode = widget.focusNode ?? FocusNode();
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final boxBg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;

    final borderColor = _isFocused
        ? (isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong)
        : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle);

    final title = 'community.addQuoteOptional'.tr.isNotEmpty &&
            'community.addQuoteOptional'.tr != 'community.addQuoteOptional'
        ? 'community.addQuoteOptional'.tr
        : 'Add a quote (optional)';

    final subtitle = 'community.shareThoughtsWithCommunity'.tr.isNotEmpty &&
            'community.shareThoughtsWithCommunity'.tr != 'community.shareThoughtsWithCommunity'
        ? 'community.shareThoughtsWithCommunity'.tr
        : 'Share your thoughts with your community.';

    final hint = 'community.repostQuoteHint'.tr.isNotEmpty &&
            'community.repostQuoteHint'.tr != 'community.repostQuoteHint'
        ? 'community.repostQuoteHint'.tr
        : 'Add an optional quote caption...';

    final currentLength = widget.controller.text.length;
    final isNearLimit = currentLength >= widget.maxLength * 0.95;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Subtitle
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),

        // Text input container with tap-anywhere focus & bottom counter
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_effectiveFocusNode.hasFocus) {
              _effectiveFocusNode.requestFocus();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.3 : 0.9,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black)
                            .withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: widget.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  cursorColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  cursorWidth: 1.8,
                  cursorRadius: const Radius.circular(1.0),
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) =>
                      null, // Handled custom below
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    height: 1.45,
                    fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                      fontFamilyFallback: const ['KantumruyPro', 'Sora'],
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 6),
                // Reactive Character Counter
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '$currentLength/${widget.maxLength}',
                    style: TextStyle(
                      color: isNearLimit
                          ? (isDark ? const Color(0xFFFBBF24) : AppColors.warning)
                          : textMuted,
                      fontSize: 11.5,
                      fontWeight: isNearLimit ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
