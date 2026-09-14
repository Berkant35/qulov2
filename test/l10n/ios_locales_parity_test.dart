import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';

/// Dart dil listesi ile iOS paketleme dosyaları ve TestFlight not eşlemesi aynı
/// kümeyi taşımalı. 2026-09-08'de InfoPlist.strings'ler pbxproj'e hiç eklenmemişti
/// ve App Store uygulamayı tek dilli sanıyordu; 19. dilde bu dört yerden biri unutulmasın.
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
    final mjs = File('scripts/push_testflight_notes.mjs').readAsStringSync();
    final map = RegExp(
      r'const LOCALE_MAP = \{([\s\S]*?)\};',
    ).firstMatch(mjs)!.group(1)!;
    final keys = RegExp(
      r"\b([a-z]{2}):\s*'",
    ).allMatches(map).map((m) => m.group(1)!).toSet();
    expect(keys, expected);
  });

  test('asc_whatsnew.mjs NOTES, LOCALE_MAP üzerinden her dili kapsar', () {
    // 5. senkron noktası: App Store "Yenilikler" metni. th/id eklenirken unutulmuştu (review).
    final mjs = File('scripts/push_testflight_notes.mjs').readAsStringSync();
    final map = RegExp(
      r'const LOCALE_MAP = \{([\s\S]*?)\};',
    ).firstMatch(mjs)!.group(1)!;
    final ascOf = {
      for (final m in RegExp(r"([a-z]{2}):\s*'([^']+)'").allMatches(map))
        m.group(1)!: m.group(2)!,
    };
    final notes = File('scripts/asc_whatsnew.mjs').readAsStringSync();
    final noteKeys = RegExp(
      r"^  '([^']+)': `",
      multiLine: true,
    ).allMatches(notes).map((m) => m.group(1)!).toSet();
    for (final code in expected) {
      final asc = ascOf[code] ?? code;
      // asc_whatsnew ASC kodlarini kullanir (en-US, de-DE...); TestFlight haritasi ile ayni.
      final candidates = {asc, code, if (code == 'pt') 'pt-PT'};
      expect(
        candidates.any(noteKeys.contains),
        isTrue,
        reason: '$code için Yenilikler notu yok ($candidates)',
      );
    }
  });

  test('testflight_release_notes.json her dil için not içerir', () {
    final json = File(
      'scripts/testflight_release_notes.json',
    ).readAsStringSync();
    for (final code in expected) {
      expect(json, contains('"$code":'), reason: '$code sürüm notu yok');
    }
  });
}
