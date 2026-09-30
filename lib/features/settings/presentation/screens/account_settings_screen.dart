import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Get.find<AuthController>().refreshCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Text(
          'settings.accountSettings'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        final user = auth.currentUser.value;
        if (user == null) return const SizedBox.shrink();

        final hasPassword = user.canChangePassword;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text('auth.email'.tr),
              subtitle: Text(user.email),
              trailing: user.emailVerified
                  ? Icon(
                      Icons.verified,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text('auth.username'.tr),
              subtitle: Text('@${user.username}'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(
                hasPassword
                    ? 'auth.changePassword'.tr
                    : 'settings.password'.tr,
              ),
              subtitle: Text(
                hasPassword
                    ? 'settings.changePasswordHint'.tr
                    : 'settings.passwordNotSet'.tr,
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Get.toNamed<void>(AppRoutes.settingsSecurity),
            ),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text('auth.phoneNumber'.tr),
                subtitle: Text(user.phoneNumber!),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('profile.edit'.tr),
              subtitle: Text('settings.editProfileHint'.tr),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Get.toNamed<void>(AppRoutes.editProfile),
            ),
          ],
        );
      }),
    );
  }
}
