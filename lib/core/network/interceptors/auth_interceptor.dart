import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

/// Interceptor that injects the Bearer token and handles refresh-token retry.
///
/// Behavior:
/// 1. Attaches `Authorization: Bearer <token>` to every request.
/// 2. On 401/403, refreshes once using the stored refresh token.
/// 3. Retries the original request through the *configured* Dio instance.
/// 4. If refresh fails, clears the session and invokes [onSessionExpired]
///    so the app can route to login; the error still propagates.
/// 5. Concurrent failures share a single in-flight refresh via a
///    [Completer] instead of being dropped.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required AuthRepository authRepository,
    this.onSessionExpired,
  })  : _storage = secureStorage,
        _authRepository = authRepository;

  final SecureStorage _storage;
  final AuthRepository _authRepository;

  /// Called once after a refresh failure clears the session.
  final void Function()? onSessionExpired;

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
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final options = err.requestOptions;

    final shouldRefresh = (statusCode == 401 || statusCode == 403) &&
        !_isAuthEndpoint(options.path) &&
        options.extra[_retriedFlag] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();

    if (!refreshed) {
      // Refresh failed — the session is unrecoverable.
      await _storage.clearAll();
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
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
        final session =
            await _authRepository.refreshToken(refreshToken: refreshToken);
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
}
