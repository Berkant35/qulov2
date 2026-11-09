import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qulo_v2/core/config/admob_config.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';

/// Google Mobile Ads (AdMob) sarmalayıcısı — pakete tek giriş noktası.
///
/// SDK, `ensureReady` çağrılana dek BAŞLATILMAZ: VIP/uzaktan kapalı kullanıcıda
/// bu metot hiç çağrılmaz, dolayısıyla SDK init'i ve reklam isteği olmaz.
/// EEA/UK'de UMP onay formu burada gösterilir; onay yoksa `false` döner.
class AdMobManager {
  AdMobManager._();
  static final AdMobManager instance = AdMobManager._();

  Future<bool>? _ready;

  /// UMP onayını alır (gerekirse form çıkar), onay varsa SDK'yı başlatır.
  /// Başarı önbelleklenir; başarısızlık bir sonraki çağrıda yeniden denenir.
  Future<bool> ensureReady() {
    final existing = _ready;
    if (existing != null) return existing;
    final attempt = _prepare().then((ok) {
      if (!ok) _ready = null;
      return ok;
    });
    return _ready = attempt;
  }

  Future<bool> _prepare() async {
    try {
      if (!AdMobConfig.canRequestAds) {
        AdMobConfig.warnIfTestIdInRelease();
        return false; // release'te gerçek unit kimliği yok → ne onay formu ne istek
      }
      await _updateConsentInfo();
      await _showConsentFormIfRequired();
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      AdMobConfig.warnIfTestIdInRelease();
      // Yapılandırma initialize'dan ÖNCE: içerik sınırı ve test cihazları ilk istekte geçerli olsun.
      await MobileAds.instance.updateRequestConfiguration(AdMobConfig.requestConfiguration);
      await MobileAds.instance.initialize();
      return true;
    } catch (e, stack) {
      dev.log('AdMob hazırlık hatası: $e', name: 'AdMobManager', stackTrace: stack);
      return false;
    }
  }

  Future<void> _updateConsentInfo() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => done.complete(),
      // Güncelleme düşse bile önbellekteki onay durumu `canRequestAds` ile okunur.
      (error) => done.complete(),
    );
    return done.future;
  }

  Future<void> _showConsentFormIfRequired() {
    final done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((_) => done.complete());
    return done.future;
  }

  /// Native reklam yükler. Başarısızlıkta [NativeAdLoadException] fırlatır.
  Future<NativeAdHandle> loadNativeAd({
    required bool nonPersonalized,
    required NativeAdStyle style,
    VoidCallback? onImpression,
    VoidCallback? onClicked,
    Duration timeout = const Duration(seconds: 15),
  }) {
    final done = Completer<NativeAdHandle>();
    final ad = NativeAd(
      adUnitId: AdMobConfig.nativeUnitId,
      request: AdRequest(nonPersonalizedAds: nonPersonalized),
      nativeTemplateStyle: style.toTemplateStyle(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => done.complete(GoogleNativeAdHandle(ad as NativeAd)),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          done.completeError(NativeAdLoadException(error.code, error.message));
        },
        onAdImpression: (_) => onImpression?.call(),
        onAdClicked: (_) => onClicked?.call(),
      ),
    )..load();
    // Zaman aşımında reklam serbest bırakılır: geç gelen yanıt sızdırılmaz.
    return done.future.timeout(timeout, onTimeout: () {
      ad.dispose();
      throw const NativeAdLoadException(-2, 'timeout');
    });
  }
}
