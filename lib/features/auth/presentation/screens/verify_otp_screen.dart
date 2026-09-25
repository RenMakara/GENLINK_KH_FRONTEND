import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/otp_keypad.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  String _otp = '';
  Worker? _errorWorker;
  Timer? _errorDismissTimer;

  AuthController get _auth => Get.find<AuthController>();

  late final String _email = _auth.pendingEmail.value.isNotEmpty
      ? _auth.pendingEmail.value
      : (Get.arguments as String? ?? '');

  bool get _isComplete => _otp.length == Validators.otpLength;

  @override
  void initState() {
    super.initState();
    _errorWorker = ever(_auth.errorMessage, (String? msg) {
      _errorDismissTimer?.cancel();
      if (msg != null && msg.isNotEmpty && mounted) {
        _errorDismissTimer = Timer(const Duration(seconds: 4), () {
          if (mounted && _auth.errorMessage.value != null) {
            _auth.errorMessage.value = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _errorWorker?.dispose();
    _errorDismissTimer?.cancel();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_otp.length >= Validators.otpLength) return;
    _clearError();
    setState(() => _otp += digit);
  }

  void _deleteDigit() {
    if (_otp.isEmpty) return;
    _clearError();
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  void _clearError() {
    _errorDismissTimer?.cancel();
    if (_auth.errorMessage.value != null) {
      _auth.errorMessage.value = null;
    }
  }

  Future<void> _submit() async {
    if (!_isComplete) return;
    final success = await _auth.verifyEmail(email: _email, otp: _otp);
    if (success) Get.offAllNamed<void>(AppRoutes.profileSetup);
  }

  Future<void> _resend() async {
    final success = await _auth.resendVerificationOtp(email: _email);
    if (success) AppSnackbar.show('auth.resendCode'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      backBottomSpacing: AppSpacing.md,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AuthBrandLockup(markSize: 42, wordmarkHeight: 18),
            Text(
              'Connect.\nLearn.\nGrow.\nTogether.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                height: 1.15,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'auth.verifyTitle'.tr,
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
          ) ??
              const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontSize: 15,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: '${'auth.verifySentTo'.tr}${_email.isNotEmpty ? '\n' : ' '}',
              ),
              if (_email.isNotEmpty)
                TextSpan(
                  text: _email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => OtpCodeDisplay(
            code: _otp,
            length: Validators.otpLength,
            errorText: _auth.errorMessage.value,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          final remaining = _auth.resendCooldown.value;
          if (remaining > 0) {
            return Center(
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: '${'auth.resendCodeIn'.tr} '),
                    TextSpan(
                      text: _formatCountdown(remaining),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: TextButton(
              onPressed: _resend,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: Text(
                'auth.resendCode'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => AppButton(
            key: const ValueKey('verify-email-button'),
            label: 'common.continue'.tr,
            loading: _auth.isLoading.value,
            onPressed: _isComplete ? _submit : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OtpNumericKeypad(
          onDigitPressed: _appendDigit,
          onBackspacePressed: _deleteDigit,
          onSymbolPressed: null,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'auth.otpHelp'.tr,
          key: const ValueKey('otp-help-text'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  static String _formatCountdown(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
