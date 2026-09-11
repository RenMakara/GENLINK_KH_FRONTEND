import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();

  late final String _email = _auth.pendingEmail.value;
  late final String _otp = Get.arguments as String? ?? '';

  static const _otpErrorCodes = {
    'OTP_INVALID',
    'OTP_EXPIRED',
    'OTP_NOT_FOUND',
    'OTP_MAX_ATTEMPTS',
    'OTP_TOO_MANY_ATTEMPTS',
    'OTP_ALREADY_USED',
  };

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await _auth.resetPassword(
      email: _email,
      otp: _otp,
      newPassword: _password.text,
    );

    if (success) {
      AppSnackbar.show('auth.passwordResetDone'.tr);
      Get.offAllNamed<void>(AppRoutes.login);
      return;
    }

    if (_isOtpError(_auth.lastErrorCode.value)) {
      AppSnackbar.error(_auth.errorMessage.value ?? 'auth.otpLength'.tr);
      Get.back<void>();
    }
  }

  static bool _isOtpError(String? code) =>
      code != null && _otpErrorCodes.contains(code);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'auth.resetTitle'.tr,
      subtitle: 'auth.newPasswordSubtitle'.tr,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => AuthErrorBanner(message: _auth.errorMessage.value)),
              AppInput.password(
                label: 'auth.newPassword'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _password,
                autofocus: true,
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
                  label: 'auth.resetPassword'.tr,
                  loading: _auth.isLoading.value,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
