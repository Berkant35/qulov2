import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kaynak tarama korumasi: kullaniciya gorunen metin `context.tr()` ile gelir.
///
/// 2026-09-11: satir bazli grep yalnizca 3 aday bulmustu; formatlayicinin alt
/// satira tasidigi `Text(\n  'metin')` bicimini goremiyordu. Cok satirli tarama
/// 7 gercek sabit metin buldu — hepsi diakritiksiz Turkce ve her dilde oyle
/// gorunuyordu: paywall "Mor Elmas Satin Al", sohbet "Bu mesaj silindi", sohbet
/// sorusu olusturma butonlari (Ileri/Gonder/Geri/Taslak Kaydet), karsilastirma
/// tablosu "FREE".
const _l = r'[A-Za-zÇĞİÖŞÜçğıöşü]';
final _single = [r"'(?:[^'$\\\n]|\\.)*", _l, r"{2,}(?:[^'$\\\n]|\\.)*'"].join();
final _double = [r'"(?:[^"$\\\n]|\\.)*', _l, r'{2,}(?:[^"$\\\n]|\\.)*"'].join();
final _literal = ['(?:', _single, '|', _double, ')'].join();
final _pattern = RegExp([
  r'\b(?:Text|SelectableText)\(\s*',
  _literal,
  r'|\b(?:hintText|labelText|helperText|errorText|tooltip|semanticLabel|semanticsLabel|title|label|message)\s*:\s*(?:const\s+)?(?:Text\(\s*)?',
  _literal,
].join());

/// Bilincli istisnalar: urun adlari ve emoji kacisi (kilit ikonu).
const _allowed = ["'PLUS'", "'PREMIUM'", r"'\ud83d\udd12'"];

List<String> _offendersIn(String source, String path) {
  final code = source.replaceAll(RegExp(r'//[^\n]*'), '');
  return [
    for (final m in _pattern.allMatches(code))
      if (!_allowed.any(m.group(0)!.contains))
        '$path:${code.substring(0, m.start).split('\n').length}: '
            '${m.group(0)!.split(RegExp(r'\s+')).join(' ')}',
  ];
}

void main() {
  group('olcucu once bilinen orneklere karsi sinanir', () {
    for (final sample in [
      "Text('Hello world')",
      "Text(\n        'Merhaba dunya',\n      )",
      "hintText: 'Search here'",
      "title: const Text('Ayarlar')",
      'label: "FREE"',
    ]) {
      test('yakalar: ${sample.replaceAll('\n', r'\n')}', () {
        expect(_offendersIn(sample, 'x'), hasLength(1));
      });
    }

    for (final sample in [
      "Text(context.tr('x_key'))",
      r"Text('$count')",
      r"Text('+${n}')",
      "Text('%')",
      "// Text('yorum satiri')",
      "label: 'PLUS'",
    ]) {
      test('yakalamaz: $sample', () {
        expect(_offendersIn(sample, 'x'), isEmpty);
      });
    }
  });

  test('lib/features ve lib/core/widgets icinde sabit UI metni yok', () {
    final offenders = [
      for (final base in ['lib/features', 'lib/core/widgets'])
        for (final f in Directory(base).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            ..._offendersIn(f.readAsStringSync(), f.path),
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
