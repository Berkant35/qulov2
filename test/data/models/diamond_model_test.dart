import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

/// Elmas bakiyesi ve islem gecmisi. Sozlesme qulo-server `diamond.service.ts`:
/// bakiye `{green, purple}`; gecmis `{items, total, page, limit}`, satirlar
/// `diamond_transactions`'tan birebir (`id, user_id, type, amount, reason,
/// reference_id, created_at`).
///
/// Canli sema (2026-09-11): `reference_id` disindaki tum kolonlar NOT NULL;
/// prod'da 292 satirda null yok. Ornek degerler prod'daki gercek degerlerdir:
/// `type` ∈ {GREEN, PURPLE}, harcamada `amount` negatif, `reason` hem
/// `POWER_USED:<guc>` birlesik bicimde hem de kucuk harfli gelebiliyor.
Map<String, dynamic> _row({
  String type = 'PURPLE',
  int amount = -23,
  String reason = 'POWER_USED:HALF',
  String? referenceId = 'session-1',
  bool includeReference = true,
}) =>
    {
      'id': 'tx-1',
      'user_id': 'u1',
      'type': type,
      'amount': amount,
      'reason': reason,
      if (includeReference) 'reference_id': referenceId,
      'created_at': '2026-09-10T18:22:04.123+00:00',
    };

void main() {
  group('DiamondBalance', () {
    test('sunucu bakiyesi parse edilir', () {
      expect(DiamondBalance.fromJson({'green': 7, 'purple': 120}),
          const DiamondBalance(green: 7, purple: 120));
    });

    test('toJson → fromJson ayni bakiyeyi verir', () {
      const balance = DiamondBalance(green: 3, purple: 0);

      expect(DiamondBalance.fromJson(balance.toJson()), balance);
    });
  });

  group('DiamondTransaction', () {
    test('harcama satiri negatif tutarla parse edilir', () {
      final tx = DiamondTransaction.fromJson(_row());

      expect(tx.type, 'PURPLE');
      expect(tx.amount, -23);
      expect(tx.reason, 'POWER_USED:HALF');
      expect(tx.referenceId, 'session-1');
      expect(tx.createdAt, '2026-09-10T18:22:04.123+00:00');
    });

    test('kazanc satiri pozitif tutarla parse edilir', () {
      final tx = DiamondTransaction.fromJson(
        _row(type: 'GREEN', amount: 4, reason: 'POWER_REWARD:HALF'),
      );

      expect((tx.type, tx.amount), ('GREEN', 4));
    });

    test('reference_id null ya da eksik olabilir (tek nullable kolon)', () {
      final nullRef = DiamondTransaction.fromJson(_row(reason: 'IAP_PURCHASE', referenceId: null));
      final missingRef =
          DiamondTransaction.fromJson(_row(reason: 'PROFILE_COMPLETION', includeReference: false));

      expect(nullRef.referenceId, isNull);
      expect(missingRef.referenceId, isNull);
    });

    test('reason oldugu gibi tasinir — model normalize etmez', () {
      // Prod'da `chat_question_power_block` kucuk harfli; esleme ekranin isi.
      final tx = DiamondTransaction.fromJson(_row(reason: 'chat_question_power_block'));

      expect(tx.reason, 'chat_question_power_block');
    });
  });

  group('DiamondHistoryResponse', () {
    test('sayfali gecmis parse edilir', () {
      final r = DiamondHistoryResponse.fromJson({
        'items': [_row(), _row(type: 'GREEN', amount: 2, reason: 'POWER_REWARD:ORACLE')],
        'total': 41,
        'page': 2,
        'limit': 20,
      });

      expect(r.items, hasLength(2));
      expect((r.total, r.page, r.limit), (41, 2, 20));
    });

    test('bos gecmis basarili yanittir (sunucu `data ?? []` doner)', () {
      final r = DiamondHistoryResponse.fromJson({
        'items': <dynamic>[],
        'total': 0,
        'page': 1,
        'limit': 20,
      });

      expect(r.items, isEmpty);
      expect(r.total, 0);
    });
  });
}
