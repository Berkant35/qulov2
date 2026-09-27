import 'package:flutter_test/flutter_test.dart';

import '../helpers/translations.dart';

const _translations = allTranslations;

/// Referans dil: fallback zinciri de buraya düşüyor (AppLocalizations.get).
const _reference = 'en';

/// "{name} sana {count} mesaj gönderdi" → {count, name}
///
/// İki stil de taranır: baskın `{name}` biçimi (41 anahtar) ve `@name` biçimi
/// (`referral_share_message`, `discover_invite_friend`,
/// `milestone_profile_completed`). `@` stili 2026-09-27'ye kadar bu regex'in
/// dışındaydı; bir çevirmen `@reward`'ı düşürse ya da `@odul` yazsa kullanıcı
/// ödül sayısı olmayan bir cümle ya da ham `@reward` metni görür, hiçbir test
/// kırmızıya dönmezdi.
Set<String> _placeholders(String text) => RegExp(r'\{(\w+)\}|@(\w+)')
    .allMatches(text)
    .map((m) => m.group(1) ?? m.group(2)!)
    .toSet();

void main() {
  final referenceKeys = _translations[_reference]!.keys.toSet();

  group('translation parity', () {
    test('AppLocalizations ile aynı 18 dili kapsıyor', () {
      expect(_translations.length, 18);
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
