import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'chat_avatar.dart';

class GroupMemberTile extends StatelessWidget {
  final String name;
  final String handle;
  final String? avatarUrl;
  final bool isOnline;
  final bool isSelected;
  final VoidCallback onTap;

  const GroupMemberTile({
    super.key,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.isOnline = false,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final defaultBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

    final tileBg = isSelected
        ? AppColors.chatPrimary.withValues(alpha: isDark ? 0.16 : 0.08)
        : defaultBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.chatPrimary : borderColor,
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              children: [
                ChatAvatar(
                  avatarUrl: avatarUrl,
                  name: name,
                  radius: 20,
                  isOnline: isOnline,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        handle,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.chatPrimary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.chatPrimary : borderColor,
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
      ),
    );
  }
}
