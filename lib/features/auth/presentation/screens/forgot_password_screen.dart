import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Step 1 of password reset: request an OTP.
///
/// The backend is deliberately anti-enumeration here — the response is the
/// same whether or not the email exists, so the UI must not imply either.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await _auth.forgotPassword(email: _email.text.trim());
    // Straight to code entry; the new password comes after that.
    if (success) Get.toNamed<void>(AppRoutes.resetOtp);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'auth.forgotTitle'.tr,
      subtitle: 'auth.forgotSubtitle'.tr,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => AuthErrorBanner(message: _auth.errorMessage.value)),
              AppInput.email(
                label: 'auth.email'.tr,
                hint: 'example@gmail.com'.tr,
                controller: _email,
                autofocus: true,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: 'auth.sendCode'.tr,
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
