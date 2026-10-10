import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';

void main() {
  test('sunucu kodları → tür + parametreler', () {
    expect(classifyRedeemFailure(const ServerFailure(code: 'INSUFFICIENT_DIAMONDS')).kind, RedeemErrorKind.insufficient);
    final cap = classifyRedeemFailure(const ServerFailure(code: 'REWARD_MONTHLY_CAP', params: {'cap': 230, 'used': 220}));
    expect(cap.kind, RedeemErrorKind.monthlyCap);
    expect(cap.params, {'cap': 230, 'used': 220});
    final young = classifyRedeemFailure(const ServerFailure(code: 'REWARD_ACCOUNT_TOO_NEW', params: {'min_days': 7}));
    expect(young.params, {'min_days': 7});
    expect(classifyRedeemFailure(const ServerFailure(code: 'REWARD_ITEM_UNAVAILABLE')).kind, RedeemErrorKind.itemUnavailable);
    expect(classifyRedeemFailure(const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE')).kind, RedeemErrorKind.notAvailable);
    expect(classifyRedeemFailure(const ServerFailure(code: 'REWARD_ACCOUNT_PURGED')).kind, RedeemErrorKind.notAvailable);
    expect(classifyRedeemFailure(const ServerFailure(code: 'RATE_LIMITED')).kind, RedeemErrorKind.rateLimited);
    // İdempotency ara katmanı: aynı anahtarla ilk deneme hâlâ işleniyor (409) — hata değil, "işleniyor".
    final dup = classifyRedeemFailure(const ServerFailure(code: 'DUPLICATE_REQUEST', statusCode: 409));
    expect(dup.kind, RedeemErrorKind.processing);
    expect(dup.code, 'DUPLICATE_REQUEST');
    expect(redeemErrorKey(RedeemErrorKind.processing), 'market_redeem_processing');
    expect(classifyRedeemFailure(const NetworkFailure()).kind, RedeemErrorKind.network);
    expect(classifyRedeemFailure(const TimeoutFailure()).kind, RedeemErrorKind.timeout);
    final other = classifyRedeemFailure(const ServerFailure(code: 'SERVER_ERROR'));
    expect(other.kind, RedeemErrorKind.generic);
    expect(other.code, 'SERVER_ERROR');
    expect(classifyRedeemFailure(const UnknownFailure()).code, 'UNKNOWN');
  });

  test('bozuk params sessizce boş kalır', () {
    expect(classifyRedeemFailure(const ServerFailure(code: 'REWARD_MONTHLY_CAP', params: 'x')).params, isEmpty);
    expect(classifyRedeemFailure(const ServerFailure(code: 'REWARD_MONTHLY_CAP', params: {'cap': '230'})).params, isEmpty);
  });

  test('mesaj: anahtar + yer tutucular', () {
    String tr(String key) => switch (key) {
          'market_error_monthly_cap' => 'limit ({used}/{cap})',
          'market_error_account_too_new' => 'min {min_days} days',
          _ => key,
        };
    expect(redeemErrorMessage(const RedeemError(RedeemErrorKind.monthlyCap, code: 'C', params: {'cap': 230, 'used': 220}), tr),
        'limit (220/230)');
    expect(redeemErrorMessage(const RedeemError(RedeemErrorKind.accountTooNew, code: 'A', params: {'min_days': 7}), tr),
        'min 7 days');
    expect(redeemErrorMessage(const RedeemError(RedeemErrorKind.timeout, code: 'T'), tr), 'error_timeout');
  });

  test('403 EMAIL_VERIFICATION_REQUIRED → doğrulama türü (genel hata değil)', () {
    final e = classifyRedeemFailure(
        const ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED', statusCode: 403));
    expect(e.kind, RedeemErrorKind.emailVerificationRequired);
    expect(e.code, 'EMAIL_VERIFICATION_REQUIRED');
    expect(redeemErrorKey(e.kind), 'error_email_verification_required');
  });
}
