/// Centralized error model matching backend ApiResponse error format.
///
/// Every backend error response is wrapped in:
/// `{ success, message, data, errorCode, timestamp }`
///
/// [AppError] represents the failure side of that contract.
class AppError implements Exception {
  const AppError({
    required this.message,
    required this.errorCode,
    this.statusCode,
  });

  final String message;
  final String errorCode;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => errorCode == 'RATE_LIMITED' || statusCode == 429;
  bool get isTokenExpired => errorCode == 'TOKEN_EXPIRED';
  bool get isTokenRevoked => errorCode == 'TOKEN_REVOKED';
  bool get isTokenReuseDetected => errorCode == 'TOKEN_REUSE_DETECTED';
  bool get isInvalidCredentials => errorCode == 'AUTH_INVALID_CREDENTIALS';
  bool get isAccountBanned => errorCode == 'AUTH_ACCOUNT_BANNED';
  bool get isEmailNotVerified => errorCode == 'AUTH_EMAIL_NOT_VERIFIED';
  bool get isWeakPassword => errorCode == 'AUTH_WEAK_PASSWORD';
  bool get isOtpInvalid => errorCode == 'OTP_INVALID';
  bool get isOtpExpired => errorCode == 'OTP_EXPIRED';
  bool get isValidation => errorCode == 'VALIDATION_ERROR';

  /// Whether this error should trigger a logout / session clear.
  bool get shouldLogout =>
      isTokenExpired ||
      isTokenRevoked ||
      isTokenReuseDetected ||
      (isUnauthorized && errorCode != 'AUTH_INVALID_CREDENTIALS');

  @override
  String toString() => 'AppError($errorCode): $message';

  /// Parse an [AppError] from a backend JSON response body.
  factory AppError.fromResponse(Map<String, dynamic> json, int statusCode) {
    return AppError(
      message: json['message'] as String? ?? 'Unknown error',
      errorCode: json['errorCode'] as String? ?? 'API_ERROR',
      statusCode: statusCode,
    );
  }
}
