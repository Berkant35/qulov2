import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Yüklenmiş bir native reklamın paketten bağımsız tutamacı: UI yalnız bunu
/// bilir, `google_mobile_ads` tipleri servis katmanında kalır (testler sahte
/// tutamaç verir).
abstract class NativeAdHandle {
  /// Reklamı çizen widget (platform view).
  Widget build();

  /// Platform kaynağını serbest bırakır; bir kez çağrılır.
  void dispose();
}

/// Native reklam renkleri — tema token'larından çağıran verir.
class NativeAdStyle {
  const NativeAdStyle({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.ctaBackground,
    required this.ctaText,
    this.cornerRadius = 12,
  });

  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color ctaBackground;
  final Color ctaText;
  final double cornerRadius;

  NativeTemplateStyle toTemplateStyle() => NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: background,
        cornerRadius: cornerRadius,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: ctaText,
          backgroundColor: ctaBackground,
        ),
        primaryTextStyle: NativeTemplateTextStyle(textColor: primaryText),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: secondaryText),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: secondaryText),
      );
}

/// Reklam yüklenemedi ([code]: AdMob hata kodu; SDK dışı sebepte -1).
class NativeAdLoadException implements Exception {
  const NativeAdLoadException(this.code, [this.message = '']);
  final int code;
  final String message;

  @override
  String toString() => 'NativeAdLoadException($code, $message)';
}

class GoogleNativeAdHandle implements NativeAdHandle {
  GoogleNativeAdHandle(this.ad);
  final NativeAd ad;

  @override
  Widget build() => AdWidget(ad: ad);

  @override
  void dispose() => ad.dispose();
}
