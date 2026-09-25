import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'chat_avatar.dart';

class GroupMemberTile extends StatelessWidget {
  final String name;
  final String handle;
  final String? avatarUrl;
  final bool isOnline;
  final bool isSelected;
  final bool isVerified;
  final VoidCallback onTap;

  const GroupMemberTile({
    super.key,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.isOnline = false,
    required this.isSelected,
    this.isVerified = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorderSubtle : const Color(0xFFE5E7EB);
    final defaultBg = isDark ? AppColors.darkSurfacePrimary : Colors.white;

    final tileBg = isSelected
        ? (isDark
            ? AppColors.chatPrimary.withValues(alpha: 0.16)
            : const Color(0xFFF1F6FE))
        : defaultBg;

    final cardBorderColor = isSelected
        ? AppColors.chatPrimary.withValues(alpha: 0.5)
        : borderColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardBorderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                ChatAvatar(
                  avatarUrl: avatarUrl,
                  name: name,
                  radius: 24,
                  isOnline: isOnline,
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.chatPrimary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        handle,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.chatPrimary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.chatPrimary
                          : (isDark ? AppColors.darkBorderStrong : const Color(0xFFD6DAE1)),
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
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
