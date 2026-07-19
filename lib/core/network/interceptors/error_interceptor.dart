import 'package:dio/dio.dart';
import 'package:qulo_v2/core/error/error_manager.dart';

class ErrorInterceptor extends Interceptor {
  // Fire-and-forget background endpoints. Connection glitches here are expected
  // (60s heartbeat retries on its own) and would otherwise spam Crashlytics.
  static const _silentPaths = <String>{
    '/users/me/presence',
    '/users/me/presence/offline',
  };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_silentPaths.contains(err.requestOptions.path)) {
      ErrorManager.logError(
        err,
        err.stackTrace,
        'API ${err.requestOptions.method} ${err.requestOptions.path}',
      );
    }
    handler.next(err);
  }
}
