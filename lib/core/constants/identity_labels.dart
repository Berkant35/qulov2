/// Kimlik & yönelim etiket kataloğu (spec 2026-10-06 §1) — sunucu
/// `src/constants/identity-labels.ts` ile aynı anahtarlar ve sıra. Yalnız profil bilgisi;
/// eşleşmeye etkisi yok.
abstract final class IdentityLabels {
  static const gender = [
    'cis_woman', 'cis_man', 'trans_woman', 'trans_man', 'non_binary', 'genderqueer', 'genderfluid',
    'agender', 'bigender', 'intersex', 'transfeminine', 'transmasculine', 'questioning',
  ];
  static const orientation = [
    'straight', 'gay', 'lesbian', 'bisexual', 'pansexual', 'asexual', 'demisexual', 'queer',
    'questioning', 'heteroflexible', 'homoflexible',
  ];
  static const maxPerGroup = 3;

  /// `questioning` iki grupta da var — çeviri anahtarı gruba göre öneklidir.
  static String genderKey(String label) => 'identity_gender_$label';
  static String orientationKey(String label) => 'identity_orientation_$label';
}

/// Etiket açık rızası (KVKK m.6) — eşleşme tercihi rızasından ayrı amaç.
abstract final class IdentityConsent {
  static const version = '2026-10-v1';
}
