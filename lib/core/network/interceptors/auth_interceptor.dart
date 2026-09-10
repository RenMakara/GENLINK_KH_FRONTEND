import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required this._authRepository,
    this.onSessionExpired,
  }) : _storage = secureStorage;

  final SecureStorage _storage;
  final AuthRepository _authRepository;

  final FutureOr<void> Function()? onSessionExpired;

  Dio? _client;
  // ignore: avoid_setters_without_getters
  set client(Dio dio) => _client = dio;

  static const _retriedFlag = 'genlink_auth_retried';
  static const _missingSessionFlag = 'genlink_auth_missing_session';

  Completer<bool>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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

    final token = await _storage.readAccessToken();
    final isDemoToken = token != null && _isDemoToken(token);

    if (isDemoToken) {
      handler.next(err);
      return;
    }

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
      final callback = onSessionExpired;
      if (callback != null) {
        try {
          await callback();
        } catch (_) {
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
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await client.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

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
