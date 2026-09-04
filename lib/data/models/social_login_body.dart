/// `/auth/social-login` govde haritasi — saf fonksiyon, test edilebilir.
/// Opsiyonel alanlar (name/surname/nonce) yalnizca doluysa haritaya eklenir;
/// `locale` her zaman zorunlu (I4 — sosyal giriste cihaz/uygulama dili artik
/// sunucuya gonderilir, register akisiyla ayni davranis).
Map<String, dynamic> buildSocialLoginBody({
  required String provider,
  required String idToken,
  String? name,
  String? surname,
  String? nonce,
  required String locale,
}) {
  return {
    'provider': provider,
    'id_token': idToken,
    if (name != null) 'name': name,
    if (surname != null) 'surname': surname,
    if (nonce != null) 'nonce': nonce,
    'locale': locale,
  };
}
