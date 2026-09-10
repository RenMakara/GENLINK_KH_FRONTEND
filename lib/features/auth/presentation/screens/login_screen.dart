import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/buttons/google_sign_in_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await _auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (success) Get.offAllNamed<void>(AppRoutes.home);
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final success = await _auth.signInWithGoogle();
    if (success) Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'auth.noAccount'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppButton.text(
            label: 'auth.register'.tr,
            onPressed: () => Get.toNamed<void>(AppRoutes.register),
          ),
        ],
      ),
      children: [
        const AuthBrandLockup(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'auth.loginTitle'.tr,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'auth.loginSubtitle'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => AuthErrorBanner(message: _auth.errorMessage.value)),
              AppInput.email(
                label: 'auth.email'.tr,
                hint: 'auth.emailHint'.tr,
                controller: _email,
                autofocus: false,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.password(
                label: 'auth.password'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _password,
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.text(
                  label: 'auth.forgotPassword'.tr,
                  onPressed: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(
                () => AppButton(
                  label: 'auth.login'.tr,
                  loading: _auth.isLoading.value,
                  onPressed: _auth.isLoading.value ? null : _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AuthOrDivider(),
              const SizedBox(height: AppSpacing.lg),
              GoogleSignInButton(
                semanticLabel: 'auth.continueWithGoogle'.tr,
                onPressed: _signInWithGoogle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
