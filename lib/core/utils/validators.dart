import 'package:get/get.dart';

/// Form field validators.
///
/// These mirror the backend's Bean Validation constraints so the user gets
/// immediate feedback, but they are a convenience, not the authority — the
/// server still validates and its `VALIDATION_ERROR` message wins.
abstract final class Validators {
  /// Deliberately permissive: `something@something.tld`. Anything stricter
  /// rejects addresses that are actually valid.
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

  /// Confirm-password check. [original] is the first password field.
  static String? Function(String?) matches(String Function() original) {
    return (String? value) {
      final missing = required(value);
      if (missing != null) return missing;
      if (value != original()) return 'auth.passwordsDoNotMatch'.tr;
      return null;
    };
  }

  /// Optional field: only validated when the user typed something.
  static String? Function(String?) optional(String? Function(String?) inner) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return inner(value);
    };
  }
}
