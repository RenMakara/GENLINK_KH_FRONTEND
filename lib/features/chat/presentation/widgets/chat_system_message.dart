import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ChatSystemMessage extends StatelessWidget {
  final String text;

  const ChatSystemMessage({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.75)
              : AppColors.lightBgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
            width: 0.8,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
