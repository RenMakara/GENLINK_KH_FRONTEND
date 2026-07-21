import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/inputs/otp_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Step 2 of password reset: enter the emailed code.
///
/// The backend has no standalone endpoint for verifying a
/// `FORGOT_PASSWORD` OTP — it is checked inside `POST /auth/reset-password`
/// alongside the new password. (`/auth/verify-otp` is for `REGISTER` and
/// returns a session, so it cannot be reused here.)
///
/// So this screen collects the code and carries it to the next screen; a
/// wrong code surfaces there, which sends the user back here.
class ResetOtpScreen extends StatefulWidget {
  const ResetOtpScreen({super.key});

  @override
  State<ResetOtpScreen> createState() => _ResetOtpScreenState();
}

class _ResetOtpScreenState extends State<ResetOtpScreen> {
  String _otp = '';

  AuthController get _auth => Get.find<AuthController>();

  late final String _email = _auth.pendingEmail.value.isNotEmpty
      ? _auth.pendingEmail.value
      : (Get.arguments as String? ?? '');

  bool get _isComplete => _otp.length == Validators.otpLength;

  void _continue() {
    if (!_isComplete) return;
    FocusScope.of(context).unfocus();
    Get.toNamed<void>(AppRoutes.resetPassword, arguments: _otp);
  }

  Future<void> _resend() async {
    final success = await _auth.forgotPassword(email: _email);
    if (success) AppSnackbar.show('auth.resendCode'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      children: [
        const AuthBadgeIcon(icon: Icons.lock_outline),
        const SizedBox(height: AppSpacing.lg),
        Text('auth.verifyTitle'.tr, style: theme.textTheme.displayMedium),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            children: [
              TextSpan(text: '${'auth.verifySentTo'.tr} '),
              TextSpan(
                text: _email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Obx(
          () => OtpInput(
            length: Validators.otpLength,
            errorText: _auth.errorMessage.value,
            onChanged: (value) => setState(() => _otp = value),
            onCompleted: (_) => _continue(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(() {
          final remaining = _auth.resendCooldown.value;
          if (remaining > 0) {
            return Center(
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  children: [
                    TextSpan(text: '${'auth.resendCodeIn'.tr} '),
                    TextSpan(
                      text: _formatCountdown(remaining),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: AppButton.text(
              label: 'auth.resendCode'.tr,
              onPressed: _resend,
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'common.continue'.tr,
          onPressed: _isComplete ? _continue : null,
        ),
      ],
    );
  }

  static String _formatCountdown(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
