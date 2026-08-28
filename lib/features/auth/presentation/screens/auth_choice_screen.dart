import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/buttons/auth_provider_button.dart';
import '../../../../design_system/widgets/buttons/google_sign_in_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Entry point for signed-out users before choosing login or registration.
class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  Future<void> _signInWithGoogle() async {
    final auth = Get.find<AuthController>();
    final success = await auth.signInWithGoogle();
    if (success) Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return AuthScaffold(
      showBack: false,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('auth.haveAccount'.tr, style: theme.textTheme.bodyMedium),
              AppButton.text(
                label: 'auth.login'.tr,
                onPressed: () => Get.toNamed<void>(AppRoutes.login),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 12, color: muted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'auth.encryptedNotice'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: AppLogoMark(size: 52),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text.rich(
          TextSpan(
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: '${'auth.welcomeTo'.tr} '),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AppWordmark(height: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'auth.choiceSubtitle'.tr,
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xl * 1.5),
        Obx(
          () => GoogleSignInButton(
            semanticLabel: 'auth.continueWithGoogle'.tr,
            onPressed: Get.find<AuthController>().isLoading.value
                ? null
                : _signInWithGoogle,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AuthProviderButton(
          key: const ValueKey('continue-with-mail'),
          label: 'auth.continueWithMail'.tr,
          onPressed: () => Get.toNamed<void>(AppRoutes.login),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'auth.orDivider'.tr,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          key: const ValueKey('auth-choice-register'),
          label: 'auth.createAccount'.tr,
          onPressed: () => Get.toNamed<void>(AppRoutes.register),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          height: 1,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ],
    );
  }
}
