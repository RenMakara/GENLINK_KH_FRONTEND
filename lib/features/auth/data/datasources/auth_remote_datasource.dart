import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_response_model.dart';
import '../models/auth_response_model.dart';
import '../models/user_response_model.dart';

/// Remote datasource for auth endpoints.
///
/// Handles raw HTTP calls and parses the ApiResponse envelope. Throws
/// [AppError] on any non-success response.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  // ── Login ─────────────────────────────────────────────────────────────

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _parseAuthResponse(response);
  }

  // ── Register ──────────────────────────────────────────────────────────

  Future<String> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'universityName': universityName,
        'workStatus': workStatus,
        'preferredLanguage': preferredLanguage,
      },
    );
    return _parseMessage(response);
  }

  // ── Google Login ──────────────────────────────────────────────────────

  Future<AuthResponseModel> googleLogin({required String idToken}) async {
    final response = await _dio.post(
      ApiEndpoints.googleLogin,
      data: {'idToken': idToken},
    );
    return _parseAuthResponse(response);
  }

  // ── Verify Email / OTP ───────────────────────────────────────────────

  Future<AuthResponseModel> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'otp': otp},
    );
    return _parseAuthResponse(response);
  }

  Future<AuthResponseModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return _parseAuthResponse(response);
  }

  // ── Resend OTP ───────────────────────────────────────────────────────

  Future<String> resendOtp({required String email}) async {
    final response = await _dio.post(
      ApiEndpoints.resendOtp,
      data: {'email': email},
    );
    return _parseMessage(response);
  }

  Future<String> resendVerificationOtp({required String email}) async {
    final response = await _dio.post(
      ApiEndpoints.resendVerificationOtp,
      data: {'email': email},
    );
    return _parseMessage(response);
  }

  // ── Password Reset ───────────────────────────────────────────────────

  Future<String> forgotPassword({required String email}) async {
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    return _parseMessage(response);
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return _parseMessage(response);
  }

  // ── Refresh Token ────────────────────────────────────────────────────

  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    final response = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return _parseAuthResponse(response);
  }

  // ── Get Current User ─────────────────────────────────────────────────

  Future<UserResponseModel> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.me);
    final body = response.data as Map<String, dynamic>;
    final api = ApiResponseModel<dynamic>.fromJson(body, null);
    if (!api.success || api.data == null) {
      throw AppError(
        message: api.message ?? 'Failed to get user profile',
        errorCode: api.errorCode ?? 'API_ERROR',
        statusCode: response.statusCode,
      );
    }
    return UserResponseModel.fromJson(api.data as Map<String, dynamic>);
  }

  // ── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  AuthResponseModel _parseAuthResponse(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>;
    final api = ApiResponseModel<Map<String, dynamic>>.fromJson(
      body,
      (data) => data as Map<String, dynamic>,
    );
    if (!api.success || api.data == null) {
      throw AppError(
        message: api.message ?? 'Request failed',
        errorCode: api.errorCode ?? 'API_ERROR',
        statusCode: response.statusCode,
      );
    }
    return AuthResponseModel.fromJson(api.data!);
  }

  String _parseMessage(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>;
    final api = ApiResponseModel<dynamic>.fromJson(body, null);
    if (!api.success) {
      throw AppError(
        message: api.message ?? 'Request failed',
        errorCode: api.errorCode ?? 'API_ERROR',
        statusCode: response.statusCode,
      );
    }
    return api.message ?? '';
  }
}
