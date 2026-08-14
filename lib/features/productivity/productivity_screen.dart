import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/productivity/widget/productivity_screen_widget.dart';

class ProductivityPage extends StatelessWidget {
  const ProductivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,

      // No floating action button
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productivity',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  Row(
                    children: [
                      // Notification
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Profile
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'R',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              buildDailySummary(
                isDark: isDark,
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              buildTodayPlan(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              buildQuickActions(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 20),

              buildWeeklyFocus(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              buildGoalProgress(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 16),

              buildSmartInsight(
                isDark: isDark,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                border: border,
              ),

              const SizedBox(height: 16),

              buildRecentActivity(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
                border: border,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
