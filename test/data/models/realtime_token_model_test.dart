import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';

void main() {
  group('RealtimeToken.tryParse', () {
    test('geçerli yanıt: token + UTC bitiş', () {
      final t = RealtimeToken.tryParse({'token': 'jwt', 'expiresAt': '2026-11-09T13:00:00.000Z'});

      expect(t!.token, 'jwt');
      expect(t.expiresAt.isUtc, isTrue);
      expect(t.expiresAt, DateTime.utc(2026, 11, 9, 13));
    });

    for (final (name, json) in <(String, Object?)>[
      ('null gövde', null),
      ('liste gövde', <Object>[]),
      ('token yok', {'expiresAt': '2026-11-09T13:00:00.000Z'}),
      ('boş token', {'token': '  ', 'expiresAt': '2026-11-09T13:00:00.000Z'}),
      ('bitiş yok', {'token': 'jwt'}),
      ('bozuk bitiş', {'token': 'jwt', 'expiresAt': 'yarin'}),
      ('bitiş sayı', {'token': 'jwt', 'expiresAt': 1762693200}),
    ]) {
      test('$name → null (çökmez)', () => expect(RealtimeToken.tryParse(json), isNull));
    }
  });

  test('remaining: yerel saatle verilen "şimdi" de UTC bitişle doğru karşılaştırılır', () {
    final t = RealtimeToken(token: 'jwt', expiresAt: DateTime.utc(2026, 11, 9, 13));

    expect(t.remaining(DateTime.utc(2026, 11, 9, 12, 50)), const Duration(minutes: 10));
    expect(t.remaining(DateTime.utc(2026, 11, 9, 12, 50).toLocal()), const Duration(minutes: 10));
    expect(t.remaining(DateTime.utc(2026, 11, 9, 13, 1)).isNegative, isTrue);
  });
}
