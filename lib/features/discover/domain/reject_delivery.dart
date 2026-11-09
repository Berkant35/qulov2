import 'package:qulo_v2/core/network/result.dart';

/// Günlük keşif hakkı bitti (qulo-server `subscription.service.incrementDailySwipes`).
/// Sunucu REJECT'i de hakka sayar; bu kodla dönen red KAYDEDİLMEMİŞTİR.
const dailyLimitExceededCode = 'DAILY_LIMIT_EXCEEDED';

/// Bir REJECT'in sunucuya teslim sonucu.
enum RejectDeliveryOutcome {
  /// Sunucu kaydı aldı.
  delivered,

  /// Günlük hak bitti: kayıt düşmedi, kart kullanıcıya geri verilmeli.
  limitExceeded,

  /// Ulaşmadı (yeniden denemeye rağmen) ya da kalıcı bir hatayla reddedildi.
  failed,
}

typedef RejectSend = Future<Result<Object?>> Function(String targetId);

/// Reddi gönderir; geçici hatada (ağ, zaman aşımı, 5xx) [retryDelay] sonra
/// bir kez yeniden dener. Bekleme sırasında red geri alındıysa
/// ([stillRejected] false) ikinci istek atılmaz.
class RejectDelivery {
  const RejectDelivery({required this.send, this.retryDelay = defaultRetryDelay});

  static const defaultRetryDelay = Duration(seconds: 2);

  final RejectSend send;
  final Duration retryDelay;

  Future<RejectDeliveryOutcome> deliver(
    String targetId, {
    required bool Function() stillRejected,
  }) async {
    var result = await send(targetId);
    if (_isTransient(result)) {
      await Future<void>.delayed(retryDelay);
      if (!stillRejected()) return RejectDeliveryOutcome.failed;
      result = await send(targetId);
    }
    return _classify(result);
  }

  static RejectDeliveryOutcome _classify(Result<Object?> result) => result.when(
        success: (_) => RejectDeliveryOutcome.delivered,
        failure: (f) => f is ServerFailure && f.code == dailyLimitExceededCode
            ? RejectDeliveryOutcome.limitExceeded
            : RejectDeliveryOutcome.failed,
      );

  static bool _isTransient(Result<Object?> result) => result.when(
        success: (_) => false,
        failure: (f) => switch (f) {
          NetworkFailure() || TimeoutFailure() => true,
          ServerFailure(:final statusCode) => statusCode == null || statusCode >= 500,
          _ => false,
        },
      );
}
