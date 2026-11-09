import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';

/// Dart dil listesi ile iOS paketleme dosyaları ve TestFlight not eşlemesi aynı
/// kümeyi taşımalı. 2026-09-08'de InfoPlist.strings'ler pbxproj'e hiç eklenmemişti
/// ve App Store uygulamayı tek dilli sanıyordu; 19. dilde bu dört yerden biri unutulmasın.
/// push_testflight_notes.mjs LOCALE_MAP: Dart dil kodu → ASC kodu (tr→tr, de→de-DE...).
/// Üç senkron testi aynı haritayı okur; parse tek yerde.
Map<String, String> _testFlightLocaleMap() {
  final map = RegExp(r'const LOCALE_MAP = \{([\s\S]*?)\};')
      .firstMatch(File('scripts/push_testflight_notes.mjs').readAsStringSync())!
      .group(1)!;
  return {
    for (final m in RegExp(r"([a-z]{2}):\s*'([^']+)'").allMatches(map))
      m.group(1)!: m.group(2)!,
  };
}

void main() {
  final expected = AppConstants.supportedQuestionLocales.toSet();

  setUpAll(() {
    // Dosya yollari paket kokune gore; monorepo kokunden kosulursa anlamsiz hata yerine net mesaj.
    expect(
      File('pubspec.yaml').existsSync(),
      isTrue,
      reason: 'testi qulov2 kokunden calistir',
    );
  });

  // ITMS-90683 (2026-11-02, build 97): geolocator Always API'sine referans veriyor; uygulama
  // Always istemese de Apple anahtarı ister. Metin When-In-Use ile aynı kalmalı.
  test('Always konum anahtarı Info.plist ve her dilde When-In-Use ile aynı', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    String plistValue(String key) => RegExp(
      '<key>$key</key>\\s*<string>([\\s\\S]*?)</string>',
    ).firstMatch(plist)!.group(1)!;
    expect(
      plistValue('NSLocationAlwaysAndWhenInUseUsageDescription'),
      plistValue('NSLocationWhenInUseUsageDescription'),
    );

    for (final code in expected) {
      final strings = File(
        'ios/Runner/$code.lproj/InfoPlist.strings',
      ).readAsStringSync();
      String? value(String key) =>
          RegExp('^"$key"\\s*=\\s*(.*)\$', multiLine: true)
              .firstMatch(strings)
              ?.group(1);
      final whenInUse = value('NSLocationWhenInUseUsageDescription');
      expect(whenInUse, isNotNull, reason: code);
      expect(
        value('NSLocationAlwaysAndWhenInUseUsageDescription'),
        whenInUse,
        reason: code,
      );
    }
  });

  test('Info.plist CFBundleLocalizations == supportedQuestionLocales', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final block = RegExp(
      r'<key>CFBundleLocalizations</key>\s*<array>([\s\S]*?)</array>',
    ).firstMatch(plist)!.group(1)!;
    final codes = RegExp(
      r'<string>([a-z]{2}(?:-[A-Za-z]+)?)</string>',
    ).allMatches(block).map((m) => m.group(1)!).toSet();
    expect(codes, expected);
  });

  test(
    'her dil için ios/Runner/<dil>.lproj/InfoPlist.strings var ve pbxproj\'e bağlı',
    () {
      final pbx = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      for (final code in expected) {
        expect(
          File('ios/Runner/$code.lproj/InfoPlist.strings').existsSync(),
          isTrue,
          reason: '$code.lproj yok',
        );
        expect(
          pbx,
          contains('$code.lproj/InfoPlist.strings'),
          reason: '$code pbxproj\'e eklenmemiş',
        );
      }
    },
  );

  test('push_testflight_notes.mjs LOCALE_MAP her dili eşler', () {
    // Yalnız mağazada olan vitrinler (vi, 2.0.15 What's New) haritada fazladan
    // durabilir; eksik uygulama dili ise notun o dilde hiç gitmemesi demek.
    expect(_testFlightLocaleMap().keys.toSet(), containsAll(expected));
  });

  test(
    'asc_keywords.mjs K, LOCALE_MAP üzerinden her dil için keyword seti taşır',
    () {
      // 6. senkron noktası: mağaza arama kelimeleri. th/id 18 dile çıkarken burada unutulmuştu.
      final ascOf = _testFlightLocaleMap();
      final k = RegExp(r'const K = \{([\s\S]*?)\n\};')
          .firstMatch(File('scripts/asc_keywords.mjs').readAsStringSync())!
          .group(1)!;
      final keywordKeys = RegExp(
        r"'([A-Za-z-]+)':",
      ).allMatches(k).map((m) => m.group(1)!).toSet();
      for (final code in expected) {
        expect(
          keywordKeys,
          contains(ascOf[code] ?? code),
          reason: '$code için keyword seti yok',
        );
      }
    },
  );

  test('testflight_release_notes.json her dil için not içerir', () {
    final json = File(
      'scripts/testflight_release_notes.json',
    ).readAsStringSync();
    for (final code in expected) {
      expect(json, contains('"$code":'), reason: '$code sürüm notu yok');
    }
  });
}
