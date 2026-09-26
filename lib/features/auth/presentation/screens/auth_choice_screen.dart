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

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  Future<void> _signInWithGoogle() async {
    final auth = Get.find<AuthController>();
    final success = await auth.signInWithGoogle();
    if (success) await auth.continueAfterGoogleLogin();
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
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.35 : 0.18,
                  ),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const AppLogoMark(size: 60),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text.rich(
          TextSpan(
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: '${'auth.welcomeTo'.tr} \n'),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AppWordmark(height: 26),
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
          () {
            final isLoading = Get.find<AuthController>().isLoading.value;
            return GoogleSignInButton(
              semanticLabel: 'auth.continueWithGoogle'.tr,
              loading: isLoading,
              onPressed: isLoading ? null : _signInWithGoogle,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AuthProviderButton(
          key: const ValueKey('continue-with-mail'),
          label: 'auth.continueWithMail'.tr,
          icon: Icon(
            Icons.mail_rounded,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Get.toNamed<void>(AppRoutes.login),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AuthOrDivider(),
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
