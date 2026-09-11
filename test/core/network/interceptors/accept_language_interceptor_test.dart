import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/interceptors/accept_language_interceptor.dart';
import 'package:qulo_v2/core/services/format_manager.dart';

/// AcceptLanguageInterceptor: her istege FormatManager locale'inden Accept-Language ekler.
void main() {
  setUp(() async {
    await FormatManager.instance.configure(const Locale('en'));
  });

  test('bolgeli locale (tr-TR) Accept-Language basligina dil-BOLGE olarak yazilir', () async {
    await FormatManager.instance.configure(const Locale('tr', 'TR'));
    final options = RequestOptions(path: '/x');

    AcceptLanguageInterceptor().onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Accept-Language'], 'tr-TR');
  });

  test('bolgesiz locale (en) Accept-Language basligina sadece dil kodu olarak yazilir', () async {
    await FormatManager.instance.configure(const Locale('en'));
    final options = RequestOptions(path: '/x');

    AcceptLanguageInterceptor().onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Accept-Language'], 'en');
  });
}
