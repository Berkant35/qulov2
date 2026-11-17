import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';

/// `ios/Runner/PrivacyInfo.xcprivacy` 2026-10-06'da yanlışlıkla `[]` ile ezilmişti
/// (geçerli plist değil) ve yıllardır "hiçbir veri toplanmıyor, takip yok" diyordu;
/// oysa uygulama Meta SDK ile takip yapıyor (ATT istemi + setAdvertiserTracking) ve
/// hesaba bağlı 16 veri türü topluyor. ASC App Privacy etiketi ile manifest
/// ayrıştığında Apple incelemede sorabilir. Bu test üç şeyi sabitler:
/// dosya gerçek bir plist, takip beyanı kodla tutarlı, izinlerin veri türleri var.
void main() {
  late String manifest;

  setUpAll(() {
    expect(File('pubspec.yaml').existsSync(), isTrue,
        reason: 'testi qulov2 kökünden çalıştır');
    manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
  });

  Set<String> collectedTypes() => RegExp(
        r'<string>NSPrivacyCollectedDataType([A-Za-z]+)</string>',
      ).allMatches(manifest).map((m) => m.group(1)!).toSet();

  test('manifest XML plist, JSON dizisi değil', () {
    expect(manifest.trimLeft(), startsWith('<?xml'));
    expect(manifest, contains('<plist'));
  });

  test('takip beyanı Meta SDK kullanımıyla tutarlı', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final usesMeta = infoPlist.contains('<key>FacebookAppID</key>');
    final tracking = RegExp(r'<key>NSPrivacyTracking</key>\s*<true/>')
        .hasMatch(manifest);
    expect(tracking, usesMeta,
        reason: 'Meta SDK varken NSPrivacyTracking true olmalı (ve tersi)');
    if (usesMeta) {
      expect(manifest, contains('<string>ep1.facebook.com</string>'),
          reason: 'Meta takip alanı NSPrivacyTrackingDomains\'de olmalı');
      expect(collectedTypes(), contains('DeviceID'));
    }
  });

  test('Info.plist izinleri karşılık gelen veri türünü taşıyor', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    const permissionToType = {
      'NSLocationWhenInUseUsageDescription': 'PreciseLocation',
      'NSMicrophoneUsageDescription': 'AudioData',
      'NSPhotoLibraryUsageDescription': 'PhotosorVideos',
    };
    final types = collectedTypes();
    permissionToType.forEach((permission, type) {
      if (infoPlist.contains('<key>$permission</key>')) {
        expect(types, contains(type), reason: '$permission var, $type beyanı yok');
      }
    });
  });

  test('mikrofon açıklamasındaki süre soru sesi üst sınırıyla tutarlı (App Review metni)', () {
    // Metin "10 saniye" diyordu, sınır 15 sn (2.0.19 final review M4).
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final mic = RegExp(r'<key>NSMicrophoneUsageDescription</key>\s*<string>([^<]*)</string>')
        .firstMatch(infoPlist)
        ?.group(1);
    expect(mic, isNotNull);
    for (final m in RegExp(r'(\d+)[- ]second').allMatches(mic!)) {
      expect(int.parse(m.group(1)!), AppConstants.questionVoiceMaxSeconds, reason: mic);
    }
  });

  test('SDK\'ların topladığı türler uygulama manifestinde de var', () {
    // RevenueCat → PurchaseHistory, Crashlytics → CrashData, Firebase Analytics → ProductInteraction
    final pubspec = File('pubspec.yaml').readAsStringSync();
    const depToType = {
      'purchases_flutter': 'PurchaseHistory',
      'firebase_crashlytics': 'CrashData',
      'firebase_analytics': 'ProductInteraction',
    };
    // google_mobile_ads (AdMob) → reklam kimliği, reklam verisi, etkileşim, tanılama.
    const adsTypes = ['DeviceID', 'AdvertisingData', 'ProductInteraction', 'OtherDiagnosticData'];
    final types = collectedTypes();
    depToType.forEach((dep, type) {
      if (RegExp('^  $dep:', multiLine: true).hasMatch(pubspec)) {
        expect(types, contains(type), reason: '$dep var, $type beyanı yok');
      }
    });
    if (RegExp('^  google_mobile_ads:', multiLine: true).hasMatch(pubspec)) {
      for (final type in adsTypes) {
        expect(types, contains(type), reason: 'google_mobile_ads var, $type beyanı yok');
      }
    }
  });

  test('Google reklam alanları NSPrivacyTrackingDomains\'e YAZILMAZ', () {
    // ATT reddedilince iOS izleme alanlarına bağlantıyı keser; AdMob alanları listeye
    // girerse izin vermeyen kullanıcıda kişiselleştirilmemiş reklam da yüklenmez.
    final domains = RegExp(r'<key>NSPrivacyTrackingDomains</key>\s*<array>([\s\S]*?)</array>')
        .firstMatch(manifest)!
        .group(1)!;
    for (final bad in ['doubleclick', 'googlesyndication', 'googleadservices', 'admob', 'google']) {
      expect(domains, isNot(contains(bad)), reason: '$bad izleme alanı olarak beyan edilmemeli');
    }
  });
}
