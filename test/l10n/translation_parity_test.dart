import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/ar.dart';
import 'package:qulo_v2/core/l10n/translations/de.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/l10n/translations/es.dart';
import 'package:qulo_v2/core/l10n/translations/fr.dart';
import 'package:qulo_v2/core/l10n/translations/hi.dart';
import 'package:qulo_v2/core/l10n/translations/it.dart';
import 'package:qulo_v2/core/l10n/translations/ja.dart';
import 'package:qulo_v2/core/l10n/translations/ko.dart';
import 'package:qulo_v2/core/l10n/translations/nl.dart';
import 'package:qulo_v2/core/l10n/translations/pl.dart';
import 'package:qulo_v2/core/l10n/translations/pt.dart';
import 'package:qulo_v2/core/l10n/translations/ru.dart';
import 'package:qulo_v2/core/l10n/translations/sv.dart';
import 'package:qulo_v2/core/l10n/translations/tr.dart';
import 'package:qulo_v2/core/l10n/translations/zh.dart';

/// AppLocalizations._localizedValues private — burada aynı listeyi tutuyoruz.
/// Yeni dil eklenince bu map de güncellenmeli (aksi halde parity testi o dili atlar).
const _translations = <String, Map<String, String>>{
  'tr': trTranslations,
  'en': enTranslations,
  'de': deTranslations,
  'fr': frTranslations,
  'es': esTranslations,
  'ar': arTranslations,
  'ru': ruTranslations,
  'pt': ptTranslations,
  'it': itTranslations,
  'ja': jaTranslations,
  'ko': koTranslations,
  'zh': zhTranslations,
  'nl': nlTranslations,
  'pl': plTranslations,
  'sv': svTranslations,
  'hi': hiTranslations,
};

/// Referans dil: fallback zinciri de buraya düşüyor (AppLocalizations.get).
const _reference = 'en';

/// "{name} sana {count} mesaj gönderdi" → {count, name}
Set<String> _placeholders(String text) => RegExp(r'\{(\w+)\}')
    .allMatches(text)
    .map((m) => m.group(1)!)
    .toSet();

void main() {
  final referenceKeys = _translations[_reference]!.keys.toSet();

  group('translation parity', () {
    test('AppLocalizations ile aynı 16 dili kapsıyor', () {
      expect(_translations.length, 16);
    });

    test('her dil $_reference ile birebir aynı key setine sahip', () {
      final problems = <String>[];

      for (final entry in _translations.entries) {
        if (entry.key == _reference) continue;
        final keys = entry.value.keys.toSet();

        final missing = referenceKeys.difference(keys);
        final extra = keys.difference(referenceKeys);

        if (missing.isNotEmpty) {
          problems.add('${entry.key}: EKSİK (${missing.length}) → ${missing.join(', ')}');
        }
        if (extra.isNotEmpty) {
          problems.add('${entry.key}: FAZLA (${extra.length}) → ${extra.join(', ')}');
        }
      }

      expect(problems, isEmpty, reason: '\n${problems.join('\n')}\n');
    });

    test('hiçbir çeviri boş değil', () {
      final problems = <String>[];

      for (final entry in _translations.entries) {
        for (final pair in entry.value.entries) {
          if (pair.value.trim().isEmpty) problems.add('${entry.key}.${pair.key}');
        }
      }

      expect(problems, isEmpty, reason: 'boş çeviri: ${problems.join(', ')}');
    });

    // Çevirmen {name}'i {isim} yaparsa kullanıcı ham placeholder görür — en sinsi i18n bug'ı.
    test('placeholder isimleri $_reference ile aynı', () {
      final reference = _translations[_reference]!
          .map((key, value) => MapEntry(key, _placeholders(value)));
      final problems = <String>[];

      for (final entry in _translations.entries) {
        if (entry.key == _reference) continue;
        for (final pair in entry.value.entries) {
          final expected = reference[pair.key];
          if (expected == null) continue; // key parity testi zaten yakalar
          final actual = _placeholders(pair.value);
          if (!_sameSet(expected, actual)) {
            problems.add('${entry.key}.${pair.key}: bekleniyor $expected → bulunan $actual');
          }
        }
      }

      expect(problems, isEmpty, reason: '\n${problems.join('\n')}\n');
    });

    test('key\'ler snake_case (yeni key eklerken konvansiyon korunsun)', () {
      final pattern = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
      final offenders =
          referenceKeys.where((k) => !pattern.hasMatch(k)).toList()..sort();

      expect(offenders, isEmpty, reason: 'snake_case değil: ${offenders.join(', ')}');
    });
  });
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
