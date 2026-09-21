import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';

class FocusDurationSheet extends StatefulWidget {
  const FocusDurationSheet({super.key, required this.initialDuration});

  final int initialDuration;

  static Future<int?> show(
    BuildContext context, {
    required int initialDuration,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          FocusDurationSheet(initialDuration: initialDuration),
    );
  }

  @override
  State<FocusDurationSheet> createState() => _FocusDurationSheetState();
}

class _FocusDurationSheetState extends State<FocusDurationSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      _DurationOption(
        minutes: 25,
        title: 'focus.duration25'.tr,
        subtitle: '${'focus.modePomodoro'.tr} • ${'focus.duration25Subtitle'.tr}',
        icon: Icons.timer_outlined,
        iconBgColor: const Color(0xFFFF5252).withValues(alpha: 0.12),
        iconColor: const Color(0xFFFF5252),
      ),
      _DurationOption(
        minutes: 50,
        title: 'focus.duration50'.tr,
        subtitle: '${'focus.modeDeepFocus'.tr} • ${'focus.duration50Subtitle'.tr}',
        icon: Icons.psychology_rounded,
        iconBgColor: AppColors.productivityAccent.withValues(alpha: 0.12),
        iconColor: AppColors.productivityAccent,
      ),
      _DurationOption(
        minutes: 90,
        title: 'focus.duration90'.tr,
        subtitle: '${'focus.modeLongFocus'.tr} • ${'focus.duration90Subtitle'.tr}',
        icon: Icons.landscape_rounded,
        iconBgColor: const Color(0xFF388BFD).withValues(alpha: 0.12),
        iconColor: const Color(0xFF388BFD),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
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
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : AppColors.lightBorderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'focus.selectDuration'.tr,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: semantic.secondaryText,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Option Items
          for (final opt in options) ...[
            _OptionCard(
              option: opt,
              isSelected: _selected == opt.minutes,
              onTap: () => setState(() => _selected = opt.minutes),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),

          // Confirm Button
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.productivityAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: Text(
              'focus.confirm'.tr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationOption {
  const _DurationOption({
    required this.minutes,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  final int minutes;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _DurationOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.productivityAccent.withValues(
                    alpha: isDark ? 0.16 : 0.08,
                  )
                : (isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightSurfacePrimary),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? AppColors.productivityAccent
                  : (isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(option.icon, color: option.iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: semantic.secondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Radio / Check circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.productivityAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.productivityAccent
                        : (isDark
                            ? AppColors.darkBorderStrong
                            : AppColors.lightBorderStrong),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
