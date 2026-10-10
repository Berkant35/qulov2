import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/tr.dart';

/// Türkçe çevirilerde diakritiksiz (ASCII) yazılmış kelime koruması.
///
/// 2026-10-04: mağaza görseli çekilirken TR arayüzde "Acik" (tema seçici) ve
/// "Yeni Eslesmeler" (eşleşmeler başlığı) görüldü; tarama 17 anahtar buldu
/// (performans paneli, çevrimiçi durumu…). Ölçüt: aynı kelimenin Türkçe
/// harfli hâli `tr.dart`ın başka bir yerinde geçiyorsa ASCII hâli hatadır.
/// Sınır: kelimenin harfli hâli hiç geçmiyorsa yakalanmaz.
const _turkishLetters = 'ÇĞİÖŞÜçğıöşü';

/// İkisi de geçerli Türkçe kelime olan çiftler ("mi" ⟷ "mı").
const _validAsciiTwins = {'mi', 'mu'};

final _word = RegExp('[A-Za-z$_turkishLetters]+');

/// Türkçe kurala göre küçük harf: I → ı, İ → i.
String _trLower(String w) =>
    w.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Harf farkını yok sayan anahtar: "Açık" ve "Acik" → "acik".
String _fold(String w) {
  const from = 'çğıöşü';
  const to = 'cgiosu';
  final lower = _trLower(w);
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i == -1 ? ch : to[i]);
  }
  return buffer.toString();
}

bool _hasTurkishLetter(String w) => w.split('').any(_turkishLetters.contains);

/// [translations] içinde, harfli hâli başka yerde geçen ASCII kelimeler.
List<String> _asciiOffenders(Map<String, String> translations) {
  final accented = <String, Set<String>>{};
  for (final value in translations.values) {
    for (final m in _word.allMatches(value)) {
      final w = m.group(0)!;
      if (_hasTurkishLetter(w)) {
        accented.putIfAbsent(_fold(w), () => {}).add(_trLower(w));
      }
    }
  }

  final offenders = <String>[];
  for (final entry in translations.entries) {
    for (final m in _word.allMatches(entry.value)) {
      final w = m.group(0)!;
      if (_hasTurkishLetter(w)) continue;
      final twins = accented[_fold(w)];
      final lower = _trLower(w);
      // "ilk" ⟷ "İlk", "HIZLI" ⟷ "Hızlı": yalnız büyük/küçük harf farkı, hata değil.
      if (twins == null || twins.contains(lower)) continue;
      if (_validAsciiTwins.contains(lower)) continue;
      offenders.add('${entry.key}: "$w" → ${twins.join(' / ')}');
    }
  }
  return offenders;
}

void main() {
  group('ölçücü önce bilinen örneklere karşı sınanır', () {
    test('harfli hâli geçen ASCII kelimeyi yakalar', () {
      final found = _asciiOffenders({
        'a': 'Açık',
        'b': 'Acik',
        'c': 'En İyi',
        'd': 'En Iyi',
      });
      expect(found, hasLength(2));
      expect(found.first, startsWith('b: "Acik"'));
      expect(found.last, startsWith('d: "Iyi"'));
    });

    test('büyük/küçük harf ve geçerli ikizleri hata saymaz', () {
      final found = _asciiOffenders({
        'a': 'İlk eşleşme',
        'b': 'ilk adım',
        'c': 'Hızlı',
        'd': 'HIZLI ÇÖZÜCÜ',
        'e': 'Hazır mı?',
        'f': 'Emin mi?',
      });
      expect(found, isEmpty);
    });
  });

  test('tr.dart içinde diakritiksiz yazılmış kelime yok', () {
    final offenders = _asciiOffenders(trTranslations);
    expect(offenders, isEmpty, reason: '\n${offenders.join('\n')}\n');
  });
}
