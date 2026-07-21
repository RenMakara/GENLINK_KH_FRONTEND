import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/buttons/google_sign_in_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      title: 'auth.loginTitle'.tr,
      subtitle: 'auth.loginSubtitle'.tr,
      // Wrap, not Row: the prompt + link overflows on narrow screens and
      // in Khmer, where the phrase is longer.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('auth.noAccount'.tr,
              style: Theme.of(context).textTheme.bodyMedium),
          AppButton.text(
            label: 'auth.register'.tr,
            onPressed: () => Get.toNamed<void>(AppRoutes.register),
          ),
        ],
      ),
      children: [
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
                autofocus: true,
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
                  onPressed: () =>
                      Get.toNamed<void>(AppRoutes.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(
                () => AppButton(
                  label: 'auth.login'.tr,
                  loading: _auth.isLoading.value,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AuthOrDivider(),
              const SizedBox(height: AppSpacing.lg),
              GoogleSignInButton(
                semanticLabel: 'auth.continueWithGoogle'.tr,
                // Google Sign-In needs the `google_sign_in` package to
                // obtain a device idToken; the backend contract
                // (POST /auth/google) is already wired in AuthController.
                onPressed: () =>
                    AppSnackbar.error('auth.googleUnavailable'.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

