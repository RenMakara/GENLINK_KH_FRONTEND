import 'package:dio/dio.dart';

import '../../localization/localization_service.dart';

class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._localization);

  final LocalizationService _localization;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _localization.headerValue;
    handler.next(options);
  }
}
