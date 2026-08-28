import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

/// Language chooser — Khmer featured first, per the design.
///
/// Selection applies immediately (the whole app re-renders in the chosen
/// language) and persists optimistically through [SettingsController], so
/// there is no separate save button to forget.
class LanguageSettingsScreen extends GetView<SettingsController> {
  const LanguageSettingsScreen({super.key});

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
          'settings.language'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        final current = controller.settings.value.language;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'settings.languageHint'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LanguageCard(
              // Always shown in its own script, so a user who cannot read
              // the current language still finds theirs.
              title: 'ភាសាខ្មែរ',
              subtitle: 'Khmer',
              selected: current == UserSettingsEntity.languageKhmer,
              onTap: () =>
                  controller.setLanguage(UserSettingsEntity.languageKhmer),
            ),
            const SizedBox(height: AppSpacing.md),
            _LanguageCard(
              title: 'English',
              subtitle: 'English',
              selected: current == UserSettingsEntity.languageEnglish,
              onTap: () =>
                  controller.setLanguage(UserSettingsEntity.languageEnglish),
            ),
          ],
        );
      }),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
