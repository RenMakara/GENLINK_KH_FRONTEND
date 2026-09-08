import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

class AppearanceSettingsScreen extends GetView<SettingsController> {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          'settings.appearance'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        final current = controller.settings.value.theme;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(
              title: 'settings.theme'.tr,
              subtitle: 'settings.appearanceHint'.tr,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeLight'.tr,
                    mode: UserSettingsEntity.themeLight,
                    selected: current == UserSettingsEntity.themeLight,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeLight),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeDark'.tr,
                    mode: UserSettingsEntity.themeDark,
                    selected: current == UserSettingsEntity.themeDark,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeDark),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeSystem'.tr,
                    mode: UserSettingsEntity.themeSystem,
                    selected: current == UserSettingsEntity.themeSystem,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeSystem),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                _buildPreview(mode),
                if (selected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String mode) {
    if (mode == UserSettingsEntity.themeSystem) {
      return Row(
        children: [
          Expanded(child: _PreviewContent(isDark: false, isSplit: true)),
          Expanded(child: _PreviewContent(isDark: true, isSplit: true)),
        ],
      );
    }
    return _PreviewContent(isDark: mode == UserSettingsEntity.themeDark);
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.isDark, this.isSplit = false});
  final bool isDark;
  final bool isSplit;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBgPrimary : const Color(0xFFF9F9F7);
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : const Color(0xFFFFFFFF);
    final accent = isDark
        ? AppColors.darkPrimary.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.06);
    final barColor = isDark
        ? AppColors.darkAccentCyan.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.1);

    return Container(
      color: bg,
      padding: EdgeInsets.all(isSplit ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Header
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: accent, width: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          // Mock Content Row
          Row(
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 5,
                      width: '60%'.contains('%') ? 30 : 30, // Small line
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Mock Tab Bar / Action
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
