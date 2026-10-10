import 'package:qulo_v2/core/network/result.dart';

/// İtfa hatası türleri (spec §7.4 hata eşlemesi).
enum RedeemErrorKind {
  insufficient,
  monthlyCap,
  accountTooNew,
  itemUnavailable,
  notAvailable,

  /// 409 `DUPLICATE_REQUEST`: aynı anahtarla ilk deneme sunucuda hâlâ işleniyor (idempotency).
  processing,
  rateLimited,

  /// 403 `EMAIL_VERIFICATION_REQUIRED`: e-posta doğrulanmadan itfa yok — sayfa doğrulama ister.
  emailVerificationRequired,
  network,
  timeout,
  generic,
}

class RedeemError {
  const RedeemError(this.kind, {required this.code, this.params = const {}});

  final RedeemErrorKind kind;

  /// GA4 `error_code` parametresi (sunucu kodu ya da NETWORK/TIMEOUT/UNKNOWN).
  final String code;

  /// Metin yer tutucuları (`cap`, `used`, `min_days`).
  final Map<String, int> params;
}

RedeemError classifyRedeemFailure(AppFailure failure) => switch (failure) {
      NetworkFailure() => const RedeemError(RedeemErrorKind.network, code: 'NETWORK'),
      TimeoutFailure() => const RedeemError(RedeemErrorKind.timeout, code: 'TIMEOUT'),
      ServerFailure(code: 'INSUFFICIENT_DIAMONDS') =>
        const RedeemError(RedeemErrorKind.insufficient, code: 'INSUFFICIENT_DIAMONDS'),
      ServerFailure(code: 'REWARD_MONTHLY_CAP', :final params) => RedeemError(RedeemErrorKind.monthlyCap,
          code: 'REWARD_MONTHLY_CAP', params: _ints(params, const ['cap', 'used'])),
      ServerFailure(code: 'REWARD_ACCOUNT_TOO_NEW', :final params) => RedeemError(RedeemErrorKind.accountTooNew,
          code: 'REWARD_ACCOUNT_TOO_NEW', params: _ints(params, const ['min_days'])),
      ServerFailure(code: 'REWARD_ITEM_UNAVAILABLE') =>
        const RedeemError(RedeemErrorKind.itemUnavailable, code: 'REWARD_ITEM_UNAVAILABLE'),
      ServerFailure(code: final code) when code == 'RAINBOW_NOT_AVAILABLE' || code == 'REWARD_ACCOUNT_PURGED' =>
        RedeemError(RedeemErrorKind.notAvailable, code: code),
      ServerFailure(code: 'DUPLICATE_REQUEST') =>
        const RedeemError(RedeemErrorKind.processing, code: 'DUPLICATE_REQUEST'),
      ServerFailure(code: 'RATE_LIMITED') => const RedeemError(RedeemErrorKind.rateLimited, code: 'RATE_LIMITED'),
      ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED') =>
        const RedeemError(RedeemErrorKind.emailVerificationRequired, code: 'EMAIL_VERIFICATION_REQUIRED'),
      ServerFailure(:final code) => RedeemError(RedeemErrorKind.generic, code: code),
      _ => const RedeemError(RedeemErrorKind.generic, code: 'UNKNOWN'),
    };

Map<String, int> _ints(Object? params, List<String> keys) {
  if (params is! Map) return const {};
  return {
    for (final key in keys)
      if (params[key] is num) key: (params[key] as num).toInt(),
  };
}

/// Tür → çeviri anahtarı (dinamik anahtar testi `RedeemErrorKind.values` üzerinden).
String redeemErrorKey(RedeemErrorKind kind) => switch (kind) {
      RedeemErrorKind.insufficient => 'market_error_insufficient',
      RedeemErrorKind.monthlyCap => 'market_error_monthly_cap',
      RedeemErrorKind.accountTooNew => 'market_error_account_too_new',
      RedeemErrorKind.itemUnavailable => 'market_error_item_unavailable',
      RedeemErrorKind.notAvailable => 'rainbow_not_available',
      RedeemErrorKind.processing => 'market_redeem_processing',
      RedeemErrorKind.rateLimited => 'error_rate_limited',
      RedeemErrorKind.emailVerificationRequired => 'error_email_verification_required',
      RedeemErrorKind.network => 'error_no_connection',
      RedeemErrorKind.timeout => 'error_timeout',
      RedeemErrorKind.generic => 'market_error_generic',
    };

/// Çeviri + yer tutucu doldurma (çeviri fonksiyonu dışarıdan: saf, test edilebilir).
String redeemErrorMessage(RedeemError error, String Function(String key) tr) {
  var text = tr(redeemErrorKey(error.kind));
  error.params.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  return text;
}
