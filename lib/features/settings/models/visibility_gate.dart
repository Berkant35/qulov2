import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';

/// Bir profilin kimsenin Keşfet listesine girememesine yol açan kapılar.
///
/// NEDEN VAR: silme geri bildirimlerinde en büyük pay `few_matches` (%40) ve
/// bu kullanıcılar kayıttan **ortalama 36 dakika sonra** siliyor; `few_users_nearby`
/// diyenler 12 dakikada. Ortalamaları 2 soru + 1 fotoğraf — yani emek harcamış
/// ama görünmemiş olabilirler. Silmeden önce eksik kapıyı göstermek, çözülebilir
/// bir sorunu olan kullanıcıya tek şansını verir.
///
/// KAYNAK: `qulo-server/src/services/matching.service.ts`. Aday sorgusu
/// `lat`/`lng` dolu şartını koyuyor (satır 128-129), ardından 2'den az sorulu
/// (5.5) ve fotoğrafsız adaylar eleniyor. Konum kapısı çift yönlü:
/// `getDiscoverFeed` koordinatsız kullanıcı için `PROFILE_INCOMPLETE` fırlatıyor,
/// yani o kullanıcı hem görünmüyor hem de kimseyi göremiyor.
///
/// BURADA OLMAYAN KAPI 1 — e-posta doğrulama. Sunucu bunu aday sorgusunda arıyor
/// (`email_verified = true`), ama giriş yapmış bir kullanıcıda hiçbir zaman false
/// olamaz: `register` token döndürmüyor (`auth.service.ts:115`), `login`
/// doğrulanmamış kullanıcıyı `EMAIL_NOT_VERIFIED` ile reddediyor (satır 176-178),
/// sosyal giriş `email_verified: true` yazıyor (satır 490) ve alanı tekrar false'a
/// çeken bir yol yok. Ayarlar ekranına ulaşan kullanıcı tanımı gereği doğrulanmış,
/// dolayısıyla o kapı listede ölü bir satır olurdu.
///
/// BURADA OLMAYAN KAPI 2 — dil kuralı. Profil, ancak sorularından en az ikisi
/// karşı tarafın okuduğu dillerde yazılmışsa ona ulaşıyor (5.6, "always strict").
/// Bunu istemci doğrulayamaz: soruların dilleri `UserModel`'de yok ve kural karşı
/// tarafın tercihlerine bağlı. Bu yüzden madde değil — ve tam da dört kapıyı
/// geçmiş kullanıcı için en olası açıklama olduğundan, arayüzde **yalnızca
/// eksik kapı kalmadığında** ayrı bir not olarak gösteriliyor.
enum VisibilityGate {
  noLocation('visibility_gate_location'),
  tooFewQuestions('visibility_gate_questions'),
  noPhoto('visibility_gate_photo');

  const VisibilityGate(this.labelKey);

  /// UI etiketinin l10n anahtarı.
  final String labelKey;
}

/// Görünürlük sorununa işaret eden silme sebepleri.
///
/// Başka bir sebep seçen kullanıcının derdi görünürlük değil; ona kontrol listesi
/// göstermek alakasız olurdu.
const Set<DeletionReason> kVisibilityRelevantReasons = {
  DeletionReason.fewMatches,
  DeletionReason.fewUsersNearby,
};

/// Kullanıcının geçemediği kapılar, sunucudaki sırayla.
///
/// Boş liste "profil görünür" demektir.
List<VisibilityGate> missingVisibilityGates(UserModel user) {
  return [
    if (user.lat == null || user.lng == null) VisibilityGate.noLocation,
    if (user.questionCount < AppConstants.minQuestions)
      VisibilityGate.tooFewQuestions,
    if ((user.photos?.length ?? 0) < AppConstants.minPhotos)
      VisibilityGate.noPhoto,
  ];
}

/// Silme sebebi ve kullanıcıya göre gösterilecek kapılar.
///
/// Sebep görünürlükle ilgisizse ya da kullanıcı yüklenmemişse boş döner. Kural
/// widget'ta değil burada duruyor ki test edilebilsin.
List<VisibilityGate> gatesForDeletionReason(
  DeletionReason? reason,
  UserModel? user,
) {
  if (user == null || !kVisibilityRelevantReasons.contains(reason)) {
    return const [];
  }
  return missingVisibilityGates(user);
}

/// Kapıların hepsi geçilmişken dil kuralını anlatan not gösterilmeli mi.
///
/// Profil görünür ama kullanıcı yine de eşleşme almıyorsa, geriye kalan tek
/// sistematik açıklama dil filtresi. Eksik kapısı olana bunu söylemek gürültü —
/// onun sorunu zaten listede.
bool shouldShowLanguageNote(DeletionReason? reason, UserModel? user) {
  if (user == null || !kVisibilityRelevantReasons.contains(reason)) return false;
  return missingVisibilityGates(user).isEmpty;
}
