import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/log_manager.dart';
import 'package:qulo_v2/core/services/app_info_manager.dart';

/// Her istege uygulama surumunu (`2.0.10+73`) ekler. Sunucu bunu KVKK riza
/// kaydina denetim izi olarak yazar (qulo-server `utils/client-meta.ts`).
///
/// Baslik yalnizca denetim izi, hicbir akisi bloklamamali: surum okunamazsa ya
/// da [timeout] icinde gelmezse istek basliksiz devam eder. Zaman asimi bilincli —
/// istek yoluna bir platform kanali bagimliligi eklendi; kanal yanit vermezse tum
/// API cagrilari donardi.
class AppVersionInterceptor extends Interceptor {
  AppVersionInterceptor({
    Future<String> Function()? version,
    Duration timeout = _defaultTimeout,
  })  : _version = version ?? (() => AppInfoManager.instance.headerVersion),
        _timeout = timeout;

  static const _headerKey = 'x-app-version';
  static const _defaultTimeout = Duration(seconds: 2);

  final Future<String> Function() _version;
  final Duration _timeout;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      options.headers[_headerKey] = await _version().timeout(_timeout);
    } catch (e) {
      LogManager.instance.logInfo('APP_VERSION', 'x-app-version eklenemedi: $e');
    }
    handler.next(options);
  }
}
