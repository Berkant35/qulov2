import 'package:qulo_v2/routing/route_names.dart';

/// Bos discover'daki pasaport ipucunun metni ve hedefi.
typedef PassportHintAction = ({String labelKey, String route});

/// Pasaport ipucunun sunum-disi logic'i.
///
/// Stateless widget oldugu icin `on` kisitsiz plain mixin (proje kurali:
/// widget yalnizca UI orchestration, calistirilan fonksiyonlar mixin'de).
mixin DiscoverPassportHintMixin {
  /// Para yolu: pasaport acik → sehir degistir, Premium → pasaportu kesfet,
  /// digerleri → abonelik. Pasaport sunucuda yalnizca Premium'da acilir
  /// (qulo-server passport.service.ts), bu yuzden Plus da aboneliğe gider.
  PassportHintAction passportHint({required bool passportActive, required bool isPremium}) {
    if (passportActive) return (labelKey: 'passport_change_city', route: RouteNames.passport);
    if (isPremium) return (labelKey: 'passport_explore_hint', route: RouteNames.passport);
    return (labelKey: 'passport_premium_explore_hint', route: RouteNames.subscription);
  }
}
