import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  static const _mutationMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
  static const _headerKey = 'Idempotency-Key';
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutationMethods.contains(options.method.toUpperCase())) {
      options.headers[_headerKey] ??= _uuid.v4();
    }
    handler.next(options);
  }
}
