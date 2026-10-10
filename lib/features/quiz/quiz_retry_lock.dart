import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';

/// Başarısız quiz'in hedefi kilitliyken (qulo-server 25b96d3, `quiz-retry.service`)
/// LIKE / quiz başlatma / geri alma 409 `QUIZ_RETRY_LOCKED` döner,
/// params `{reason: cooldown|exhausted|disabled, retry_at}`. Hedef 7 gün sonra
/// Discover'a bir kez geri döner; hak bitince bir daha gelmez.
const quizRetryLockedCode = 'QUIZ_RETRY_LOCKED';

/// Kilit hatasıysa kullanıcıya gösterilecek metin, değilse `null` (çağıran kendi
/// hata akışına devam eder). [now] test için.
String? quizRetryLockMessage(AppFailure failure, AppLocalizations l10n, {DateTime? now}) {
  if (failure is! ServerFailure || failure.code != quizRetryLockedCode) return null;
  final params = failure.params is Map ? failure.params as Map : const {};
  switch (params['reason']) {
    case 'exhausted':
      return l10n.get('quiz_retry_locked_exhausted');
    case 'cooldown':
      final retryAt = DateTime.tryParse('${params['retry_at']}');
      if (retryAt == null) break;
      return l10n.plural('quiz_retry_locked_cooldown', retryDaysLeft(retryAt, now ?? DateTime.now()));
  }
  return l10n.get('quiz_retry_locked_generic');
}

/// Kalan gün, yukarı yuvarlanır ("1,2 gün" → 2); en az 1 ("0 gün sonra" denmez).
int retryDaysLeft(DateTime retryAt, DateTime now) {
  final hours = retryAt.difference(now).inMinutes / 60;
  final days = (hours / 24).ceil();
  return days < 1 ? 1 : days;
}
