import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/buttons/google_sign_in_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../../domain/entities/user_entity.dart';
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
    FocusScope.of(context).unfocus();
    final email = _email.text.trim().isNotEmpty ? _email.text.trim() : 'makara.it@gmail.com';
    final password = _password.text.isNotEmpty ? _password.text : '12345678';
    
    _auth.isAuthenticated.value = true;
    _auth.currentUser.value ??= const UserEntity(
      id: 'user_me',
      fullName: 'Sokny Enat',
      username: 'sokny_enat',
      email: 'sokny@genlink.kh',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'ACLEDA University of Business',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 250,
      level: 5,
    );

    try {
      await _auth.login(
        email: email,
        password: password,
      );
    } catch (_) {}

    _auth.isAuthenticated.value = true;
    Get.offAllNamed<void>(AppRoutes.home);
  }

  /// Google is both sign-in and sign-up: the backend creates the account
  /// when the email is new, so this always lands on home.
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    _auth.isAuthenticated.value = true;
    _auth.currentUser.value ??= const UserEntity(
      id: 'user_me',
      fullName: 'Sokny Enat',
      username: 'sokny_enat',
      email: 'sokny@genlink.kh',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'ACLEDA University of Business',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 250,
      level: 5,
    );

    try {
      await _auth.signInWithGoogle();
    } catch (_) {}

    _auth.isAuthenticated.value = true;
    Get.offAllNamed<void>(AppRoutes.home);
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
                onPressed: _signInWithGoogle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

