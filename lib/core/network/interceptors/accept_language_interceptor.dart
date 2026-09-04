import 'package:dio/dio.dart';
import 'package:qulo_v2/core/services/format_manager.dart';

/// Her istege Accept-Language ekler; sunucu (sosyal giris, app-config) dili buradan cozer.
class AcceptLanguageInterceptor extends Interceptor {
  static const _headerKey = 'Accept-Language';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[_headerKey] = FormatManager.instance.acceptLanguageTag;
    handler.next(options);
  }
}
