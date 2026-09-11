/// Elmas islem sebebi (`diamond_transactions.reason`) -> ceviri anahtari.
/// Tek kaynak; elmas ekrani ve performans ekraninin gecmis satirlari buradan okur.
///
/// Sunucu sebepleri uc bicimde yazar (qulo-server `diamondService` cagrilari):
/// sabit (`IAP_PURCHASE`), ek almis (`POWER_USED:HALF`, `BADGE_GOLD`) ve
/// kucuk harfli (`chat_question_skip`, `buy_power_HINT`). Bilinmeyen sebep ham
/// kod yerine genel etikete duser — kullaniciya asla ic kod gosterilmez.
const diamondReasonKeys = [
  'reason_power_used',
  'reason_power_reward',
  'reason_question_reward',
  'reason_power_purchase',
  'reason_iap',
  'reason_referral',
  'reason_subscription',
  'reason_boost',
  'reason_profile_completion',
  'reason_badge',
  'reason_exchange',
  'reason_retention',
  'reason_other',
];

/// Sohbet sorusunda guc harcayan sebepler (`chat-question.service.ts`
/// `tryUseOrSpend`). Genis `CHAT_QUESTION_` oneki kullanilmaz: odul
/// sebepleri de ayni onekle basliyor.
const _chatQuestionSpendPrefixes = [
  'CHAT_QUESTION_POWER_',
  'CHAT_QUESTION_SKIP',
  'CHAT_QUESTION_RESCUE',
];

String diamondReasonKey(String reason) {
  final code = reason.split(':').first.toUpperCase();
  if (code == 'POWER_USED') return 'reason_power_used';
  if (code == 'POWER_REWARD' || code == 'CHAT_QUESTION_POWER_REWARD') {
    return 'reason_power_reward';
  }
  if (code == 'CHAT_QUESTION_REWARD') return 'reason_question_reward';
  if (_chatQuestionSpendPrefixes.any(code.startsWith)) return 'reason_power_used';
  if (code.startsWith('BUY_POWER_')) return 'reason_power_purchase';
  if (code.startsWith('BADGE_')) return 'reason_badge';
  if (code.startsWith('REFERRAL_')) return 'reason_referral';
  return switch (code) {
    'IAP_PURCHASE' => 'reason_iap',
    'SUBSCRIPTION_BONUS' => 'reason_subscription',
    'BOOST' => 'reason_boost',
    'PROFILE_COMPLETION' => 'reason_profile_completion',
    'EXCHANGE_GREEN_TO_PURPLE' => 'reason_exchange',
    'RETENTION_BONUS' => 'reason_retention',
    _ => 'reason_other',
  };
}

/// `diamond_transactions.type` (GREEN | PURPLE) -> ceviri anahtari.
String diamondTypeKey(String type) =>
    type.toUpperCase() == 'GREEN' ? 'green_diamonds' : 'purple_diamonds';
