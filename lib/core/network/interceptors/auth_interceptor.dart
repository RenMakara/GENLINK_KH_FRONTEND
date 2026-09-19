import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

/// Interceptor that injects the Bearer token and handles refresh-token retry.
///
/// Behavior:
/// 1. Attaches `Authorization: Bearer <token>` to every protected request.
/// 2. On 401, refreshes once using the stored refresh token.
/// 3. Retries the original request through the *configured* Dio instance.
/// 4. If refresh fails, clears the session and invokes [onSessionExpired]
///    so the app can route to login; the error still propagates.
/// 5. Concurrent failures share a single in-flight refresh via a
///    [Completer] instead of being dropped.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required this._authRepository,
    this.onSessionExpired,
  }) : _storage = secureStorage;

  final SecureStorage _storage;
  final AuthRepository _authRepository;

  /// Called once when refresh fails so app state and stored credentials can
  /// be cleared before the failed request continues through the Dio chain.
  final FutureOr<void> Function()? onSessionExpired;

  /// The configured client, used to replay a request after refresh.
  ///
  /// Assigned after construction because the Dio instance and this
  /// interceptor are mutually dependent. A bare `Dio()` cannot be used
  /// here: it has no `baseUrl`, so replaying a relative path would fail
  /// to resolve a host.
  Dio? _client;
  // ignore: avoid_setters_without_getters
  set client(Dio dio) => _client = dio;

  /// Marks a request that has already been replayed, so a second 401 on
  /// the retry cannot start a refresh loop.
  static const _retriedFlag = 'genlink_auth_retried';
  static const _missingSessionFlag = 'genlink_auth_missing_session';
  static const _sessionTokenFlag = 'genlink_auth_session_token';

  /// Shared in-flight refresh. Concurrent 401s await this instead of
  /// each firing their own refresh call.
  Completer<bool>? _refreshCompleter;

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
    final hasRealToken =
        token != null && token.isNotEmpty && !_isDemoToken(token);

    if (kDebugMode && options.path.contains('/entertainment/quizzes')) {
      debugPrint(
        '[Quiz API]\n'
        'Auth attached: $hasRealToken\n'
        'Token source: ${hasRealToken ? 'authenticated session' : 'none'}\n'
        'Demo token: ${token != null && _isDemoToken(token)}',
      );
    }

    if (!hasRealToken) {
      final isPushRegistration = _isPushRegistrationEndpoint(options.path);
      final callback = onSessionExpired;
      // Let the session callback own cleanup when it exists. Clearing here
      // independently can race with a login that is persisting a new token.
      if (!isPushRegistration &&
          callback == null &&
          token != null &&
          token.isNotEmpty) {
        await _storage.clearAll();
      }
      options.extra[_missingSessionFlag] = true;
      if (!isPushRegistration && callback != null) {
        await callback();
      }
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
            data: const {
              'success': false,
              'message': 'Authentication required.',
              'errorCode': 'AUTH_REQUIRED',
            },
          ),
          type: DioExceptionType.badResponse,
          error: const AppError(
            message: 'Authentication required.',
            errorCode: 'AUTH_REQUIRED',
            statusCode: 401,
          ),
        ),
      );
      return;
    }

    options.headers['Authorization'] = 'Bearer $token';
    // Keep the token used by this request so a late 401 from an older
    // session cannot expire the credentials that belong to a newer login.
    options.extra[_sessionTokenFlag] = token;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final options = err.requestOptions;
    final capturedToken = options.extra[_sessionTokenFlag] as String?;
    final isStaleSessionRequest = statusCode == 401 &&
        capturedToken != null &&
        capturedToken != await _storage.readAccessToken();

    final shouldRefresh =
        statusCode == 401 &&
        !_isAuthEndpoint(options.path) &&
        !_isLogoutEndpoint(options.path) &&
        !_isPushRegistrationEndpoint(options.path) &&
        !isStaleSessionRequest &&
        options.extra[_retriedFlag] != true &&
        options.extra[_missingSessionFlag] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();

    if (!refreshed) {
      // Refresh failed — the session is unrecoverable.
      final callback = onSessionExpired;
      if (callback != null) {
        try {
          await callback();
        } catch (_) {
          // A routing/state callback must not prevent local token cleanup or
          // leave Dio's interceptor queue unresolved.
          await _storage.clearAll();
        }
      } else {
        await _storage.clearAll();
      }
      handler.next(err);
      return;
    }

    final refreshedToken = await _storage.readAccessToken();
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $refreshedToken';
    }
    options.extra[_retriedFlag] = true;

    final client = _client;
    if (client == null) {
      // Never wired up — fail loudly rather than silently dropping the retry.
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await client.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Refresh the access token, coalescing concurrent callers.
  ///
  /// Returns `true` if a new token pair was obtained.
  Future<bool> _refresh() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await _storage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          completer.complete(false);
          return;
        }
        final session = await _authRepository.refreshToken(
          refreshToken: refreshToken,
        );
        await _storage.saveTokenPair(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/google') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/verify-reset-otp') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/verify-email') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/resend-otp') ||
        path.contains('/auth/resend-verification-otp');
  }

  // Logout is authenticated, so it must still receive the bearer token, but a
  // 401 from it must never start a refresh cycle: logout is already best effort
  // and the local session cleanup is handled by AuthController.
  bool _isLogoutEndpoint(String path) => path.contains('/auth/logout');

  // Device registration is supplemental. Its 401 must not invalidate a user
  // session, especially when a request from the previous session completes
  // during logout/login.
  bool _isPushRegistrationEndpoint(String path) =>
      path.contains('/profile/settings/notifications/devices');

  bool _isDemoToken(String token) =>
      token == 'demo_access_token' ||
      token == 'mock_access_token_123' ||
      token == 'mock_google_token';
}
