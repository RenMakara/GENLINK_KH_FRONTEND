import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/settings_controller.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late final SettingsController _controller;

  static const _preferences = <_NotificationPreferenceDefinition>[
    _NotificationPreferenceDefinition(
      type: 'PRODUCTIVITY_TASK',
      titleKey: 'settings.productivityTaskNotifications',
      subtitleKey: 'settings.productivityTaskNotificationsHint',
      icon: Icons.task_alt_rounded,
    ),
    _NotificationPreferenceDefinition(
      type: 'PRODUCTIVITY_HABIT',
      titleKey: 'settings.productivityHabitNotifications',
      subtitleKey: 'settings.productivityHabitNotificationsHint',
      icon: Icons.local_fire_department_outlined,
    ),
    _NotificationPreferenceDefinition(
      type: 'PRODUCTIVITY_GOAL',
      titleKey: 'settings.productivityGoalNotifications',
      subtitleKey: 'settings.productivityGoalNotificationsHint',
      icon: Icons.flag_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _controller.loadNotificationPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Text(
          'settings.notificationPreferences'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isNotificationPreferencesLoading.value &&
            _controller.notificationPreferences.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = _controller.notificationPreferencesError.value;
        if (error != null && _controller.notificationPreferences.isEmpty) {
          return _ErrorState(
            message: error,
            onRetry: _controller.loadNotificationPreferences,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'settings.notificationPreferencesHint'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < _preferences.length; index++)
                    _PreferenceTile(
                      definition: _preferences[index],
                      enabled: _controller.notificationPreferenceEnabled(
                        _preferences[index].type,
                      ),
                      busy: _controller.isNotificationPreferenceBusy(
                        _preferences[index].type,
                      ),
                      onChanged: (value) =>
                          _controller.setNotificationPreference(
                            _preferences[index].type,
                            value,
                          ),
                      showDivider: index < _preferences.length - 1,
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _NotificationPreferenceDefinition {
  const _NotificationPreferenceDefinition({
    required this.type,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
  });

  final String type;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.definition,
    required this.enabled,
    required this.busy,
    required this.onChanged,
    required this.showDivider,
  });

  final _NotificationPreferenceDefinition definition;
  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = SwitchListTile(
      title: Text(definition.titleKey.tr),
      subtitle: Text(definition.subtitleKey.tr),
      value: enabled,
      onChanged: busy ? null : onChanged,
      secondary: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(definition.icon, color: scheme.primary),
    );
    if (!showDivider) return tile;
    return Column(children: [tile, const Divider(height: 1, indent: 72)]);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: theme.colorScheme.error,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: Text('settings.retryNotificationPreferences'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
