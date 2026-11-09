import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob kimlikleri — tek kaynak (yayıncı pub-1650543626009624, Qulo uygulamaları).
///
/// Release varsayılanı Qulo'nun GERÇEK native birim kimlikleridir (dart-define
/// gerekmez). DEBUG derlemede Google'ın RESMİ TEST birimi kullanılır: geliştirici
/// kendi gerçek reklamına tıklayıp hesabı geçersiz trafikle riske atmasın.
/// `--dart-define=ADMOB_IOS_NATIVE_UNIT=...` / `ADMOB_ANDROID_NATIVE_UNIT=...`
/// verilirse her modda bunlar önceliklidir.
///
/// Uygulama kimliği (`GADApplicationIdentifier` / `APPLICATION_ID`) native
/// dosyalardadır (Info.plist, AndroidManifest.xml). Uzaktan açma anahtarı
/// `app_config.ads_enabled`'dır (kapalıyken hiçbir istek atılmaz).
abstract final class AdMobConfig {
  static const testIosNativeUnit = 'ca-app-pub-3940256099942544/3986624511';
  static const testAndroidNativeUnit = 'ca-app-pub-3940256099942544/2247696110';
  static const releaseIosNativeUnit = 'ca-app-pub-1650543626009624/8012023743';
  static const releaseAndroidNativeUnit = 'ca-app-pub-1650543626009624/3414303180';

  static const _iosNativeUnit = String.fromEnvironment('ADMOB_IOS_NATIVE_UNIT');
  static const _androidNativeUnit = String.fromEnvironment('ADMOB_ANDROID_NATIVE_UNIT');

  /// Virgüllü test cihazı kimlikleri: `--dart-define=ADMOB_TEST_DEVICE_IDS=ID1,ID2`.
  /// Geliştirici kendi telefonunu buraya yazar; böylece kendi reklamına
  /// tıklayıp AdMob hesabını geçersiz trafikle riske atmaz.
  static const _testDeviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

  /// SDK başlatılmadan ÖNCE uygulanacak istek yapılandırması (tek kaynak).
  static RequestConfiguration get requestConfiguration => buildRequestConfiguration(_testDeviceIds);

  /// `ADMOB_TEST_DEVICE_IDS` değerini ayrıştırır: virgülle ayır, kırp, boşları at,
  /// tekrarı sil. Tanımsız/boşsa boş liste.
  @visibleForTesting
  static List<String> parseTestDeviceIds(String raw) {
    final seen = <String>{};
    for (final part in raw.split(',')) {
      final id = part.trim();
      if (id.isNotEmpty) seen.add(id);
    }
    return List.unmodifiable(seen);
  }

  /// Uygulama 18+ ve flört içerikli: yetişkin/olgun reklamlar kapalı (en çok PG),
  /// çocuğa yönelik ve yaş altı muamelesi hayır.
  @visibleForTesting
  static RequestConfiguration buildRequestConfiguration(String rawTestDeviceIds) => RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.pg,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        testDeviceIds: parseTestDeviceIds(rawTestDeviceIds),
      );

  /// Bu platformun native reklam unit kimliği: dart-define > (debug ? test : gerçek).
  static String get nativeUnitId => resolveNativeUnitId(
        isDebug: kDebugMode,
        isIos: Platform.isIOS,
        iosOverride: _iosNativeUnit,
        androidOverride: _androidNativeUnit,
      );

  /// Çözümlenen birim kimliği boş değilse istek atılabilir (fail-closed koruma).
  /// Uzaktan `ads_enabled` kontrolü ayrıca `AdmobManager` tarafındadır.
  static bool get canRequestAds => nativeUnitId.isNotEmpty;

  /// Release derlemede Google test kimliği (dart-define ile) kullanılıyorsa loga yazar.
  static void warnIfTestIdInRelease() {
    if (kDebugMode) return;
    if (nativeUnitId == testIosNativeUnit || nativeUnitId == testAndroidNativeUnit) {
      dev.log(
        'AdMob native unit TEST kimliği kullanılıyor (release build).',
        name: 'AdMobConfig',
        level: 900,
      );
    }
  }

  @visibleForTesting
  static String resolveNativeUnitId({
    required bool isDebug,
    required bool isIos,
    required String iosOverride,
    required String androidOverride,
  }) {
    final override = isIos ? iosOverride : androidOverride;
    if (override.isNotEmpty) return override;
    if (isDebug) return isIos ? testIosNativeUnit : testAndroidNativeUnit;
    return isIos ? releaseIosNativeUnit : releaseAndroidNativeUnit;
  }
}
