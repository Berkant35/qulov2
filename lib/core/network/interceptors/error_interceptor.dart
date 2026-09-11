import 'package:dio/dio.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/network/interceptors/auth_interceptor.dart';

typedef ErrorReporter = void Function(
  Object error, [
  StackTrace? stack,
  String? reason,
]);

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({ErrorReporter report = ErrorManager.logError})
      : _report = report;

  final ErrorReporter _report;

  // Fire-and-forget background endpoints. Connection glitches here are expected
  // (60s heartbeat retries on its own) and would otherwise spam Crashlytics.
  static const _silentPaths = <String>{
    '/users/me/presence',
    '/users/me/presence/offline',
  };

  /// AuthInterceptor yenilemeden sonra ayni `RequestOptions`'i `_dio.fetch`
  /// ile tum zincirden yeniden gecirir: tekrar da hata alirsa ayni hata ic ve
  /// dis zincirde iki kez buraya gelir.
  static const _reportedKey = 'error_reported';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (_shouldReport(err)) {
      options.extra[_reportedKey] = true;
      _report(err, err.stackTrace, 'API ${options.method} ${options.path}');
    }
    handler.next(err);
  }

  bool _shouldReport(DioException err) {
    final options = err.requestOptions;
    if (options.extra[_reportedKey] == true) return false;
    if (_silentPaths.contains(options.path)) return false;
    if (err.type == DioExceptionType.cancel) return false;
    // 401 genelde hata degil oturum durumu: yanlis sifre ya da suresi dolan
    // token; AuthInterceptor yeniler, olmazsa cikis yaptirir. Ama YENI token'la
    // tekrar gonderilen istek de 401 alirsa sunucu taze token'i reddediyor —
    // toplu cikis olursa gorulmesi gereken gercek anormallik.
    if (err.response?.statusCode == 401) {
      return options.extra[AuthInterceptor.retriedKey] == true;
    }
    return true;
  }
}
