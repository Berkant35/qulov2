import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:qulo_v2/core/error/crash_classifier.dart';

/// Crashlytics fatal/non-fatal ayrımı: görsel yükleme hataları crash değil.
void main() {
  FlutterErrorDetails details(Object e, {String? library}) =>
      FlutterErrorDetails(exception: e, library: library);

  group('non-fatal (görsel yükleme)', () {
    test("'image resource service' kütüphanesinden gelen her hata", () {
      expect(
        CrashClassifier.isFatalFlutterError(
          details(StateError('codec'), library: CrashClassifier.imageLibrary),
        ),
        isFalse,
      );
    });

    test('CachedNetworkImage ClientException (async, PlatformDispatcher yolu)', () {
      final e = ClientException('Connection closed', Uri.parse('https://cdn.x/a.jpg'));
      expect(CrashClassifier.isImageLoadError(e), isTrue);
      expect(CrashClassifier.isFatalFlutterError(details(e)), isFalse);
    });

    test('cache manager HTTP 404 (HttpException alt sınıfı)', () {
      expect(CrashClassifier.isImageLoadError(const HttpException('Invalid statusCode: 404')), isTrue);
    });

    test('NetworkImageLoadException', () {
      final e = NetworkImageLoadException(statusCode: 403, uri: Uri.parse('https://cdn.x/a.jpg'));
      expect(CrashClassifier.isImageLoadError(e), isTrue);
    });
  });

  group('fatal kalır', () {
    test('widget/render hatası (widgets library)', () {
      expect(
        CrashClassifier.isFatalFlutterError(
          details(StateError('Bad state'), library: 'widgets library'),
        ),
        isTrue,
      );
    });

    test('kütüphanesiz yakalanmamış hata', () {
      expect(CrashClassifier.isFatalFlutterError(details(Exception('x'))), isTrue);
      expect(CrashClassifier.isImageLoadError(StateError('ConcurrentModification')), isFalse);
      expect(CrashClassifier.isImageLoadError(const FormatException('json')), isFalse);
    });
  });
}
