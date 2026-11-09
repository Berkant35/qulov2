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

  group('oracleAccuracy — guc demosu Kahin dogrulugu', () {
    // Sunucu `GET /app/economy` → `{ version, config, oracleAccuracy }`: oran
    // config'in ICINDE degil, kok seviyede ayri alan (config semasina girmez).
    Map<String, dynamic> envelope({Object? oracleAccuracy, bool withConfig = true}) => {
          'version': 3,
          if (withConfig) 'config': _plain(EconomyConfig.fallback.toJson()),
          if (oracleAccuracy != null) 'oracleAccuracy': oracleAccuracy,
        };

    test('oracleAccuracy kok alandan okunur (0.65)', () {
      final response = EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 0.65));

      expect(response.config.oracleAccuracy, 0.65);
    });

    test('alan yoksa 0.7 — demo yedek degeriyle calisir', () {
      final response = EconomyConfigResponse.fromJson(envelope());

      expect(response.config.oracleAccuracy, 0.7);
      expect(EconomyConfig.fallback.oracleAccuracy, 0.7);
    });

    test('kokteki tam sayi (1 ve 0 — JSON\'da int gelir) double olur, cokmez', () {
      expect(EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 1)).config.oracleAccuracy, 1.0);
      expect(EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 0)).config.oracleAccuracy, 0.0);
    });

    test('config bolumu yokken de kok oran uygulanir, geri kalan fallback', () {
      final response = EconomyConfigResponse.fromJson(
        envelope(oracleAccuracy: 0.65, withConfig: false),
      );

      expect(response.config.oracleAccuracy, 0.65);
      expect(response.config.powerCosts, EconomyConfig.fallback.powerCosts);
      expect(response.config.core, EconomyConfig.fallback.core);
    });

    test('toJson→fromJson oracleAccuracy korunur (cevrimdisi acilis onbellegi)', () {
      final config = EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 0.65)).config;

      final restored = EconomyConfig.fromJson(_plain(config.toJson()));

      expect(restored.oracleAccuracy, 0.65);
      expect(restored, config);
    });

    test('oran esitlige girer — farkli oranli config\'ler esit sayilmaz', () {
      final a = EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 0.65)).config;
      final b = EconomyConfigResponse.fromJson(envelope(oracleAccuracy: 0.9)).config;

      expect(a, isNot(b));
    });
  });

  group('rewards.starterPowers — kayit hediyesi guc adetleri', () {
    // Sunucu `DEFAULT_STARTER_POWERS`: 8 gucun hepsi 1. Alan hic yoksa varsayilan;
    // alan VARSA oldugu gibi (kismi tanimda listelenmeyen guc verilmez —
    // sunucu `exchange.service` yalniz listelenenleri envantere yazar).
    const allPowers = [
      'ORACLE', 'HALF', 'SKIP', 'SKIP_ALL', 'TIME_EXTEND', 'HINT', 'POWER_BLOCK', 'POWER_UNBLOCK',
    ];

    Map<String, dynamic> rewardsJson({Object? starterPowers}) => {
          'milestones': {'25': 5},
          'referralPurple': 25,
          'maxCompletedReferrals': 10,
          if (starterPowers != null) 'starterPowers': starterPowers,
        };

    test('starterPowers yoksa 8 guc × 1', () {
      final rewards = RewardsConfig.fromJson(rewardsJson());

      expect(rewards.starterPowers, {for (final p in allPowers) p: 1});
    });

    test('varsayilan guc adlari fiyat tablosundaki 8 guc ile birebir ayni', () {
      final pricedPowers = PowerCostsConfig.fallback.toJson().keys.toSet();

      expect(EconomyConfig.fallback.rewards.starterPowers.keys.toSet(), pricedPowers);
      expect(pricedPowers, allPowers.toSet());
    });

    test('config\'te rewards bolumu hic yoksa da 8 guc × 1', () {
      final config = EconomyConfig.fromJson(const <String, dynamic>{});

      expect(config.rewards.starterPowers, {for (final p in allPowers) p: 1});
    });

    test("starterPowers {'HALF':0} okunur — 0 gecerli adet, kismi tanim varsayilanla doldurulmaz", () {
      final rewards = RewardsConfig.fromJson(rewardsJson(starterPowers: {'HALF': 0}));

      expect(rewards.starterPowers, {'HALF': 0});
    });

    test('listelenen tum guclerin adedi okunur, listede olmayan kalmaz', () {
      final rewards = RewardsConfig.fromJson(
        rewardsJson(starterPowers: {'ORACLE': 2, 'HALF': 0, 'HINT': 5}),
      );

      expect(rewards.starterPowers, {'ORACLE': 2, 'HALF': 0, 'HINT': 5});
      expect(rewards.starterPowers['SKIP'], isNull);
    });

    test('starterPowers onbellek gidis-donusunde korunur', () {
      final rewards = RewardsConfig.fromJson(
        rewardsJson(starterPowers: {'ORACLE': 3, 'SKIP_ALL': 0}),
      );

      final restored = RewardsConfig.fromJson(_plain(rewards.toJson()));

      expect(restored.starterPowers, {'ORACLE': 3, 'SKIP_ALL': 0});
      expect(restored, rewards);
    });
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
