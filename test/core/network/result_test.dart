import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';

/// `Result` + `DioException.toAppFailure()` — 21 repository'nin tamamının
/// hata yolu buradan geçiyor, ama testi yoktu.
///
/// Bu dosya mevcut davranışı **donduruyor**, düzeltmiyor. İki sürprizi
/// bilerek kayda geçiriyor (aşağıda ilgili testlerde açıklandı).
void main() {
  Response<dynamic> res(int status, [dynamic data]) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: data,
      );

  DioException dio(DioExceptionType type, {Response<dynamic>? response, Object? error}) =>
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: type,
        response: response,
        error: error,
      );

  group('Result', () {
    test('Success: isSuccess true, when success dalını çalıştırır', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(
        result.when(success: (d) => 'ok:$d', failure: (f) => 'fail'),
        'ok:42',
      );
    });

    test('Failure: isFailure true, when failure dalını çalıştırır', () {
      const result = Failure<int>(NetworkFailure());

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(
        result.when(success: (d) => 'ok', failure: (f) => 'fail:${f.runtimeType}'),
        'fail:NetworkFailure',
      );
    });

    test('null payload da geçerli bir Success — boş 204 yanıtları böyle geliyor', () {
      const result = Success<String?>(null);

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d ?? 'null-ok', failure: (f) => 'fail'), 'null-ok');
    });
  });

  group('toAppFailure — ağ katmanı', () {
    test('üç timeout tipi de TimeoutFailure olur', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          dio(type).toAppFailure(),
          isA<TimeoutFailure>(),
          reason: '$type TimeoutFailure olmalı',
        );
      }
    });

    test('connectionError NetworkFailure olur — kullanıcıya "bağlantı yok" denen dal', () {
      expect(dio(DioExceptionType.connectionError).toAppFailure(), isA<NetworkFailure>());
    });

    test('bilinmeyen tip UnknownFailure olur ve orijinal hatayı taşır', () {
      final failure = dio(DioExceptionType.unknown, error: 'boom').toAppFailure();

      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).error, 'boom');
    });
  });

  group('toAppFailure — sunucu yanıtı', () {
    test('gövdedeki error.code ServerFailure olarak taşınır', () {
      final failure = dio(
        DioExceptionType.badResponse,
        response: res(400, {
          'error': {'code': 'INSUFFICIENT_DIAMONDS', 'message': 'Yetersiz elmas', 'params': {'need': 5}},
        }),
      ).toAppFailure();

      expect(failure, isA<ServerFailure>());
      final server = failure as ServerFailure;
      expect(server.code, 'INSUFFICIENT_DIAMONDS');
      expect(server.statusCode, 400);
      expect(server.message, 'Yetersiz elmas');
      expect(server.params, {'need': 5});
    });

    test('code String değilse SERVER_ERROR fallback — bozuk gövdede çökmez', () {
      final failure = dio(
        DioExceptionType.badResponse,
        response: res(500, {'error': {'code': 42}}),
      ).toAppFailure();

      expect((failure as ServerFailure).code, 'SERVER_ERROR');
      expect(failure.message, isNull);
    });

    test('SÜRPRIZ: gövdeli 401 UnauthorizedFailure DEĞİL, ServerFailure döner', () {
      // Gövde parse'ı 401 kontrolünden ÖNCE geliyor (result.dart:96-105).
      // qulo-server her 401'e `{error:{code:...}}` ekliyor (errorHandler.ts:19),
      // yani sunucudan gelen 401'lerde UnauthorizedFailure hiç üretilmiyor.
      // Bu bugün zararsız — auth_interceptor.dart:44 401'i daha önce yakalayıp
      // token yeniliyor — ama biri "401 ise UnauthorizedFailure gelir" varsayıp
      // ona göre dallanırsa sessizce yanılır. Davranış burada dondurulmuştur.
      final failure = dio(
        DioExceptionType.badResponse,
        response: res(401, {'error': {'code': 'TOKEN_EXPIRED'}}),
      ).toAppFailure();

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 'TOKEN_EXPIRED');
      expect(failure.statusCode, 401);
    });

    test('gövdesiz 401 UnauthorizedFailure olur — pratikte yalnızca ara katman 401leri', () {
      expect(dio(DioExceptionType.badResponse, response: res(401)).toAppFailure(),
          isA<UnauthorizedFailure>());
    });

    test('gövdesiz diğer durum kodları SERVER_ERROR olur', () {
      final failure = dio(DioExceptionType.badResponse, response: res(503)).toAppFailure();

      expect((failure as ServerFailure).code, 'SERVER_ERROR');
      expect(failure.statusCode, 503);
    });

    test('gövde Map değilse (HTML hata sayfası) çökmez, SERVER_ERROR döner', () {
      // Railway/Netlify ara katmanı bazen HTML döndürüyor; parse burada patlamamalı.
      final failure = dio(
        DioExceptionType.badResponse,
        response: res(502, '<html>Bad Gateway</html>'),
      ).toAppFailure();

      expect((failure as ServerFailure).code, 'SERVER_ERROR');
      expect(failure.statusCode, 502);
    });

    test('response null ise SERVER_ERROR, statusCode null — çökmez', () {
      final failure = dio(DioExceptionType.badResponse).toAppFailure();

      expect((failure as ServerFailure).code, 'SERVER_ERROR');
      expect(failure.statusCode, isNull);
    });
  });
}
