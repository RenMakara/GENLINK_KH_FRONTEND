import 'package:dio/dio.dart';

import '../errors/app_error.dart';

/// High-level wrapper around [Dio] that unwraps the backend `ApiResponse`
/// envelope so datasources deal in payloads, not envelopes.
///
/// Every backend endpoint returns:
/// ```json
/// { "success": true, "message": "...", "data": {...},
///   "errorCode": null, "timestamp": "..." }
/// ```
///
/// Do not put endpoint paths here — those belong in `ApiEndpoints`.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  // ── Verbs ─────────────────────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    final response =
        await guardDio(() => _dio.get<dynamic>(path, queryParameters: query));
    return _unwrap(response, parse);
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    final response = await guardDio(
        () => _dio.post<dynamic>(path, data: body, queryParameters: query));
    return _unwrap(response, parse);
  }

  Future<T> put<T>(
    String path, {
    Object? body,
    required T Function(dynamic data) parse,
  }) async {
    final response = await guardDio(() => _dio.put<dynamic>(path, data: body));
    return _unwrap(response, parse);
  }

  Future<void> delete(String path, {Map<String, dynamic>? query}) async {
    final response = await guardDio(
        () => _dio.delete<dynamic>(path, queryParameters: query));
    _envelope(response);
  }

  // ── Parsers ───────────────────────────────────────────────────────────

  /// Parse `data` as a JSON object.
  static Map<String, dynamic> asMap(dynamic data) =>
      (data as Map?)?.cast<String, dynamic>() ?? const {};

  /// Parse `data` as a list of JSON objects mapped through [item].
  static List<T> asList<T>(dynamic data, T Function(Map<String, dynamic>) item) {
    final list = data as List? ?? const [];
    return list
        .map((e) => item((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // ── Internals ─────────────────────────────────────────────────────────

  T _unwrap<T>(Response<dynamic> response, T Function(dynamic) parse) =>
      parse(_envelope(response)['data']);

  /// Validate the envelope and return it, throwing [AppError] on failure.
  ///
  /// A non-2xx status is already converted by `ErrorInterceptor`; this
  /// catches the rarer case of a 200 carrying `success: false`.
  Map<String, dynamic> _envelope(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map) {
      throw AppError(
        message: 'Unexpected response format',
        errorCode: 'API_ERROR',
        statusCode: response.statusCode,
      );
    }
    final envelope = body.cast<String, dynamic>();
    if (envelope['success'] != true) {
      throw AppError(
        message: envelope['message'] as String? ?? 'Request failed',
        errorCode: envelope['errorCode'] as String? ?? 'API_ERROR',
        statusCode: response.statusCode,
      );
    }
    return envelope;
  }
}
