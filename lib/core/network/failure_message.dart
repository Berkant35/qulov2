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
        _ => fallbackKey,
      };
}
