import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/log_manager.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LogManager.instance.logRequest(options.method, options.path);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LogManager.instance.logResponse(
      response.requestOptions.method,
      response.requestOptions.path,
      response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LogManager.instance.logError(
      err.requestOptions.method,
      err.requestOptions.path,
      err.response?.statusCode,
      err.message,
    );
    handler.next(err);
  }
}
