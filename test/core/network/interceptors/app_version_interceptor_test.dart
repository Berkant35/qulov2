import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qulo_v2/core/network/interceptors/app_version_interceptor.dart';

/// AppVersionInterceptor: her istege `x-app-version` ekler. Sunucu bunu KVKK riza
/// kaydina denetim izi olarak yazar (qulo-server `utils/client-meta.ts`). Baslik
/// eklenmeden once prod'daki riza satirlarinin hicbirinde surum yoktu.
///
/// Gercek Dio + yakalayan adapter kullaniliyor: "istek devam eder" iddiasi ancak
/// istegin adapter'a (sunucuya) ULASTIGI gorulerek kanitlanir. Handler'in
/// tamamlanmasi `next` ile `resolve`'u ayirt etmez.
void main() {
  late _CapturingAdapter adapter;

  Dio dioWith(AppVersionInterceptor interceptor) {
    adapter = _CapturingAdapter();
    return Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);
  }

  test('surumu x-app-version basligiyla sunucuya gonderir', () async {
    await dioWith(AppVersionInterceptor(version: () async => '2.0.10+73')).get('/x');

    expect(adapter.sent?.headers['x-app-version'], '2.0.10+73');
  });

  test('surum okunamazsa istek basliksiz yine sunucuya ulasir', () async {
    await dioWith(
      AppVersionInterceptor(version: () async => throw Exception('kanal yok')),
    ).get('/x');

    expect(adapter.sent, isNotNull, reason: 'baslik yalnizca denetim izi; istegi dusurmemeli');
    expect(adapter.sent!.headers.containsKey('x-app-version'), isFalse);
  });

  test('surum hic donmezse istek zaman asiminin ardindan basliksiz gider — asili kalmaz', () async {
    // Istek yoluna bir platform kanali bagimliligi eklendi; kanal yanit vermezse
    // TUM API cagrilari donardi.
    final never = Completer<String>().future;

    await dioWith(AppVersionInterceptor(
      version: () => never,
      timeout: const Duration(milliseconds: 20),
    )).get('/x');

    expect(adapter.sent, isNotNull);
    expect(adapter.sent!.headers.containsKey('x-app-version'), isFalse);
  });

  test('varsayilan kaynak AppInfoManager.headerVersion — ayarlar etiketi degil', () async {
    // Sunucu "2.0.11 (74)" bicimini sessizce atar; varsayilan yanlis getter'a
    // baglanirsa riza kaydinda surum yine bos kalir.
    PackageInfo.setMockInitialValues(
      appName: 'Qulo',
      packageName: 'app.qulo',
      version: '2.0.11',
      buildNumber: '74',
      buildSignature: '',
    );

    await dioWith(AppVersionInterceptor()).get('/x');

    expect(adapter.sent?.headers['x-app-version'], '2.0.11+74');
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}
