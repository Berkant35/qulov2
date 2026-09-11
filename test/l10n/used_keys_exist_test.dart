import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';

/// Kodda `tr('anahtar')` / `plural('anahtar', n)` ile kullanilan her statik
/// anahtar en.dart'ta olmali (parite testi 16 dile yayar).
///
/// Parite testi yalnizca diller arasi anahtar kumesini karsilastirir; kodun
/// OLMAYAN bir anahtari istemesini gormez. `AppLocalizations.get` bulunamayan
/// anahtari okunabilir metne cevirdigi icin (`error_rate_limit` → "Error rate
/// limit") hata sessizdir. 2026-09-11'de 17 eksik anahtar bulundu: 14'u koddaki
/// yanlis addi (ayni anlamda anahtar zaten vardi), 3'u gercekten eksikti.
final _use = RegExp(r"""\.(tr|plural)\(\s*'([a-z0-9_]+)'""");

List<String> _missingIn(String source, String path, Set<String> keys) => [
      for (final m in _use.allMatches(source))
        if (!_exists(m.group(1)!, m.group(2)!, keys))
          '$path:${source.substring(0, m.start).split('\n').length}: ${m.group(2)}',
    ];

/// `plural` anahtari son ekle saklanir (`x_one` / `x_other`); `_other` sart.
bool _exists(String kind, String key, Set<String> keys) =>
    kind == 'plural' ? keys.contains('${key}_other') : keys.contains(key);

void main() {
  final keys = enTranslations.keys.toSet();

  group('olcucu once bilinen orneklere karsi sinanir', () {
    test('var olan anahtar temiz, olmayan yakalanir', () {
      expect(_missingIn("context.tr('next')", 'x', keys), isEmpty);
      expect(_missingIn("context.tr('yok_boyle_bir_anahtar')", 'x', keys), hasLength(1));
    });

    test('alt satira tasinmis cagri da yakalanir', () {
      expect(_missingIn("context.tr(\n  'yok_boyle_bir_anahtar',\n)", 'x', keys), hasLength(1));
    });

    test('plural son ekli anahtara bakar', () {
      expect(_missingIn("l10n.plural('time_days_ago', n)", 'x', keys), isEmpty);
      expect(_missingIn("l10n.plural('yok_boyle_bir_anahtar', n)", 'x', keys), hasLength(1));
    });

    test('interpolasyonlu dinamik anahtar bu testin konusu degil', () {
      // `prefix_$x` aileleri dynamic_keys_test'te deger kumeleriyle sinanir.
      expect(_missingIn(r"context.tr('question_category_$c')", 'x', keys), isEmpty);
    });
  });

  test('lib/ icindeki her statik ceviri anahtari en.dart\'ta var', () {
    final missing = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('l10n/translations'))
          ..._missingIn(f.readAsStringSync(), f.path, keys),
    ];

    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
