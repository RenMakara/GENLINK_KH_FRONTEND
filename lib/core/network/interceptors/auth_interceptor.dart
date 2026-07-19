import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

/// Interceptor that injects the Bearer token and handles refresh-token retry.
///
/// Behavior:
/// 1. Attaches `Authorization: Bearer <token>` to every request.
/// 2. On 401/403, attempts a single refresh using the stored refresh token.
/// 3. Retries the original request with the new access token.
/// 4. If refresh fails, does NOT retry — the error propagates so the app
///    can redirect to login.
/// 5. Prevents duplicate refresh calls when multiple requests fail
///    simultaneously using a boolean guard.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required AuthRepository authRepository,
  })  : _storage = secureStorage,
        _authRepository = authRepository;

  final SecureStorage _storage;
  final AuthRepository _authRepository;

  /// Guard to prevent concurrent refresh attempts.
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token injection for auth endpoints (login, register, refresh).
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Only attempt refresh on 401/403 for non-auth endpoints.
    if ((statusCode == 401 || statusCode == 403) &&
        !_isAuthEndpoint(err.requestOptions.path) &&
        !_isRefreshing) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        // Retry the original request with the new token.
        final token = await _storage.readAccessToken();
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
        }
        try {
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
      // Refresh failed — clear local session and propagate the error.
      await _storage.clearAll();
    }

    handler.next(err);
  }

  /// Attempt to refresh the access token.
  ///
  /// Returns `true` if a new token pair was obtained successfully.
  Future<bool> _attemptRefresh() async {
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final session = await _authRepository.refreshToken(
        refreshToken: refreshToken,
      );
      await _storage.saveTokenPair(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/google') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/verify-email') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/resend-otp') ||
        path.contains('/auth/resend-verification-otp');
  }
}
