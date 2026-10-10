import 'package:qulo_v2/core/network/result.dart';

/// Kullaniciya gosterilecek hata metninin CEVIRI ANAHTARI.
///
/// `AppFailure.message` gelistirici metnidir, UI'da gosterilmez: sunucu hata
/// govdesinde `message` gondermez (qulo-server `errorHandler` ve rate limit
/// yalnizca `code` + `params` yazar), istemci tarafi varsayilanlar ise
/// Ingilizce sabittir (`NetworkFailure` → "No internet connection"). Eskiden
/// snackbar'lar `f.message ?? context.tr(...)` yazdigi icin ag koptugunda her
/// dilde Ingilizce metin gorunuyordu.
extension AppFailureMessageKey on AppFailure {
  String userMessageKey(String fallbackKey) => switch (this) {
        NetworkFailure() => 'error_no_connection',
        TimeoutFailure() => 'error_timeout',
        ServerFailure(code: 'RATE_LIMITED') => 'error_rate_limited',
        // Kapıyı ele almayan bir yol olursa bile genel hata yerine ne yapılacağı söylenir.
        ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED') => 'error_email_verification_required',
        ServerFailure(code: 'GENDER_PREF_LOCKED') => 'error_gender_pref_locked',
        ServerFailure(code: 'CONSENT_RELOCK') => 'error_consent_relock',
        // Erişilemeyen profil: eski sunucu 403 NOT_COMPATIBLE, yeni sunucu tek tip 404 USER_NOT_FOUND.
        ServerFailure(code: 'NOT_COMPATIBLE' || 'USER_NOT_FOUND') => 'error_not_compatible',
        ServerFailure(code: 'IDENTITY_CONSENT_REQUIRED') => 'error_identity_consent_required',
        ServerFailure(code: 'GENDER_LOCKED') => 'error_gender_locked',
        _ => fallbackKey,
      };
}
