import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/quiz/quiz_retry_lock.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_error_view.dart';

/// 409 QUIZ_RETRY_LOCKED (qulo-server 25b96d3): başarısız quiz'in hedefi
/// kilitliyken LIKE / quiz başlatma / geri alma genel hata yerine ne zaman
/// tekrar denenebileceğini söyler.
void main() {
  final en = AppLocalizations(const Locale('en'));
  final tr = AppLocalizations(const Locale('tr'));
  final now = DateTime.utc(2026, 10, 4, 12);

  ServerFailure locked(Map<String, Object?> params) =>
      ServerFailure(code: quizRetryLockedCode, statusCode: 409, params: params);

  test('cooldown: retry_at\'ten kalan gün (çoğul)', () {
    final f = locked({'reason': 'cooldown', 'retry_at': '2026-10-09T12:00:00.000Z'});

    expect(quizRetryLockMessage(f, en, now: now), 'You can try this profile again in 5 days');
    expect(quizRetryLockMessage(f, tr, now: now), 'Bu profili 5 gün sonra tekrar deneyebilirsin');
  });

  test('cooldown: son gün tekil, kısmi gün yukarı yuvarlanır', () {
    final f = locked({'reason': 'cooldown', 'retry_at': '2026-10-04T15:00:00.000Z'});
    expect(quizRetryLockMessage(f, en, now: now), 'You can try this profile again in 1 day');
    expect(retryDaysLeft(DateTime.utc(2026, 10, 5, 18), now), 2);
    expect(retryDaysLeft(DateTime.utc(2026, 10, 1), now), 1, reason: '"0 gün sonra" denmez');
  });

  test('exhausted: hak kalmadı', () {
    expect(quizRetryLockMessage(locked({'reason': 'exhausted', 'retry_at': null}), en, now: now),
        en.get('quiz_retry_locked_exhausted'));
  });

  test('disabled / retry_at bozuk / params yok → genel kilit metni', () {
    final generic = en.get('quiz_retry_locked_generic');
    expect(quizRetryLockMessage(locked({'reason': 'disabled', 'retry_at': null}), en), generic);
    expect(quizRetryLockMessage(locked({'reason': 'cooldown', 'retry_at': 'x'}), en), generic);
    expect(quizRetryLockMessage(const ServerFailure(code: quizRetryLockedCode), en), generic);
  });

  test('başka hata → null (çağıranın kendi akışı)', () {
    expect(quizRetryLockMessage(const ServerFailure(code: 'DAILY_LIMIT_EXCEEDED'), en), isNull);
    expect(quizRetryLockMessage(const NetworkFailure(), en), isNull);
  });

  test('quiz başlatma ekranı: kilit metni, soru yok, genel', () {
    expect(quizStartErrorMessage(locked({'reason': 'exhausted'}), en),
        en.get('quiz_retry_locked_exhausted'));
    expect(quizStartErrorMessage(const ServerFailure(code: 'NO_QUESTIONS'), en),
        en.get('quiz_no_questions'));
    expect(quizStartErrorMessage(const NetworkFailure(), en), en.get('quiz_start_error'));
  });

  test('quiz başlatma: erişilemeyen profil (404 USER_NOT_FOUND / eski 403 NOT_COMPATIBLE) → "profil kullanılamıyor"', () {
    for (final code in ['USER_NOT_FOUND', 'NOT_COMPATIBLE']) {
      expect(quizStartErrorMessage(ServerFailure(code: code), en), en.get('error_not_compatible'), reason: code);
    }
  });
}
