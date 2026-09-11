import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/interceptors/app_version_interceptor.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';

void main() {
  /// AppVersionInterceptor kaydi silinirse sunucu `x-app-version` almaz ve KVKK
  /// riza kaydinda surum sessizce bos kalir — interceptor'in kendi testleri bunu
  /// yakalayamaz.
  test('istek zincirinde AppVersionInterceptor tam bir kez kayitli', () {
    NetworkManager.instance.init();

    expect(
      NetworkManager.instance.dio.interceptors.whereType<AppVersionInterceptor>(),
      hasLength(1),
    );
  });

  /// get/post/put/delete/upload tek bir yoldan sonuc uretir. Repository testleri
  /// fake kullandigi icin bu yolu baska hicbir test calistirmiyor.
  group('NetworkManager.guard — manuel metodlarin ortak sonuc/hata yolu', () {
    Future<Response<dynamic>> ok(dynamic data) async =>
        Response(requestOptions: RequestOptions(path: '/x'), data: data);

    test('parser varsa govdeyi parser ile cevirir', () async {
      final result = await NetworkManager.guard<int>(
        () => ok({'n': 3}),
        (json) => json['n'] as int,
      );

      expect(result, isA<Success<int>>().having((s) => s.data, 'data', 3));
    });

    test('parser yoksa ham govde T olarak doner', () async {
      final result = await NetworkManager.guard<Map<String, dynamic>>(
        () => ok({'n': 3}),
        null,
      );

      expect(
        result,
        isA<Success<Map<String, dynamic>>>().having((s) => s.data, 'data', {'n': 3}),
      );
    });

    test('Dio hatasi toAppFailure ile eslenir (zaman asimi → TimeoutFailure)', () async {
      final result = await NetworkManager.guard<int>(
        () => Future.error(DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        )),
        null,
      );

      expect(
        result,
        isA<Failure<int>>().having((f) => f.failure, 'failure', isA<TimeoutFailure>()),
      );
    });

    test('parser hatasi UnknownFailure olur — cokmez', () async {
      final result = await NetworkManager.guard<int>(
        () => ok({}),
        (json) => throw const FormatException('bozuk govde'),
      );

      expect(
        result,
        isA<Failure<int>>().having((f) => f.failure, 'failure', isA<UnknownFailure>()),
      );
    });

    test('tip uyusmazligi (cast) UnknownFailure olur — cokmez', () async {
      final result = await NetworkManager.guard<int>(() => ok('metin'), null);

      expect(
        result,
        isA<Failure<int>>().having((f) => f.failure, 'failure', isA<UnknownFailure>()),
      );
    });
  });
}
