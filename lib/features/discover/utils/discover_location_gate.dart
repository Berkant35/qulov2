import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/providers/location_provider.dart';

/// Sunucuda konum yok: Discover 400 `PROFILE_INCOMPLETE` (cihazda konum olsa da
/// sunucuya yazılamamış olabilir). Discover bunu konum istem kartıyla gösterir —
/// "konum ver" ya da "şehir seç" (2.0.18 konumsuz yedek yol).
const discoverLocationMissingCode = 'PROFILE_INCOMPLETE';

bool isDiscoverLocationMissing(Object? error) =>
    error is ServerFailure && error.code == discoverLocationMissingCode;

/// Discover'ı kapatan konum hatası; yoksa null. Profilden gelen konum varken
/// izin eksikliği desteyi engellemez (sunucu kayıtlı konumu kullanır); sahte
/// konum her durumda engeller.
String? blockingLocationError(LocationState location) {
  final error = location.error;
  if (error == null) return null;
  if (location.lat == null || error == LocationErrors.mockDetected) return error;
  return null;
}

/// Konum bu geçişte kullanılabilir hale geldi mi (izin verildi, GPS geldi)?
///
/// `getCurrentLocation` önce hatayı silip yükleniyor durumuna geçer, sonra
/// konumu yazar; "önceki hatalı → sonraki hatasız" diye bakmak bu iki adımlı
/// geçişi kaçırıyordu ve istem kartından izin veren kullanıcının destesi
/// yüklenmiyordu.
bool locationBecameReady(LocationState? prev, LocationState next) {
  bool ready(LocationState s) => s.lat != null && s.error == null && !s.isLoading;
  return ready(next) && (prev == null || !ready(prev));
}
