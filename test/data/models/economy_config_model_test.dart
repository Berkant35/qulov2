import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';

/// Ekonomi config'i (guc fiyatlari, elmas oranlari, tier limitleri) sunucudan
/// gelir ve cevrimdisi acilis icin SharedPreferences'a `toJson` ile yazilip
/// `fromJson` ile okunur (`economy_config_provider`). `toJson`'da unutulan ya
/// da farkli anahtarla okunan bir alan, cevrimdisi acilista sessizce
/// varsayilan fiyata doner.
///
/// Ayirt edici yontem: fallback'in JSON agacindaki HER yaprak degistirilir
/// (int +1, double +0.25, bool tersine). Varsayilanla ayni degeri sinamak
/// eksik alani gizlerdi; degistirilmis deger ancak iki yon de dogruysa geri gelir.
void main() {
  test('her alan onbellek gidis-donusunde korunur (tum yapraklar degistirilmis)', () {
    final original = _plain(EconomyConfig.fallback.toJson());
    final bumped = _bump(original) as Map<String, dynamic>;
    expect(bumped, isNot(equals(original)), reason: 'senaryo: degerler gercekten degisti');

    final roundTrip = _plain(EconomyConfig.fromJson(bumped).toJson());

    expect(roundTrip, bumped);
  });

  test('SUNUCU yanitindaki her alan onbellekte korunur — toJson eksigi yakalanir', () {
    // Ustteki test JSON'u toJson'dan turettigi icin toJson'da UNUTULAN alani
    // goremez (iki tarafta da eksik olur). Burada kaynak toJson'dan bagimsiz:
    // prod `GET /app/economy` yaniti (2026-09-11). Nesne esitligi (Equatable)
    // kullanilir: sunucunun mobilin modellemedigi bolumleri (`retention`)
    // karsilastirmaya girmez.
    final server = jsonDecode(
      File('test/fixtures/economy_config_prod_2026_09_11.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final serverConfig = server['config'] as Map<String, dynamic>;
    final bumped = EconomyConfig.fromJson(_bump(serverConfig) as Map<String, dynamic>);
    expect(bumped, isNot(EconomyConfig.fromJson(serverConfig)), reason: 'senaryo: degerler degisti');

    final restored = EconomyConfig.fromJson(_plain(bumped.toJson()));

    expect(restored, bumped);
  });

  test('fallback gidis-donusunde esit kalir', () {
    final restored = EconomyConfig.fromJson(_plain(EconomyConfig.fallback.toJson()));

    expect(restored, EconomyConfig.fallback);
  });

  test('int anahtarli haritalar JSON\'a yazilabilir (anahtar string)', () {
    // jsonEncode int anahtarli Map'i reddeder; onbellege yazma patlardi.
    expect(() => jsonEncode(EconomyConfig.fallback.toJson()), returnsNormally);
  });

  test('eksik bolumler varsayilana duser — kismi sunucu yaniti cokmez', () {
    final config = EconomyConfig.fromJson(const <String, dynamic>{});

    expect(config, EconomyConfig.fallback);
  });
}

/// JSON'a yaz-oku: gercek onbellek yolu ile ayni tip normallestirmesi.
Map<String, dynamic> _plain(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

Object? _bump(Object? value) => switch (value) {
      Map<String, dynamic> m => <String, dynamic>{
          for (final e in m.entries) e.key: _bump(e.value),
        },
      List<dynamic> l => [for (final x in l) _bump(x)],
      bool b => !b,
      int i => i + 1,
      double d => d + 0.25,
      _ => value,
    };
