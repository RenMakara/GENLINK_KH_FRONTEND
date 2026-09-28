import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_floating_error_banner.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';

class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key, this.optionalPrompt = false});

  final bool optionalPrompt;

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

typedef SetPasswordScreen = PasswordSetupScreen;

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _errorMessage;
  int _errorTriggerCount = 0;

  AuthController get _auth => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.optionalPrompt && _hasPassword) {
        Get.offAllNamed<void>(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _hasPassword => _auth.currentUser.value?.hasPassword ?? false;

  void _dismissError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
      _auth.errorMessage.value = null;
    }
  }

  Future<void> _submit() async {
    _dismissError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final changingPassword = _hasPassword;
    final success = changingPassword
        ? await _auth.changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _password.text,
          )
        : await _auth.setPassword(password: _password.text);

    if (!success) {
      final errorCode = _auth.lastErrorCode.value;
      final errorMsg = _auth.errorMessage.value;
      final isAlreadySet = errorCode == 'AUTH_PASSWORD_ALREADY_SET' ||
          (errorMsg != null &&
              errorMsg.toLowerCase().contains('already has a password'));

      if (isAlreadySet) {
        final user = _auth.currentUser.value;
        if (user != null) {
          _auth.currentUser.value = user.copyWith(hasPassword: true);
        }
        await _auth.dismissGooglePasswordPrompt();

        if (!mounted) return;

        if (widget.optionalPrompt) {
          AppSnackbar.show('auth.passwordAlreadySet'.tr);
          Get.offAllNamed<void>(AppRoutes.home);
          return;
        } else {
          setState(() {
            _errorMessage = null;
          });
          AppSnackbar.show('auth.passwordAlreadySet'.tr);
          return;
        }
      }

      if (mounted && _auth.errorMessage.value != null) {
        setState(() {
          _errorMessage = _auth.errorMessage.value;
          _errorTriggerCount++;
        });
      }
      return;
    }

    if (!mounted) return;

    if (changingPassword) {
      AppSnackbar.show('auth.passwordChanged'.tr);
      Get.offAllNamed<void>(AppRoutes.login);
    } else if (widget.optionalPrompt) {
      AppSnackbar.show('auth.passwordSet'.tr);
      Get.offAllNamed<void>(AppRoutes.home);
    } else {
      AppSnackbar.show('auth.passwordSet'.tr);
      Get.back<void>();
    }
  }

  Future<void> _maybeLater() async {
    _dismissError();
    await _auth.dismissGooglePasswordPrompt();
    Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChanging = _hasPassword;

    final title = widget.optionalPrompt
        ? 'auth.setPasswordTitle'.tr
        : (isChanging
              ? 'auth.changePassword'.tr
              : 'auth.setPasswordTitle'.tr);

    final subtitle = widget.optionalPrompt
        ? 'auth.setPasswordDescription'.tr
        : (isChanging
              ? 'settings.changePasswordHint'.tr
              : 'auth.setPasswordDescription'.tr);

    final submitLabel = isChanging
        ? 'auth.changePassword'.tr
        : 'auth.setPassword'.tr;

    return AuthScaffold(
      showBack: !widget.optionalPrompt,
      title: title,
      subtitle: subtitle,
      overlay: AuthFloatingErrorBanner(
        key: const ValueKey('auth-floating-error-banner'),
        message: _errorMessage,
        triggerKey: _errorTriggerCount,
        title: _errorMessage ?? 'common.error'.tr,
        description: 'auth.loginErrorDescription'.tr,
        onDismissed: _dismissError,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => AuthErrorBanner(message: _auth.errorMessage.value)),
              if (isChanging) ...[
                AppInput.password(
                  key: const ValueKey('current-password-input'),
                  label: 'auth.currentPassword'.tr,
                  hint: 'auth.passwordHint'.tr,
                  controller: _currentPassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppInput.password(
                key: const ValueKey('password-input'),
                label: isChanging
                    ? 'auth.newPassword'.tr
                    : 'auth.password'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _password,
                autofocus: !isChanging,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs + 2,
                  left: AppSpacing.xs,
                  bottom: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'auth.passwordTooShort'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              AppInput.password(
                key: const ValueKey('confirm-password-input'),
                label: 'auth.confirmPassword'.tr,
                hint: 'auth.passwordHint'.tr,
                controller: _confirmPassword,
                textInputAction: TextInputAction.done,
                validator: Validators.matches(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Obx(
                () => AppButton(
                  key: const ValueKey('password-submit-button'),
                  label: submitLabel,
                  loading: _auth.isLoading.value,
                  onPressed: _auth.isLoading.value ? null : _submit,
                ),
              ),
              if (widget.optionalPrompt) ...[
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => AppButton.text(
                    key: const ValueKey('maybe-later-button'),
                    label: 'auth.maybeLater'.tr,
                    muted: true,
                    onPressed: _auth.isLoading.value ? null : _maybeLater,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
