import 'package:get/get.dart';

abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const minPasswordLength = 8;
  static const minUsernameLength = 3;
  static const otpLength = 6;

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'common.required'.tr;
    return null;
  }

  static String? email(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    if (!_emailPattern.hasMatch(value!.trim())) return 'auth.invalidEmail'.tr;
    return null;
  }

  static String? password(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    if (value!.length < minPasswordLength) return 'auth.passwordTooShort'.tr;
    return null;
  }

  static String? username(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    if (value!.trim().length < minUsernameLength) {
      return 'auth.usernameTooShort'.tr;
    }
    return null;
  }

  static String? otp(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    if (value!.trim().length != otpLength) return 'auth.otpLength'.tr;
    return null;
  }

  static String? Function(String?) matches(String Function() original) {
    return (String? value) {
      final missing = required(value);
      if (missing != null) return missing;
      if (value != original()) return 'auth.passwordsDoNotMatch'.tr;
      return null;
    };
  }

  static String? Function(String?) optional(String? Function(String?) inner) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return inner(value);
    };
  }
}
