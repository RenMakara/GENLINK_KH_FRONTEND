import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/buttons/google_sign_in_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    // workStatus is optional on the backend and is collected later, on the
    // Edit Profile screen, to keep sign-up to five fields.
    final success = await _auth.register(
      fullName: _fullName.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    // Registration returns a message, not a session — the account is
    // PENDING until the emailed OTP is verified.
    if (success) Get.toNamed<void>(AppRoutes.verifyEmail);
  }

  /// Google is both sign-in and sign-up: the backend creates the account
  /// when the email is new, so this always lands on home.
  Future<void> _signInWithGoogle() async {
    final success = await _auth.signInWithGoogle();
    if (success) Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: 'auth.registerTitle'.tr,
      subtitle: 'auth.registerSubtitle'.tr,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wrap, not Row: the prompt + link overflows on narrow screens
          // and in Khmer, where the phrase is longer.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('auth.haveAccount'.tr, style: theme.textTheme.bodyMedium),
              AppButton.text(
                label: 'auth.login'.tr,
                onPressed: () => Get.offNamed<void>(AppRoutes.login),
              ),
            ],
          ),
          Text(
            'auth.legalNotice'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
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
              AppInput(
                label: 'auth.fullName'.tr,
                hint: 'auth.fullNameHint'.tr,
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'auth.username'.tr,
                hint: 'auth.usernameHint'.tr,
                controller: _username,
                textInputAction: TextInputAction.next,
                validator: Validators.username,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.email(
                label: 'auth.email'.tr,
                hint: 'auth.emailHint'.tr,
                controller: _email,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.password(
                label: 'auth.password'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _password,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.password(
                label: 'auth.confirmPassword'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _confirmPassword,
                validator: Validators.matches(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: 'auth.createAccount'.tr,
                  loading: _auth.isLoading.value,
                  onPressed: _submit,
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
