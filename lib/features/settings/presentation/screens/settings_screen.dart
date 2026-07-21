import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoader();

        final settings = controller.settings.value;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _SectionHeader(title: 'settings.appearance'.tr),
            _ChoiceTile(
              title: 'settings.theme'.tr,
              value: settings.theme,
              options: {
                UserSettingsEntity.themeLight: 'settings.themeLight'.tr,
                UserSettingsEntity.themeDark: 'settings.themeDark'.tr,
                UserSettingsEntity.themeSystem: 'settings.themeSystem'.tr,
              },
              onSelected: controller.setTheme,
            ),
            _ChoiceTile(
              title: 'settings.language'.tr,
              value: settings.language,
              options: {
                LocalizationService.khmer: 'settings.languageKhmer'.tr,
                LocalizationService.english: 'settings.languageEnglish'.tr,
              },
              onSelected: controller.setLanguage,
            ),

            const Divider(),
            _SectionHeader(title: 'settings.notifications'.tr),
            SwitchListTile(
              title: Text('settings.notificationsEnabled'.tr),
              value: settings.notificationEnabled,
              onChanged: controller.setNotificationEnabled,
            ),

            const Divider(),
            _SectionHeader(title: 'settings.privacy'.tr),
            _ChoiceTile(
              title: 'settings.privacyProfile'.tr,
              value: settings.privacyProfile,
              options: {
                for (final option in UserSettingsEntity.privacyOptions)
                  option: _titleCase(option),
              },
              onSelected: controller.setPrivacyProfile,
            ),
            SwitchListTile(
              title: Text('settings.allowMessages'.tr),
              value: settings.allowMessages,
              onChanged: controller.setAllowMessages,
            ),
            SwitchListTile(
              title: Text('settings.allowFollowRequest'.tr),
              value: settings.allowFollowRequest,
              onChanged: controller.setAllowFollowRequest,
            ),

            const Divider(),
            _SectionHeader(title: 'settings.security'.tr),
            SwitchListTile(
              title: Text('settings.biometric'.tr),
              value: settings.biometricEnabled,
              onChanged: controller.setBiometricEnabled,
            ),

            const Divider(),
            _SectionHeader(title: 'settings.account'.tr),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'auth.logout'.tr,
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  final confirmed = await AppDialog.confirm(
                    title: 'auth.logoutConfirm'.tr,
                    confirmLabel: 'auth.logout'.tr,
                    destructive: true,
                  );
                  if (confirmed) await Get.find<AuthController>().logout();
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _titleCase(String enumValue) => enumValue
      .split('_')
      .map((word) =>
          word.isEmpty ? word : word[0] + word.substring(1).toLowerCase())
      .join(' ');
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A tile that opens a single-choice bottom sheet.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(options[value] ?? value),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            RadioGroup<String>(
              groupValue: value,
              onChanged: (selectedValue) =>
                  Navigator.of(sheetContext).pop(selectedValue),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in options.entries)
                    RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (selected != null && selected != value) onSelected(selected);
  }
}
