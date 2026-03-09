import 'package:dio/dio.dart';
import 'package:qulo_v2/core/error/error_manager.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ErrorManager.logError(
      err,
      err.stackTrace,
      'API ${err.requestOptions.method} ${err.requestOptions.path}',
    );
    handler.next(err);
  }
}
