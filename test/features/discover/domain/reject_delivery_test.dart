import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/discover/domain/reject_delivery.dart';

/// REJECT teslimi: sunucu REJECT'i günlük hakka sayar (403 DAILY_LIMIT_EXCEEDED
/// = kayıt yok, kart geri verilmeli); geçici hatada tek yeniden deneme.
void main() {
  const ok = Success<Object?>(null);
  const limit = Failure<Object?>(ServerFailure(code: dailyLimitExceededCode, statusCode: 403));
  const offline = Failure<Object?>(NetworkFailure());
  const timeout = Failure<Object?>(TimeoutFailure());
  const internal = Failure<Object?>(ServerFailure(code: 'INTERNAL', statusCode: 500));
  const notCompatible = Failure<Object?>(ServerFailure(code: 'USER_NOT_FOUND', statusCode: 404));

  /// Yanıtları sırayla verir; son yanıt tekrar eder.
  ({RejectDelivery delivery, List<String> calls}) scripted(List<Result<Object?>> replies) {
    final calls = <String>[];
    final delivery = RejectDelivery(
      retryDelay: Duration.zero,
      send: (id) async {
        calls.add(id);
        return replies[(calls.length - 1).clamp(0, replies.length - 1)];
      },
    );
    return (delivery: delivery, calls: calls);
  }

  Future<RejectDeliveryOutcome> run(RejectDelivery d, {bool stillRejected = true}) =>
      d.deliver('u1', stillRejected: () => stillRejected);

  test('basari: tek istek, delivered', () async {
    final s = scripted([ok]);
    expect(await run(s.delivery), RejectDeliveryOutcome.delivered);
    expect(s.calls, ['u1']);
  });

  test('gunluk hak 403: yeniden denenmez, limitExceeded', () async {
    final s = scripted([limit]);
    expect(await run(s.delivery), RejectDeliveryOutcome.limitExceeded);
    expect(s.calls, hasLength(1));
  });

  for (final (name, transient) in [('ag', offline), ('zaman asimi', timeout), ('5xx', internal)]) {
    test('$name hatasi: bir kez yeniden dener, basarirsa delivered', () async {
      final s = scripted([transient, ok]);
      expect(await run(s.delivery), RejectDeliveryOutcome.delivered);
      expect(s.calls, hasLength(2));
    });
  }

  test('yeniden deneme de basarisizsa failed; ucuncu istek yok', () async {
    final s = scripted([offline, internal, ok]);
    expect(await run(s.delivery), RejectDeliveryOutcome.failed);
    expect(s.calls, hasLength(2));
  });

  test('yeniden deneme gunluk hakka takilirsa limitExceeded', () async {
    final s = scripted([offline, limit]);
    expect(await run(s.delivery), RejectDeliveryOutcome.limitExceeded);
  });

  test('uyumsuz kart (404): kalici hata, yeniden denenmez', () async {
    final s = scripted([notCompatible]);
    expect(await run(s.delivery), RejectDeliveryOutcome.failed);
    expect(s.calls, hasLength(1));
  });

  test('beklerken red geri alindiysa ikinci istek atilmaz', () async {
    final s = scripted([offline, ok]);
    expect(await run(s.delivery, stillRejected: false), RejectDeliveryOutcome.failed);
    expect(s.calls, hasLength(1));
  });
}
