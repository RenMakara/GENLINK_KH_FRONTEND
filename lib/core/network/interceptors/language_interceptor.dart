import 'package:dio/dio.dart';

import '../../localization/localization_service.dart';

/// Attaches `Accept-Language` to every request.
///
/// The backend resolves system content (financial lessons, motivation tips,
/// badge names, interest names, quiz questions) from this header when the
/// caller is anonymous, and from the stored `preferredLanguage` when signed
/// in. Without the header every response falls back to English, which is the
/// wrong default for a Khmer-first app.
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._localization);

  final LocalizationService _localization;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _localization.headerValue;
    handler.next(options);
  }
}
