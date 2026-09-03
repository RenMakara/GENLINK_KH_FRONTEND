import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

/// Settings hub: profile header, grouped navigation tiles, log out.
///
/// Individual preferences live on sub-screens (language, appearance,
/// privacy, account); this page only routes. Sections from the design with
/// no backend today — security, blocked users — are not shown rather than
/// rendered dead.
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          'settings.title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        final user = auth.currentUser.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            // ── Profile header row ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: user?.avatarUrl,
                    name: user?.fullName,
                    size: 46,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'profile.edit'.tr,
                    onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Account ────────────────────────────────────────────────
            _SectionLabel(text: 'settings.account'.tr),
            _HubTile(
              icon: Icons.person_outline,
              title: 'settings.accountSettings'.tr,
              subtitle: 'settings.accountSettingsHint'.tr,
              onTap: () => Get.toNamed<void>(AppRoutes.settingsAccount),
            ),

            // ── Preferences ────────────────────────────────────────────
            _SectionLabel(text: 'settings.preferences'.tr),
            Obx(
              () => _HubTile(
                icon: Icons.language,
                title: 'settings.language'.tr,
                subtitle:
                    controller.settings.value.language ==
                        UserSettingsEntity.languageKhmer
                    ? 'settings.languageKhmer'.tr
                    : 'settings.languageEnglish'.tr,
                onTap: () => Get.toNamed<void>(AppRoutes.settingsLanguage),
              ),
            ),
            Obx(
              () => _HubTile(
                icon: Icons.palette_outlined,
                title: 'settings.appearance'.tr,
                subtitle: _themeLabel(controller.settings.value.theme),
                onTap: () => Get.toNamed<void>(AppRoutes.settingsAppearance),
              ),
            ),
            Obx(
              () => SwitchListTile(
                secondary: const Icon(Icons.notifications_none),
                title: Text('settings.notifications'.tr),
                value: controller.settings.value.notificationEnabled,
                onChanged: controller.setNotificationEnabled,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
              ),
            ),

            // ── Privacy & security ─────────────────────────────────────
            _SectionLabel(text: 'settings.privacy'.tr),
            _HubTile(
              icon: Icons.lock_outline,
              title: 'settings.privacySettings'.tr,
              subtitle: 'settings.privacySettingsHint'.tr,
              onTap: () => Get.toNamed<void>(AppRoutes.settingsPrivacy),
            ),
            Obx(
              () => SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text('settings.biometric'.tr),
                value: controller.settings.value.biometricEnabled,
                onChanged: controller.setBiometricEnabled,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
              ),
            ),

            // ── About ──────────────────────────────────────────────────
            _SectionLabel(text: 'settings.support'.tr),
            _HubTile(
              icon: Icons.info_outline,
              title: 'settings.about'.tr,
              subtitle: 'GenLink KH',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'GenLink KH',
                applicationLegalese: 'settings.aboutLegalese'.tr,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            _LogOutTile(onTap: () => _confirmLogout(context)),
          ],
        );
      }),
    );
  }

  String _themeLabel(String theme) => switch (theme) {
    'LIGHT' => 'settings.themeLight'.tr,
    'DARK' => 'settings.themeDark'.tr,
    _ => 'settings.themeSystem'.tr,
  };

  /// The design's log-out confirmation: bottom sheet, avatar, red action.
  Future<void> _confirmLogout(BuildContext context) async {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    final theme = Theme.of(context);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(
                imageUrl: user?.avatarUrl,
                name: user?.fullName,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'auth.logoutConfirm'.tr,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text('auth.logout'.tr),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text('common.cancel'.tr),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed ?? false) await auth.logout();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}

class _LogOutTile extends StatelessWidget {
  const _LogOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(Icons.exit_to_app_rounded, color: error),
      title: Text('auth.logout'.tr, style: TextStyle(color: error)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}
