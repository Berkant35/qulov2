import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/realtime_auth_manager.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';

/// Realtime kullanıcı JWT'si (2.0.18 P0, sözleşme `tasks/surum-2.0.18-sozlesmeler.md`):
/// abone olmadan önce al, bitişten 2 dk önce yenile, arka planda durdur, öne gelişte
/// 3 dk'dan az kaldıysa yenileyip yeniden abone ettir; alınamazsa anon sür; çıkışta temizle.
///
/// Zaman: `testWidgets`'in sahte saati (`tester.binding.clock`) — `fake_async`
/// doğrudan bağımlılık değil, pubspec'e eklememek için.

const _unavailable = Failure<RealtimeToken>(
  ServerFailure(code: 'REALTIME_TOKEN_UNAVAILABLE', statusCode: 503),
);
const _offline = Failure<RealtimeToken>(NetworkFailure());

class _FakeTarget implements RealtimeAuthTarget {
  final applied = <String>[];
  int anon = 0;
  int resets = 0;

  @override
  Future<void> apply(String token) async => applied.add(token);

  @override
  Future<void> useAnon() async => anon++;

  @override
  Future<void> reset() async => resets++;
}

/// Sunucu: sıradaki yanıt [next] ile belirlenir; varsayılan her çağrıda 10 dk'lık yeni token.
class _FakeIssuer {
  _FakeIssuer(this.now);

  final DateTime Function() now;
  int calls = 0;
  Result<RealtimeToken>? next;
  Completer<void>? gate;

  Future<Result<RealtimeToken>> call() async {
    calls++;
    await gate?.future;
    return next ??
        Success(RealtimeToken(token: 'jwt-$calls', expiresAt: now().add(const Duration(minutes: 10))));
  }
}

class _Harness {
  _Harness(this.tester) {
    issuer = _FakeIssuer(now);
    manager = RealtimeAuthManager(issueToken: issuer.call, target: target, now: now);
    manager.resubscribeRequests.listen((_) => resubscribes++);
  }

  final WidgetTester tester;
  final target = _FakeTarget();
  late final _FakeIssuer issuer;
  late final RealtimeAuthManager manager;
  int resubscribes = 0;

  DateTime now() => tester.binding.clock.now().toUtc();

  Future<void> ensure([String userId = 'u1']) => manager.ensureFresh(userId: userId);

  /// Yayın akışı olayı mikro görevde teslim eder: sayaç için bir kare ilerletilir.
  Future<void> foreground() async {
    await manager.onForeground();
    await tester.pump();
  }

  Future<void> wait(Duration d) => tester.pump(d);
}

/// Sahte saatli test: yönetici gövde bitince kapatılır (bekleyen zamanlayıcı kalmaz).
void _test(String description, Future<void> Function(_Harness h) body) {
  testWidgets(description, (tester) async {
    final h = _Harness(tester);
    await body(h);
    h.manager.dispose();
  });
}

void main() {
  group('token alma', () {
    _test('abone olmadan önce token alınır ve bağlantıya uygulanır', (h) async {

      await h.ensure();

      expect(h.issuer.calls, 1);
      expect(h.target.applied, ['jwt-1']);
      expect(h.manager.currentToken, 'jwt-1');
    });

    _test('taze token varken ikinci abonelik sunucuya gitmez', (h) async {
      await h.ensure();

      await h.wait(const Duration(minutes: 5));
      await h.ensure();

      expect(h.issuer.calls, 1);
    });

    _test('aynı anda iki sahip (liste + sohbet) tek istekte birleşir', (h) async {
      h.issuer.gate = Completer<void>();

      final a = h.ensure();
      final b = h.ensure();
      h.issuer.gate!.complete();
      await Future.wait([a, b]);

      expect(h.issuer.calls, 1);
      expect(h.target.applied, ['jwt-1']);
    });
  });

  group('yenileme zamanlaması (ön planda)', () {
    _test('bitişten 2 dk önce yenilenir; öncesinde yenilenmez', (h) async {
      await h.ensure();

      await h.wait(const Duration(minutes: 7, seconds: 59));
      expect(h.issuer.calls, 1);

      await h.wait(const Duration(seconds: 1));
      expect(h.issuer.calls, 2);
      expect(h.target.applied, ['jwt-1', 'jwt-2']);
    });

    _test('zamanlayıcıyla yenileme kanalları düşürmez (yeniden abone istenmez)', (h) async {
      await h.ensure();

      await h.wait(const Duration(minutes: 8));

      expect(h.issuer.calls, 2);
      expect(h.resubscribes, 0, reason: 'setAuth açık kanallara access_token iter');
    });

    _test('her yenileme bir sonrakini kurar (uzun oturum)', (h) async {
      await h.ensure();

      for (var i = 0; i < 3; i++) {
        await h.wait(const Duration(minutes: 8));
      }

      expect(h.issuer.calls, 4);
      expect(h.manager.hasScheduledRefresh, isTrue);
    });
  });

  group('503 / ağ hatası → anon bağlantıyla devam', () {
    _test('503: token yok, istisna yok, uygulanan bir şey yok', (h) async {
      h.issuer.next = _unavailable;

      await h.ensure();

      expect(h.manager.currentToken, isNull);
      expect(h.target.applied, isEmpty);
      expect(h.target.anon, 0, reason: 'bağlantı zaten anon');
      expect(h.manager.hasScheduledRefresh, isFalse);
    });

    _test('başarısızlıktan sonra 1 dk içinde abonelik yolları tekrar istemez (sınır dakikada 10)',
        (h) async {
      h.issuer.next = _unavailable;
      await h.ensure();

      await h.wait(const Duration(seconds: 59));
      await h.ensure();
      expect(h.issuer.calls, 1);

      await h.wait(const Duration(seconds: 1));
      h.issuer.next = null;
      await h.ensure();
      expect(h.issuer.calls, 2);
      expect(h.manager.currentToken, 'jwt-2');
    });

    _test('öne gelişte bekleme yok: 503 sonrası tekrar denenir, alınınca yeniden abone ettirilir',
        (h) async {
      h.issuer.next = _unavailable;
      await h.ensure();
      h.manager.onBackground();
      h.issuer.next = null;

      await h.foreground();

      expect(h.issuer.calls, 2);
      expect(h.manager.currentToken, 'jwt-2');
      expect(h.resubscribes, 1);
    });

    _test('öne gelişte yine 503: anonda kalınır, gereksiz yeniden abonelik yok', (h) async {
      h.issuer.next = _unavailable;
      await h.ensure();

      await h.foreground();

      expect(h.issuer.calls, 2);
      expect(h.resubscribes, 0);
    });

    _test('yenileme ağ hatası verirse geçerli token korunur, bitmeden bir kez daha denenir',
        (h) async {
      await h.ensure();
      h.issuer.next = _offline;

      await h.wait(const Duration(minutes: 8)); // planlı yenileme: hata
      expect(h.issuer.calls, 2);
      expect(h.manager.currentToken, 'jwt-1');
      expect(h.target.anon, 0);

      h.issuer.next = null;
      await h.wait(const Duration(minutes: 1)); // tekrar deneme
      expect(h.issuer.calls, 3);
      expect(h.manager.currentToken, 'jwt-3');
    });

    _test('token bitene kadar alınamazsa anon anahtara dönülür', (h) async {
      await h.ensure();
      h.issuer.next = _offline;

      await h.wait(const Duration(minutes: 8)); // planlı yenileme: hata
      await h.wait(const Duration(minutes: 1)); // tekrar: hata, 1 dk kaldı
      expect(h.manager.currentToken, 'jwt-1');
      await h.wait(const Duration(minutes: 1)); // bitiş anında son deneme: hata

      expect(h.issuer.calls, 4);
      expect(h.manager.currentToken, isNull);
      expect(h.target.anon, 1);
    });
  });

  group('arka plan / öne geliş', () {
    _test('arka planda zamanlayıcı durur: yenileme yapılmaz', (h) async {
      await h.ensure();

      h.manager.onBackground();
      await h.wait(const Duration(minutes: 30));

      expect(h.issuer.calls, 1);
      expect(h.manager.hasScheduledRefresh, isFalse);
    });

    _test('öne gelişte 3 dk\'dan az kaldıysa önce yenile, sonra yeniden abone ettir', (h) async {
      await h.ensure();
      h.manager.onBackground();
      await h.wait(const Duration(minutes: 7, seconds: 30)); // 2,5 dk kaldı

      await h.foreground();

      expect(h.issuer.calls, 2);
      expect(h.target.applied.last, 'jwt-2');
      expect(h.resubscribes, 1);
    });

    _test('öne gelişte süresi geçmişse yenilenir ve yeniden abone ettirilir (kanallar kapanmıştı)',
        (h) async {
      await h.ensure();
      h.manager.onBackground();
      await h.wait(const Duration(hours: 2));

      await h.foreground();

      expect(h.manager.currentToken, 'jwt-2');
      expect(h.resubscribes, 1);
    });

    _test('öne gelişte yeterince süre varsa istek yok, zamanlayıcı yeniden kurulur', (h) async {
      await h.ensure();
      h.manager.onBackground();
      await h.wait(const Duration(minutes: 5));

      await h.foreground();
      expect(h.issuer.calls, 1);
      expect(h.resubscribes, 0);
      expect(h.manager.hasScheduledRefresh, isTrue);

      await h.wait(const Duration(minutes: 3)); // bitişten 2 dk önce
      expect(h.issuer.calls, 2);
    });

    _test('girişsiz (hiç abone olunmamış) öne geliş istek atmaz', (h) async {

      await h.foreground();

      expect(h.issuer.calls, 0);
    });
  });

  group('çıkış ve hesap değişimi', () {
    _test('clear: token bellekten atılır, kanallar kapatılıp anon\'a dönülür, zamanlayıcı durur',
        (h) async {
      await h.ensure();

      await h.manager.clear();
      await h.wait(const Duration(minutes: 30));

      expect(h.manager.currentToken, isNull);
      expect(h.target.resets, 1);
      expect(h.issuer.calls, 1, reason: 'çıkıştan sonra planlı yenileme yok');
    });

    _test('çıkıştan sonra öne geliş eski kullanıcı için token istemez', (h) async {
      await h.ensure();
      await h.manager.clear();

      await h.foreground();

      expect(h.issuer.calls, 1);
    });

    _test('istek sürerken çıkış yapılırsa gelen token uygulanmaz (sonraki kullanıcıya eski sub kalmaz)',
        (h) async {
      h.issuer.gate = Completer<void>();
      final pending = h.ensure();

      await h.manager.clear();
      h.issuer.gate!.complete();
      await pending;

      expect(h.target.applied, isEmpty);
      expect(h.manager.currentToken, isNull);
      expect(h.manager.hasScheduledRefresh, isFalse);
    });

    _test('başka kullanıcıyla abonelik: önce eski token ve kanallar temizlenir, yeni token alınır',
        (h) async {
      await h.ensure('u1');

      await h.ensure('u2');

      expect(h.target.resets, 1);
      expect(h.issuer.calls, 2);
      expect(h.manager.currentToken, 'jwt-2');
    });
  });
}
