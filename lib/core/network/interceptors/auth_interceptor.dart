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
      if (token != null && token.isNotEmpty) {
        await _storage.clearAll();
      }
      options.extra[_missingSessionFlag] = true;
      onSessionExpired?.call();
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
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final options = err.requestOptions;

<<<<<<< HEAD
=======
    final token = await _storage.readAccessToken();
    final isDemoToken = token != null && _isDemoToken(token);

    if (isDemoToken) {
      // Demo session: backend API failures must not wipe demo state or bounce to login.
      handler.next(err);
      return;
    }

    // A 403 means the authenticated user lacks permission; refreshing does
    // not change authorization and must never turn a forbidden operation
    // into a logout. Only a 401 is a token-authentication failure.
>>>>>>> 8b06999452f85e3446ffa6b8116d9166bca9b671
    final shouldRefresh =
        statusCode == 401 &&
        !_isAuthEndpoint(options.path) &&
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
        path.contains('/auth/reset-password') ||
        path.contains('/auth/verify-email') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/resend-otp') ||
        path.contains('/auth/resend-verification-otp');
  }

  bool _isDemoToken(String token) =>
      token == 'demo_access_token' ||
      token == 'mock_access_token_123' ||
      token == 'mock_google_token';
}
