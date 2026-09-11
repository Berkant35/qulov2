import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qulo_v2/core/network/safe_svg_network_loader.dart';

/// Agdan gelen SVG — Crashlytics'teki "XmlParserException: name expected" fatal'i.
///
/// flutter_svg'de yukleyici hata verirse hata, cagiran yakalasa bile, iki
/// yerden zone'a sizar (`svg.cache`'teki onError'suz `.then` ve
/// vector_graphics'te dinlenmeyen `whenComplete`) → `PlatformDispatcher.onError`
/// → fatal. Sizinti bu yuzden `testWidgets` ile degil duz `test` +
/// `runZonedGuarded` ile sinanir: widget binding hatayi yutuyor.
void main() {
  const validSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="M0 0h24v24H0z"/></svg>';
  // CDN hata/limit sayfasi: tek satir HTML, satir ici JS'teki `<` "name expected" verir.
  const htmlPage = '<!DOCTYPE html><html><head><script>if (a<b) {}</script>'
      '</head><body>Too Many Requests</body></html>';

  late Uint8List fallbackBytes;

  setUpAll(() async {
    final bytes =
        await const SvgStringLoader(SafeSvgNetworkLoader.fallbackSvg).loadBytes(null);
    fallbackBytes = Uint8List.sublistView(bytes);
  });

  setUp(svg.cache.clear);

  test('gecerli SVG yuklenir, yedek degil', () async {
    final r = await _load(MockClient((_) async => http.Response(validSvg, 200)));

    expect(r.error, isNull);
    expect(r.leaked, isEmpty);
    expect(r.bytes, isNot(fallbackBytes));
  });

  group('asla hata firlatmaz, yedek SVG doner, zone\'a sizinti yok', () {
    test('200 ama govde HTML (CDN hata sayfasi)', () async {
      final r = await _load(MockClient((_) async => http.Response(htmlPage, 200)));

      expect(r.error, isNull);
      expect(r.leaked, isEmpty);
      expect(r.bytes, fallbackBytes);
    });

    test('404 HTML sayfasi', () async {
      final r = await _load(MockClient((_) async => http.Response(htmlPage, 404)));

      expect(r.error, isNull);
      expect(r.leaked, isEmpty);
      expect(r.bytes, fallbackBytes);
    });

    test('ag hatasi (cevrimdisi)', () async {
      final r = await _load(
        MockClient((_) async => throw const SocketException('Failed host lookup')),
      );

      expect(r.error, isNull);
      expect(r.leaked, isEmpty);
      expect(r.bytes, fallbackBytes);
    });
  });

  test('koruma: lib icinde ham ag SVG yukleyicisi kullanilmaz', () {
    // Ham SvgNetworkLoader'in hatasi yukaridaki sizintiyla fatal'a doner.
    // `SvgPicture(SvgNetworkLoader(url))` yazimi da ayni yol.
    final banned = RegExp(r'SvgPicture\.network\(|(?<!Safe)SvgNetworkLoader\(');
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => banned.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty, reason: 'AppNetworkSvg kullan');
  });
}

Future<({Uint8List? bytes, Object? error, List<Object> leaked})> _load(
  http.Client client,
) async {
  final leaked = <Object>[];
  Uint8List? bytes;
  Object? error;
  await runZonedGuarded(() async {
    try {
      final data = await SafeSvgNetworkLoader(
        'https://cdn.test/icon.svg',
        httpClient: client,
      ).loadBytes(null);
      bytes = Uint8List.sublistView(data);
    } catch (e) {
      error = e;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }, (e, _) => leaked.add(e));
  return (bytes: bytes, error: error, leaked: leaked);
}
