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

/// Email verification via the 6-digit OTP.
///
/// The backend returns a full token pair from `/auth/verify-email`, so a
/// successful verification signs the user in — there is no second login step.
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  String _otp = '';

  AuthController get _auth => Get.find<AuthController>();

  /// Email comes from the register/forgot step; `Get.arguments` is a
  /// fallback for deep links into this screen.
  late final String _email = _auth.pendingEmail.value.isNotEmpty
      ? _auth.pendingEmail.value
      : (Get.arguments as String? ?? '');

  bool get _isComplete => _otp.length == Validators.otpLength;

  Future<void> _submit() async {
    if (!_isComplete) return;
    FocusScope.of(context).unfocus();

    final success = await _auth.verifyEmail(email: _email, otp: _otp);
    // Verification returns a session, so the account is live from here.
    // New accounts go through profile setup first; it is skippable.
    if (success) Get.offAllNamed<void>(AppRoutes.profileSetup);
  }

  Future<void> _resend() async {
    final success = await _auth.resendVerificationOtp(email: _email);
    if (success) AppSnackbar.show('auth.resendCode'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // No `title`: this screen renders its own header so the email address
    // can be emphasised inside the subtitle line.
    return AuthScaffold(
      children: [
        const AuthBadgeIcon(icon: Icons.lock_outline),
        const SizedBox(height: AppSpacing.lg),
        Text('auth.verifyTitle'.tr, style: theme.textTheme.displayLarge),
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
            // Submitting straight from the last digit saves a tap.
            onCompleted: (_) => _submit(),
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
        Obx(
          () => AppButton(
            label: 'auth.verifyEmail'.tr,
            loading: _auth.isLoading.value,
            onPressed: _isComplete ? _submit : null,
          ),
        ),
      ],
    );
  }

  /// `m:ss`, matching the design's `0:47`.
  static String _formatCountdown(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
