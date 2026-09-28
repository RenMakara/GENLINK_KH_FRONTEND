import 'package:dio/dio.dart';

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
  bool get isProfilePrivate =>
      errorCode == 'PROFILE_PRIVATE' ||
      message.toLowerCase().contains('profile is private') ||
      (errorCode == 'API_ERROR' && message.toLowerCase().contains('private'));
  bool get isProfileFriendsOnly =>
      errorCode == 'PROFILE_FRIENDS_ONLY' ||
      message.toLowerCase().contains('friends only');

  bool get shouldLogout =>
      isTokenExpired ||
      isTokenRevoked ||
      isTokenReuseDetected ||
      (isUnauthorized && errorCode != 'AUTH_INVALID_CREDENTIALS');

  @override
  String toString() => 'AppError($errorCode): $message';

  factory AppError.fromResponse(Map<String, dynamic> json, int statusCode) {
    return AppError(
      message: json['message'] as String? ?? 'Unknown error',
      errorCode: json['errorCode'] as String? ?? 'API_ERROR',
      statusCode: statusCode,
    );
  }

  factory AppError.fromDio(DioException exception) {
    final inner = exception.error;
    if (inner is AppError) return inner;

    return AppError(
      message: exception.message ?? 'Unable to reach the server.',
      errorCode: 'NETWORK_ERROR',
      statusCode: exception.response?.statusCode,
    );
  }
}

Future<T> guardDio<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw AppError.fromDio(e);
  }
}
