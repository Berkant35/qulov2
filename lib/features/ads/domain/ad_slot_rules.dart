import 'package:qulo_v2/features/ads/domain/ad_audience.dart';

/// Reklam yuvası sabitleri — tek yer.
abstract final class AdSlotConstants {
  /// Her bu kadar profil kartından sonra bir reklam yuvası.
  static const int profilesPerSlot = 5;

  /// İlk reklam, bu kadar profil geçilmeden asla çıkmaz.
  static const int minProfilesBeforeFirstAd = 4;

  /// Oturum başına gösterilebilecek en çok reklam.
  static const int maxAdsPerSession = 6;

  /// Yuvadan bu kadar profil önce reklam yüklemeye başlanır.
  static const int preloadLeadProfiles = 2;
}

/// Reklam yuvası kuralları (saf Dart: Flutter/paket yok).
///
/// `slotsResolved`: şimdiye dek karara bağlanan yuva sayısı (gösterilen + yükleme
/// başarısızlığından atlanan). `adsShown` yalnız gösterilenler (üst sınır için).
class AdSlotRules {
  const AdSlotRules({
    this.profilesPerSlot = AdSlotConstants.profilesPerSlot,
    this.minProfilesBeforeFirstAd = AdSlotConstants.minProfilesBeforeFirstAd,
    this.maxAdsPerSession = AdSlotConstants.maxAdsPerSession,
    this.preloadLeadProfiles = AdSlotConstants.preloadLeadProfiles,
  });

  final int profilesPerSlot;
  final int minProfilesBeforeFirstAd;
  final int maxAdsPerSession;
  final int preloadLeadProfiles;

  /// Reklam isteği atmaya / göstermeye izin: yalnız doğrulanmış ücretsiz kullanıcı
  /// ve uzaktan anahtar açıkken. VIP ve bilinmeyen durumda ASLA.
  bool mayServe({required AdAudience audience, required bool remoteEnabled}) =>
      remoteEnabled && audience == AdAudience.free;

  /// [slotIndex]. yuvanın (0 tabanlı) açıldığı geçilmiş-profil sayısı.
  int thresholdFor(int slotIndex) {
    final first =
        profilesPerSlot < minProfilesBeforeFirstAd ? minProfilesBeforeFirstAd : profilesPerSlot;
    return first + slotIndex * profilesPerSlot;
  }

  /// Sıradaki yuva geldi mi. Bir sonraki profil kartı yoksa (`hasNextCard`
  /// false) reklam çıkmaz: boş/biten desteye reklam konmaz.
  bool isSlotDue({
    required int profilesPassed,
    required int slotsResolved,
    required int adsShown,
    required bool hasNextCard,
  }) {
    if (!hasNextCard || adsShown >= maxAdsPerSession) return false;
    return profilesPassed >= thresholdFor(slotsResolved);
  }

  /// Yuva yaklaşırken (ama henüz gelmemişken) reklamı önceden yükle.
  bool shouldPreload({
    required int profilesPassed,
    required int slotsResolved,
    required int adsShown,
  }) {
    if (adsShown >= maxAdsPerSession) return false;
    return profilesPassed >= thresholdFor(slotsResolved) - preloadLeadProfiles;
  }
}
