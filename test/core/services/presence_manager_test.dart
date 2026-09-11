import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/services/presence_service.dart';
import 'package:qulo_v2/core/services/presence_manager.dart';

/// Cevrimici gostergesi. Baglanti (`app.dart`): resumed → start, paused/detached
/// → stop (cevrimdisi bildirir); `AuthNotifier.forceLogout` → pause (token
/// gecersizken cevrimdisi cagrisi yapilmaz), `logout` → stop.
///
/// Singleton — her testten once `init`, gövde sonunda `dispose()` (periyodik
/// timer testWidgets'in "bekleyen timer" kontrolunden ONCE kapanmali;
/// tearDown bu kontrolden sonra calisir). Zaman `tester.pump` ile ilerler.
void main() {
  late _FakePresenceService service;
  final manager = PresenceManager.instance;

  setUp(() {
    manager.dispose();
    service = _FakePresenceService();
    manager.init(service);
  });

  void presenceTest(String name, Future<void> Function(WidgetTester tester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        manager.dispose();
      }
    });
  }

  presenceTest('start: hemen bir heartbeat, sonra 60 sn\'de bir', (tester) async {
    manager.start();
    await tester.pump();
    expect(service.heartbeats, 1);

    await tester.pump(const Duration(seconds: 60));
    expect(service.heartbeats, 2);

    await tester.pump(const Duration(seconds: 60));
    expect(service.heartbeats, 3);
  });

  presenceTest('ikinci start ikinci timer acmaz — cift heartbeat yok', (tester) async {
    manager.start();
    manager.start();
    await tester.pump(const Duration(seconds: 60));

    expect(service.heartbeats, 2);
  });

  presenceTest('servis baglanmadan start hicbir sey yapmaz', (tester) async {
    manager.dispose();

    manager.start();
    await tester.pump(const Duration(seconds: 60));

    expect(service.heartbeats, 0);
  });

  presenceTest('stop: timer durur ve cevrimdisi bildirilir', (tester) async {
    manager.start();
    await tester.pump();

    await manager.stop();
    await tester.pump(const Duration(seconds: 120));

    expect(service.offlines, 1);
    expect(service.heartbeats, 1);
  });

  presenceTest('pause: timer durur ama cevrimdisi BILDIRILMEZ', (tester) async {
    manager.start();
    await tester.pump();

    manager.pause();
    await tester.pump(const Duration(seconds: 120));

    expect(service.offlines, 0);
    expect(service.heartbeats, 1);
  });

  presenceTest('pause sonrasi start hemen heartbeat atar (on plana donus)', (tester) async {
    manager.start();
    await tester.pump();
    manager.pause();

    manager.start();
    await tester.pump();

    expect(service.heartbeats, 2);
  });

  presenceTest('heartbeat hatasi yutulur, timer surer', (tester) async {
    service.failHeartbeat = true;

    manager.start();
    await tester.pump(const Duration(seconds: 60));

    expect(service.heartbeats, 2);
  });

  presenceTest('cevrimdisi cagrisi hatasi yutulur — stop tamamlanir', (tester) async {
    service.failOffline = true;
    manager.start();

    await expectLater(manager.stop(), completes);
    expect(service.offlines, 1);
  });
}

class _FakePresenceService implements PresenceService {
  int heartbeats = 0;
  int offlines = 0;
  bool failHeartbeat = false;
  bool failOffline = false;

  @override
  Future<void> heartbeat() async {
    heartbeats++;
    if (failHeartbeat) throw Exception('ag yok');
  }

  @override
  Future<void> goOffline() async {
    offlines++;
    if (failOffline) throw Exception('ag yok');
  }
}
