/// Konum istem kartının eylemi: sistem izni iste, uygulama ayarları ya da
/// telefonun konum ayarları.
enum LocationPromptAction { requestPermission, openAppSettings, openLocationSettings }

/// Discover konum istem kartının içeriği — hata koduna göre
/// `DiscoverLocationPromptMixin.promptFor` üretir.
class LocationPromptContent {
  const LocationPromptContent({
    required this.titleKey,
    required this.messageKey,
    required this.ctaKey,
    required this.action,
    this.isMock = false,
    this.offersCity = true,
  });

  final String titleKey;

  /// Sahte konum uyarısında açıklama yok — başlık yeterince açık.
  final String? messageKey;
  final String ctaKey;
  final LocationPromptAction action;
  final bool isMock;

  /// "Şehir seç" yedek yolu sunulur mu; sahte konumda hayır (önce sahte konum kapatılmalı).
  final bool offersCity;
}
