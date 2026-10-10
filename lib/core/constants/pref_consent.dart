/// Eşleşme tercihi açık rızası (KVKK m.6) — sunucu `PUT /users/me/pref-consent`.
abstract final class PrefConsent {
  /// Onaylanan aydınlatma metninin sürümü; web gizlilik metni değişince artırılır
  /// (sunucu `user_consents.version`'a yazar).
  static const version = '2026-10-v1';
  static const granted = 'GRANTED';
  static const declined = 'DECLINED';
}
