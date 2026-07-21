import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../controllers/settings_controller.dart';

/// Privacy: profile visibility radios plus the message/follow toggles.
///
/// Backed 1:1 by `user_settings` fields — the design rows with no field
/// (online status, search visibility, data export) are not rendered.
class PrivacySettingsScreen extends GetView<SettingsController> {
  const PrivacySettingsScreen({super.key});

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
        title: Text('settings.privacySettings'.tr),
      ),
      body: Obx(() {
        final settings = controller.settings.value;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'settings.privacyProfile'.tr,
                style: theme.textTheme.titleSmall,
              ),
            ),
            RadioGroup<String>(
              groupValue: settings.privacyProfile,
              onChanged: (value) {
                if (value != null) controller.setPrivacyProfile(value);
              },
              child: Column(
                children: [
                  for (final option in UserSettingsEntity.privacyOptions)
                    RadioListTile<String>(
                      title: Text('privacy.$option'.tr),
                      subtitle: Text(
                        'privacy.${option}Hint'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      value: option,
                    ),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: Text('settings.allowMessages'.tr),
              subtitle: Text('settings.allowMessagesHint'.tr),
              value: settings.allowMessages,
              onChanged: controller.setAllowMessages,
            ),
            SwitchListTile(
              title: Text('settings.allowFollowRequest'.tr),
              subtitle: Text('settings.allowFollowRequestHint'.tr),
              value: settings.allowFollowRequest,
              onChanged: controller.setAllowFollowRequest,
            ),
          ],
        );
      }),
    );
  }
}
