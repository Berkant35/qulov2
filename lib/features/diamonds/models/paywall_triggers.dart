/// Paywall'un açıldığı "ihtiyaç anı" (analytics `trigger`, başlık seçimi).
///
/// Teklif bağlamsız anlarda (ör. kayıttan dakikalar sonraki ilk eşleşme)
/// değil, kullanıcı bir şeye ihtiyaç duyup karşılayamadığında açılır.
/// Yeni çağrı yerleri literal yerine buradaki sabiti kullanır.
abstract final class PaywallTriggers {
  /// Soru içi güç: mor bakiye yetersiz (403 `INSUFFICIENT_DIAMONDS`).
  static const String quizPower = 'quiz_power';

  /// Yanlış cevap sonrası kurtarma (SKIP/SKIP_ALL): bakiye yetersiz (403).
  static const String quizRescue = 'quiz_rescue';

  /// Günlük keşif/beğeni sınırı (403 `DAILY_LIMIT_EXCEEDED`).
  static const String swipeLimit = 'swipe_limit';

  /// Yeşil→mor dönüşüm: yeşil bakiye yetersiz (403 `INSUFFICIENT_DIAMONDS`).
  static const String exchangeConvert = 'exchange_convert';
}
