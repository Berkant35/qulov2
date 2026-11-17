import 'package:dio/dio.dart';

/// İstek bazlı yanıt bekleme sınırı. Genel sınır (`NetworkManager`, 15 sn)
/// uzun süren tekil uçlara yetmez (ör. soru medyası yükleme: depolama +
/// normalize + senkron moderasyon). Retrofit metodu
/// `@Extra({RequestTimeoutInterceptor.receiveTimeoutKey: <Duration>})` ile
/// işaretlenir; işaretsiz istekler olduğu gibi geçer.
class RequestTimeoutInterceptor extends Interceptor {
  static const receiveTimeoutKey = 'receive_timeout';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timeout = options.extra[receiveTimeoutKey];
    if (timeout is Duration) options.receiveTimeout = timeout;
    handler.next(options);
  }
}
