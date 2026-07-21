import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

/// Theme chooser: three preview cards (light / dark / system).
///
/// Applies live through [SettingsController] — the page itself re-themes
/// the moment a card is tapped, which is the best possible preview.
/// The design's "glassmorphism effects" toggle has no backend field and is
/// not rendered.
class AppearanceSettingsScreen extends GetView<SettingsController> {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppBackButton(),
        ),
        leadingWidth: 58 + AppSpacing.md * 2,
        title: Text('settings.appearance'.tr),
      ),
      body: Obx(() {
        final current = controller.settings.value.theme;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'settings.appearanceHint'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeLight'.tr,
                    preview: Brightness.light,
                    selected: current == UserSettingsEntity.themeLight,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeLight),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeDark'.tr,
                    preview: Brightness.dark,
                    selected: current == UserSettingsEntity.themeDark,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeDark),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ThemeCard(
                    label: 'settings.themeSystem'.tr,
                    preview: null,
                    selected: current == UserSettingsEntity.themeSystem,
                    onTap: () =>
                        controller.setTheme(UserSettingsEntity.themeSystem),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

/// A miniature screen preview. [preview] null renders the half/half
/// "system" swatch.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Brightness? preview;
  final bool selected;
  final VoidCallback onTap;

  static const _light = Color(0xFFF7F7F5);
  static const _dark = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: preview == null
                ? const Row(
                    children: [
                      Expanded(child: ColoredBox(child: SizedBox.expand(), color: _light)),
                      Expanded(child: ColoredBox(child: SizedBox.expand(), color: _dark)),
                    ],
                  )
                : ColoredBox(
                    color: preview == Brightness.light ? _light : _dark,
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            size: 15,
            color: selected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
