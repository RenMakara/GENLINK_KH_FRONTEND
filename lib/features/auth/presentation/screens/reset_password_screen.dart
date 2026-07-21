import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Step 2 of password reset: OTP + new password.
///
/// Unlike verification, reset returns only a message — the user still has
/// to log in with the new password afterwards.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();

  late final String _email = _auth.pendingEmail.value.isNotEmpty
      ? _auth.pendingEmail.value
      : (Get.arguments as String? ?? '');

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await _auth.resetPassword(
      email: _email,
      otp: _otp.text.trim(),
      newPassword: _password.text,
    );
    if (success) {
      AppSnackbar.show('auth.resetPassword'.tr);
      Get.offAllNamed<void>(AppRoutes.login);
    }
  }

  Future<void> _resend() async {
    final success = await _auth.forgotPassword(email: _email);
    if (success) AppSnackbar.show('auth.resendCode'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'auth.resetTitle'.tr,
      subtitle: 'auth.resetSubtitle'.tr,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => AuthErrorBanner(message: _auth.errorMessage.value)),
              AppInput(
                label: 'auth.otpCode'.tr,
                controller: _otp,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: Validators.otpLength,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.otp,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.password(
                label: 'auth.newPassword'.tr,
                controller: _password,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput.password(
                label: 'auth.confirmPassword'.tr,
                controller: _confirmPassword,
                validator: Validators.matches(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: 'auth.resetPassword'.tr,
                  loading: _auth.isLoading.value,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(() {
                final remaining = _auth.resendCooldown.value;
                return Center(
                  child: AppButton.text(
                    label: remaining > 0
                        ? 'auth.resendIn'.trParams({'seconds': '$remaining'})
                        : 'auth.resendCode'.tr,
                    onPressed: remaining > 0 ? null : _resend,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
