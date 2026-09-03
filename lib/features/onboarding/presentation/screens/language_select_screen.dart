import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../controllers/language_select_controller.dart';

/// "Choose your language" — step 1 of the first-run flow.
class LanguageSelectScreen extends GetView<LanguageSelectController> {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'onboarding.stepOf'.trParams({
                        'step': '${LanguageSelectController.step}',
                        'total': '${LanguageSelectController.totalSteps}',
                      }).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'onboarding.chooseLanguage'.tr,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'onboarding.chooseLanguageHint'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Obx(
                      () => Column(
                        children: [
                          _LanguageOption(
                            // Always shown in its own script — a user who
                            // cannot read the current language still
                            // recognises theirs.
                            title: 'ភាសាខ្មែរ',
                            subtitle: 'Khmer',
                            selected:
                                controller.selected.value ==
                                LocalizationService.khmer,
                            onTap: () =>
                                controller.select(LocalizationService.khmer),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _LanguageOption(
                            title: 'English',
                            subtitle: 'English',
                            selected:
                                controller.selected.value ==
                                LocalizationService.english,
                            onTap: () =>
                                controller.select(LocalizationService.english),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'settings.appearance'.tr,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'settings.appearanceHint'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _ThemeOption(
                              label: 'settings.themeLight'.tr,
                              icon: Icons.light_mode_outlined,
                              selected:
                                  controller.selectedTheme.value ==
                                  ThemeMode.light,
                              onTap: () =>
                                  controller.selectTheme(ThemeMode.light),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _ThemeOption(
                              label: 'settings.themeDark'.tr,
                              icon: Icons.dark_mode_outlined,
                              selected:
                                  controller.selectedTheme.value ==
                                  ThemeMode.dark,
                              onTap: () =>
                                  controller.selectTheme(ThemeMode.dark),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _ThemeOption(
                              label: 'settings.themeSystem'.tr,
                              icon: Icons.brightness_auto_outlined,
                              selected:
                                  controller.selectedTheme.value ==
                                  ThemeMode.system,
                              onTap: () =>
                                  controller.selectTheme(ThemeMode.system),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Obx(
                () => Column(
                  children: [
                    AppButton(
                      label: 'common.continue'.tr,
                      loading: controller.isSaving.value,
                      onPressed: controller.continueToSplash,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'onboarding.bothLanguages'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable language card: filled and checked when active, quiet
/// surface with an empty ring when not.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
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

    final background = selected ? scheme.primary : scheme.surface;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: background,
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionDot(selected: selected, foreground: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected, required this.foreground});

  final bool selected;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.secondary : Colors.transparent,
        border: Border.all(
          color: selected ? Colors.transparent : scheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: scheme.onSecondary)
          : null,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.06)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 104,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
