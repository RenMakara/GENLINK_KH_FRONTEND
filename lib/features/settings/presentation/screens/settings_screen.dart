import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        titleSpacing: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.title'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'settings.subtitle'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final user = auth.currentUser.value;
        final settings = controller.settings.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            _ProfileSummaryCard(
              user: user,
              onEdit: () => Get.toNamed<void>(AppRoutes.editProfile),
            ),

            _SectionLabel(text: 'settings.account'.tr),
            _SettingsGroup(
              rows: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  accent: AppColors.brandPrimary,
                  title: 'settings.accountSettings'.tr,
                  subtitle: 'settings.accountSettingsHint'.tr,
                  onTap: () => Get.toNamed<void>(AppRoutes.settingsAccount),
                ),
                _SettingsRow(
                  icon: Icons.badge_outlined,
                  accent: AppColors.productivityAccent,
                  title: 'settings.personalInformation'.tr,
                  subtitle: 'settings.personalInformationHint'.tr,
                  onTap: () => Get.toNamed<void>(AppRoutes.editProfile),
                ),
              ],
            ),

            _SectionLabel(text: 'settings.preferences'.tr),
            _SettingsGroup(
              rows: [
                _SettingsRow(
                  icon: Icons.language_rounded,
                  accent: AppColors.brandPrimary,
                  title: 'settings.language'.tr,
                  subtitle:
                      settings.language == UserSettingsEntity.languageKhmer
                      ? 'settings.languageKhmer'.tr
                      : 'settings.languageEnglish'.tr,
                  onTap: () => Get.toNamed<void>(AppRoutes.settingsLanguage),
                ),
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  accent: AppColors.warning,
                  title: 'settings.appearance'.tr,
                  subtitle: _themeLabel(settings.theme),
                  onTap: () => Get.toNamed<void>(AppRoutes.settingsAppearance),
                ),
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  accent: AppColors.danger,
                  title: 'settings.notifications'.tr,
                  subtitle: 'settings.notificationsHint'.tr,
                  trailing: Switch(
                    value: settings.notificationEnabled,
                    onChanged: controller.setNotificationEnabled,
                  ),
                ),
              ],
            ),

            _SectionLabel(text: 'settings.privacyData'.tr),
            _SettingsGroup(
              rows: [
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  accent: AppColors.productivityAccent,
                  title: 'settings.privacySettings'.tr,
                  subtitle: 'settings.privacySettingsHint'.tr,
                  onTap: () => Get.toNamed<void>(AppRoutes.settingsPrivacy),
                ),
                _SettingsRow(
                  icon: Icons.fingerprint_rounded,
                  accent: AppColors.success,
                  title: 'settings.biometric'.tr,
                  subtitle: 'settings.biometricHint'.tr,
                  trailing: Switch(
                    value: settings.biometricEnabled,
                    onChanged: controller.setBiometricEnabled,
                  ),
                ),
              ],
            ),

            _SectionLabel(text: 'settings.support'.tr),
            _SettingsGroup(
              rows: [
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  accent: AppColors.warning,
                  title: 'settings.about'.tr,
                  subtitle: 'settings.version'.tr,
                  onTap: () => Get.toNamed<void>(AppRoutes.settingsAbout),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            _LogOutButton(onTap: () => _confirmLogout(context)),
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

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.user, required this.onEdit});

  final UserEntity? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final role = _humanizeRole(
      user?.workStatus?.trim().isNotEmpty == true
          ? user?.workStatus
          : user?.role,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                imageUrl: user?.avatarUrl,
                name: user?.fullName,
                size: 58,
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 3),
                  ),
                ),
              ),
            ],
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.66),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          role.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onEdit,
            tooltip: 'profile.edit'.tr,
            icon: Icon(Icons.edit_outlined, color: scheme.primary, size: 22),
          ),
        ],
      ),
    );
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
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 76,
                endIndent: AppSpacing.md,
                color: scheme.outlineVariant,
              ),
            rows[index],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trailingWidget =
        trailing ??
        (onTap == null
            ? const SizedBox(width: 4)
            : Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: scheme.onSurface.withValues(alpha: 0.58),
              ));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + 2,
            AppSpacing.sm,
            AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              _SettingsIcon(icon: icon, accent: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accent, size: 24),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Material(
      color: error.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: error.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: error, size: 25),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'auth.logout'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _humanizeRole(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return '';

  return normalized
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
