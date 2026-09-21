import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';

/// Form color scheme resolving Light and Dark mode consistently.
class FormThemeColors {
  FormThemeColors(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
  Color get ctaBackground =>
      isDark ? Colors.white : const Color(0xFF0F172A);
  Color get ctaForeground =>
      isDark ? const Color(0xFF0F172A) : Colors.white;
}

/// 1. Standard Form Scaffold with keyboard dismissal on tap outside
class CreationFormScaffold extends StatelessWidget {
  const CreationFormScaffold({
    super.key,
    required this.header,
    required this.children,
    this.bottomBar,
  });

  final Widget header;
  final List<Widget> children;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: children,
                ),
              ),
              ?bottomBar,
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Clean iOS-Style Header Bar with Title, Subtitle, Close Button & Save Pill
class CreationFormHeader extends StatelessWidget {
  const CreationFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSave,
    this.onClose,
    this.isSaving = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSave;
  final VoidCallback? onClose;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button (×)
          IconButton(
            onPressed: onClose ?? () => Get.back(),
            splashRadius: 22,
            icon: Icon(
              Icons.close_rounded,
              color: colors.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 4),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Save Button Pill
          FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: colors.ctaBackground,
              foregroundColor: colors.ctaForeground,
              disabledBackgroundColor:
                  colors.ctaBackground.withValues(alpha: 0.6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              minimumSize: const Size(68, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.ctaForeground),
                    ),
                  )
                : Text(
                    'common.save'.tr,
                    style: TextStyle(
                      color: colors.ctaForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 3. Compact Contextual Hero Card with Soft 3D Illustration & Motivational Quote
class CreationHeroCard extends StatelessWidget {
  const CreationHeroCard({
    super.key,
    required this.illustration,
    required this.quote,
    required this.gradientColors,
    required this.quoteColor,
    required this.sparkleColor,
  });

  final Widget illustration;
  final String quote;
  final List<Color> gradientColors;
  final Color quoteColor;
  final Color sparkleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  gradientColors.first.withValues(alpha: 0.35),
                  gradientColors.last.withValues(alpha: 0.20),
                ]
              : gradientColors,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : gradientColors.last.withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: isDark ? 0.20 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 3D Illustration
          illustration,
          const SizedBox(width: 14),

          // Right: Motivational Phrase with ✦ Sparkle
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✦ ',
                  style: TextStyle(
                    color: isDark ? Colors.white : sparkleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      color: isDark ? Colors.white : quoteColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
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

/// 4. Section Label with optional required red asterisk (*)
class CreationSectionLabel extends StatelessWidget {
  const CreationSectionLabel({
    super.key,
    required this.label,
    this.isRequired = false,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 5. Polished Text Input Field with leading icon container and optional character limit
class CreationTextField extends StatefulWidget {
  const CreationTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.leadingIcon,
    this.label,
    this.isRequired = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.accentColor = AppColors.productivityAccent,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget leadingIcon;
  final String? label;
  final bool isRequired;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Color accentColor;

  @override
  State<CreationTextField> createState() => _CreationTextFieldState();
}

class _CreationTextFieldState extends State<CreationTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted && widget.maxLength != null) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);
    final length = widget.controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          CreationSectionLabel(
            label: widget.label!,
            isRequired: widget.isRequired,
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? widget.accentColor
                  : colors.border,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            12,
            widget.maxLines > 1 ? 12 : 6,
            14,
            widget.maxLines > 1 ? 8 : 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: widget.maxLines > 1
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: widget.maxLines > 1 ? 2 : 0,
                      right: 10,
                    ),
                    child: widget.leadingIcon,
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      maxLines: widget.maxLines,
                      textInputAction: widget.textInputAction,
                      onSubmitted: widget.onSubmitted,
                      cursorColor: widget.accentColor,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: widget.maxLines > 1
                            ? const EdgeInsets.symmetric(vertical: 4)
                            : const EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.maxLength != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$length/${widget.maxLength}',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 6. Compact Selectable Card (used for Goal Type, Priority, Frequency)
class SelectionOptionCard extends StatelessWidget {
  const SelectionOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.accentColor = const Color(0xFF22C55E),
    this.indicatorColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? icon;
  final Color accentColor;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);
    final isDark = colors.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? accentColor.withValues(alpha: 0.22)
                    : accentColor.withValues(alpha: 0.10))
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : colors.border,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Check Badge at Top-Right when selected
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Content: Icon + Label
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(height: 6),
                    ] else if (indicatorColor != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: indicatorColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : accentColor)
                            : colors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
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

/// 7. Modern Dropdown Field Card with Modal Bottom Sheet Picker
class CreationDropdownCard extends StatelessWidget {
  const CreationDropdownCard({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.leadingIcon,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.itemIconBuilder,
    this.sheetTitle,
    this.accentColor = AppColors.productivityAccent,
  });

  final String label;
  final String value;
  final List<String> values;
  final Widget leadingIcon;
  final String Function(String item) itemLabelBuilder;
  final ValueChanged<String> onChanged;
  final Widget Function(String item, bool isSelected)? itemIconBuilder;
  final String? sheetTitle;
  final Color accentColor;

  void _showPicker(BuildContext context) {
    final colors = FormThemeColors(context);
    final isDark = colors.isDark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sheetTitle ?? label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of options
                ...values.map((item) {
                  final isSelected = item == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onChanged(item);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? accentColor.withValues(alpha: 0.22)
                                    : accentColor.withValues(alpha: 0.10))
                                : colors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? accentColor : colors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (itemIconBuilder != null)
                                itemIconBuilder!(item, isSelected)
                              else
                                leadingIcon,
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  itemLabelBuilder(item),
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDark ? Colors.white : accentColor)
                                        : colors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: accentColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreationSectionLabel(label: label),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPicker(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  leadingIcon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      itemLabelBuilder(value),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 8. Action Picker Card (Target, Deadline, Due Date, Reminder)
class CreationPickerCard extends StatelessWidget {
  const CreationPickerCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onClear,
    this.showTrailingArrow = true,
  });

  final Widget leadingIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool showTrailingArrow;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: colors.textMuted,
                  ),
                )
              else if (showTrailingArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 9. Milestone Manager Card with Lavender Tint and `+ Add Milestone` Button
class CreationMilestonesCard extends StatelessWidget {
  const CreationMilestonesCard({
    super.key,
    required this.milestones,
    required this.onAddMilestone,
    required this.onRemoveMilestone,
  });

  final List<String> milestones;
  final VoidCallback onAddMilestone;
  final ValueChanged<int> onRemoveMilestone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = FormThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF581C87).withValues(alpha: 0.22)
            : const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFFA855F7).withValues(alpha: 0.35)
              : const Color(0xFFE9D5FF),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Purple Flag Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF7E22CE).withValues(alpha: 0.45)
                      : const Color(0xFFF3E8FF),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF9333EA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'goals.create.addMilestones'.tr,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'goals.create.milestonesSubtitle'.tr,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Add Milestone Pill Button
              OutlinedButton(
                onPressed: onAddMilestone,
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF7E22CE).withValues(alpha: 0.3)
                      : Colors.white,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFFA855F7).withValues(alpha: 0.5)
                        : const Color(0xFFD8B4FE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'goals.create.addMilestoneBtn'.tr,
                  style: const TextStyle(
                    color: Color(0xFF9333EA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // List of added milestones (if any)
          if (milestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                milestones.length,
                (index) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF6B21A8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFC084FC)
                          : const Color(0xFFE9D5FF),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: Color(0xFF9333EA),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        milestones[index],
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onRemoveMilestone(index),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 10. Motivational Card (Green for Goal, Coral for Habit)
class CreationMotivationCard extends StatelessWidget {
  const CreationMotivationCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.isGreen = true,
  });

  final String title;
  final String subtitle;
  final bool isGreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTint = isGreen
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFF7ED));
    final borderTint = isGreen
        ? (isDark
            ? const Color(0xFF059669).withValues(alpha: 0.4)
            : const Color(0xFFA7F3D0))
        : (isDark
            ? const Color(0xFFEA580C).withValues(alpha: 0.4)
            : const Color(0xFFFFEDD5));
    final titleColor = isGreen
        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
        : (isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C));
    final subtitleColor = isGreen
        ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFFED7AA) : const Color(0xFFEA580C));

    return Container(
      decoration: BoxDecoration(
        color: primaryTint.withValues(alpha: isDark ? 0.35 : 1.0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderTint),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Soft3DSproutIcon(size: 38, isGreen: isGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
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

/// 11. Full-Width Bottom CTA Button
class CreationPrimaryButton extends StatelessWidget {
  const CreationPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = FormThemeColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.ctaBackground,
            foregroundColor: colors.ctaForeground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.ctaForeground),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: colors.ctaForeground,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Soft 3D Sprout / Seedling Icon for motivational cards
class Soft3DSproutIcon extends StatelessWidget {
  const Soft3DSproutIcon({
    super.key,
    this.size = 36,
    this.isGreen = true,
  });

  final double size;
  final bool isGreen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SproutPainter(isGreen: isGreen),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.isGreen});
  final bool isGreen;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Small ambient base shadow
    canvas.drawOval(
      Rect.fromLTWH(w * 0.20, h * 0.84, w * 0.60, h * 0.16),
      Paint()
        ..color = (isGreen ? const Color(0xFF10B981) : const Color(0xFFF97316))
            .withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pot / Base Mound
    final potPath = Path()
      ..moveTo(w * 0.28, h * 0.58)
      ..lineTo(w * 0.72, h * 0.58)
      ..lineTo(w * 0.65, h * 0.88)
      ..cubicTo(w * 0.60, h * 0.94, w * 0.40, h * 0.94, w * 0.35, h * 0.88)
      ..close();

    final potPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isGreen
            ? [const Color(0xFF86EFAC), const Color(0xFF22C55E)]
            : [const Color(0xFFFDBA74), const Color(0xFFEA580C)],
      ).createShader(Rect.fromLTWH(w * 0.28, h * 0.58, w * 0.44, h * 0.36));
    canvas.drawPath(potPath, potPaint);

    // Stem
    final stemPath = Path()
      ..moveTo(w * 0.50, h * 0.60)
      ..cubicTo(w * 0.49, h * 0.42, w * 0.51, h * 0.34, w * 0.50, h * 0.26);

    canvas.drawPath(
      stemPath,
      Paint()
        ..color = isGreen ? const Color(0xFF16A34A) : const Color(0xFFC2410C)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Left Leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.50, h * 0.34)
      ..cubicTo(w * 0.30, h * 0.30, w * 0.18, h * 0.18, w * 0.22, h * 0.08)
      ..cubicTo(w * 0.38, h * 0.06, w * 0.46, h * 0.22, w * 0.50, h * 0.34)
      ..close();

    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isGreen
            ? [const Color(0xFF4ADE80), const Color(0xFF15803D)]
            : [const Color(0xFFFED7AA), const Color(0xFFF97316)],
      ).createShader(Rect.fromLTWH(w * 0.18, h * 0.06, w * 0.64, h * 0.32));
    canvas.drawPath(leftLeaf, leafPaint);

    // Right Leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..cubicTo(w * 0.64, h * 0.24, w * 0.78, h * 0.16, w * 0.82, h * 0.12)
      ..cubicTo(w * 0.76, h * 0.06, w * 0.58, h * 0.14, w * 0.50, h * 0.30)
      ..close();
    canvas.drawPath(rightLeaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
