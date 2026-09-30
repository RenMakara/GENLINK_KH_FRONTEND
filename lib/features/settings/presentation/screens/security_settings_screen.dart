import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
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
          'settings.security'.tr,
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                onTap: () => Get.toNamed<void>(AppRoutes.passwordSetup),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.56,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.productivityAccent.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.productivityAccent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPassword
                                  ? 'auth.changePassword'.tr
                                  : 'settings.password'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              hasPassword
                                  ? 'settings.changePasswordHint'.tr
                                  : 'settings.passwordNotSet'.tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.62,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasPassword
                  ? 'settings.changePasswordHint'.tr
                  : 'settings.setPasswordHint'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: hasPassword
                  ? 'auth.changePassword'.tr
                  : 'auth.setPasswordTitle'.tr,
              onPressed: () => Get.toNamed<void>(AppRoutes.passwordSetup),
            ),
          ],
        );
      }),
    );
  }
}
