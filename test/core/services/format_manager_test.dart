import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/format_manager.dart';

/// Tek noktadan biçimlendirme: aynı değer, bölgeye göre farklı sunum.
/// Sunucu her zaman metrik gönderir (km, cm, kg); dönüşüm burada.
void main() {
  final fm = FormatManager.instance;
  // UTC öğle: her saat diliminde (±12) aynı takvim günü kalır; saat testleri yerel DateTime ile.
  final noon = DateTime.utc(2026, 9, 4, 12, 0);

  group('UnitSystem.resolve', () {
    test('US/LR/MM/GB imperial, gerisi metrik, null metrik', () {
      expect(UnitSystem.resolve('US'), UnitSystem.imperial);
      expect(UnitSystem.resolve('gb'), UnitSystem.imperial);
      expect(UnitSystem.resolve('TR'), UnitSystem.metric);
      expect(UnitSystem.resolve('DE'), UnitSystem.metric);
      expect(UnitSystem.resolve(null), UnitSystem.metric);
    });
  });

  group('acceptLanguageTag', () {
    test('bolge kodu varsa dil-BOLGE etiketi doner', () async {
      await fm.configure(const Locale('tr', 'TR'));
      expect(fm.acceptLanguageTag, 'tr-TR');
    });

    test('bolge kodu yoksa sadece dil kodu doner', () async {
      await fm.configure(const Locale('en'));
      expect(fm.acceptLanguageTag, 'en');
    });
  });

  group('configure', () {
    test('ülke kodu yoksa profil ülkesine düşer', () async {
      await fm.configure(const Locale('en'), profileCountry: 'US');
      expect(fm.units, UnitSystem.imperial);
      await fm.configure(const Locale('en'));
      expect(fm.units, UnitSystem.metric);
    });
  });

  group('en_US (imperial)', () {
    setUp(() => fm.configure(const Locale('en', 'US')));

    test('mesafe mil, 1 ondalık; 1 km altı nearby', () {
      expect(fm.distance(3.2), '2.0 mi');
      expect(fm.distance(0.4), 'Nearby');
    });
    test('locationLine şehir • mesafe / tek parça / null', () {
      expect(fm.locationLine(city: 'Boston', distanceKm: 3.2), 'Boston • 2.0 mi');
      expect(fm.locationLine(city: null, distanceKm: 3.2), '2.0 mi');
      expect(fm.locationLine(city: 'Boston', distanceKm: null), 'Boston');
      expect(fm.locationLine(city: '', distanceKm: null), isNull);
    });
    test('yarıçap: mil etiketi, km gidiş-dönüş sapmasız', () {
      final s = fm.radiusScale;
      expect(s.divisions, isNull);
      expect(s.label(s.fromKm(50)), '31 mi');
      expect(s.toKm(s.fromKm(50)).round(), 50);
      expect(fm.radius(50), '31 mi');
    });
    test('boy ft/in, kilo lbs, geri dönüşümler', () {
      expect(fm.height(178), "5'10\"");
      expect(fm.heightToImperial(178), (feet: 5, inches: 10));
      expect(fm.heightToCm(feet: 5, inches: 10), 178);
      expect(fm.weight(72), '159 lbs');
      expect(fm.weightToLbs(72), 159);
      expect(fm.weightToKg(159), 72);
    });
    test('tarih ay adıyla, saat 12 saatlik', () {
      expect(fm.date(noon), 'Sep 4, 2026');
      expect(fm.dateShort(noon), 'Sep 4');
      // intl 0.20.2 CLDR verisinde en_US saat/meridyem arasi dar bosluksuz
      // bosluk (U+202F) kullanir; normalize et (bicim dile ait, koda degil).
      expect(fm.time(DateTime(2026, 9, 4, 23, 45)).replaceAll('\u202F', ' '), '11:45 PM');
    });
    test('sayı ve yüzde', () {
      expect(fm.integer(1000), '1,000');
      expect(fm.percent(85), '85%');
      expect(fm.seconds(30), '30s');
    });
  });

  group('tr_TR (metrik)', () {
    setUp(() => fm.configure(const Locale('tr', 'TR')));

    test('mesafe km ondalık virgül', () {
      expect(fm.distance(3.2), '3,2 km');
      expect(fm.distance(0.4), 'Yakında');
    });
    test('yarıçap 5 km adım', () {
      final s = fm.radiusScale;
      expect(s.divisions, 99);
      expect(fm.radius(50), '50 km');
    });
    test('boy/kilo metrik', () {
      expect(fm.height(178), '178 cm');
      expect(fm.weight(72), '72 kg');
    });
    test('tarih/saat', () {
      expect(fm.date(noon), '4 Eyl 2026');
      expect(fm.time(DateTime(2026, 9, 4, 23, 45)), '23:45');
    });
    test('sayı/yüzde', () {
      expect(fm.integer(1000), '1.000');
      expect(fm.percent(85), '%85');
    });
  });

  group('en_GB', () {
    setUp(() => fm.configure(const Locale('en', 'GB')));
    test('mil ama 24 saat', () {
      expect(fm.units, UnitSystem.imperial);
      expect(fm.time(DateTime(2026, 9, 4, 23, 45)), '23:45');
      expect(fm.date(noon), '4 Sept 2026');
    });
  });

  group('de_DE', () {
    setUp(() => fm.configure(const Locale('de', 'DE')));
    test('tarih ve yüzde Almanca', () {
      expect(fm.date(noon), '4. Sept. 2026');
      // intl Almanca yüzde deseninde sayı ile % arasında NBSP var; normalize et.
      expect(fm.percent(85).replaceAll('\u00A0', ' '), '85 %');
    });
  });

  group('göreli zaman (en)', () {
    setUp(() => fm.configure(const Locale('en', 'US')));
    final now = DateTime(2026, 9, 4, 12, 0);

    test('dayLabel bugün / dün / tarih', () {
      expect(fm.dayLabel(now, now: now), 'Today');
      expect(fm.dayLabel(now.subtract(const Duration(days: 1)), now: now), 'Yesterday');
      expect(fm.dayLabel(now.subtract(const Duration(days: 3)), now: now), 'Sep 1, 2026');
    });
    test('relative eşikleri', () {
      expect(fm.relative(now.subtract(const Duration(seconds: 30)), now: now), 'Just now');
      expect(fm.relative(now.subtract(const Duration(minutes: 1)), now: now), '1 minute ago');
      expect(fm.relative(now.subtract(const Duration(minutes: 5)), now: now), '5 minutes ago');
      expect(fm.relative(now.subtract(const Duration(hours: 3)), now: now), '3 hours ago');
      expect(fm.relative(now.subtract(const Duration(days: 4)), now: now), '4 days ago');
      expect(fm.relative(now.subtract(const Duration(days: 10)), now: now), 'Aug 25');
    });
    test('relativeShort rozet biçimi', () {
      expect(fm.relativeShort(now.subtract(const Duration(seconds: 5)), now: now), 'Now');
      expect(fm.relativeShort(now.subtract(const Duration(minutes: 5)), now: now), '5m');
      expect(fm.relativeShort(now.subtract(const Duration(hours: 3)), now: now), '3h');
      expect(fm.relativeShort(now.subtract(const Duration(days: 4)), now: now), '4d');
    });
    test('gelecek damga (saat kayması) just now sayılır', () {
      expect(fm.relative(now.add(const Duration(days: 30)), now: now), 'Just now');
      expect(fm.relativeShort(now.add(const Duration(days: 2)), now: now), 'Now');
    });
  });
}
