import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_session.dart';

const _ok = RedeemResult(
  redemption: Redemption(id: 'r1', status: RedemptionStatus.pending, brandKey: 'GRAB', countryCode: 'TH',
      currency: 'THB', faceValue: 50, rainbowPrice: 51),
  balance: 949,
);

void main() {
  test('anahtar oturum başına bir kez üretilir; tekrar denemede aynı anahtar + kaynak kart', () async {
    var n = 0;
    final session = RedeemSession(itemId: 'i1', sourceItemId: 'b1', newKey: () => 'key-${++n}');
    final keys = <String>[];
    Future<Result<RedeemResult>> call({required String itemId, required String idempotencyKey, String? sourceItemId}) async {
      keys.add(idempotencyKey);
      expect(itemId, 'i1');
      expect(sourceItemId, 'b1');
      return keys.length == 1 ? const Failure(NetworkFailure()) : const Success(_ok);
    }

    expect(await session.submit(call), isA<Failure<RedeemResult>>());
    expect(await session.submit(call), isA<Success<RedeemResult>>());
    expect(keys, ['key-1', 'key-1']);
  });

  test('istek sürerken ikinci gönderim null döner (tek uçuş); bitince tekrar serbest', () async {
    final gate = Completer<Result<RedeemResult>>();
    var calls = 0;
    Future<Result<RedeemResult>> call({required String itemId, required String idempotencyKey, String? sourceItemId}) {
      calls++;
      return gate.future;
    }

    final session = RedeemSession(itemId: 'i1', newKey: () => 'k');
    final first = session.submit(call);
    expect(session.inFlight, isTrue);
    expect(await session.submit(call), isNull);
    gate.complete(const Success(_ok));
    await first;
    expect(session.inFlight, isFalse);
    expect(calls, 1);
  });
}
