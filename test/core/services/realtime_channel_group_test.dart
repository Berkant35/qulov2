import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/realtime_auth_manager.dart';
import 'package:qulo_v2/core/services/realtime_channel_group.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kanal sahibinin (eşleşme listesi, sohbet) Realtime kanalları (2.0.18 P0):
/// abone olmadan önce token, sunucu kanalı kapatırsa (süresi geçen token) ya da
/// token öne gelişte yenilenince yeniden kurulum. Kanal adları sahipte sabit kalır.
///
/// Kanallar gerçek `RealtimeChannel` nesnesi ama abone EDİLMEZ (ağ yok): durum
/// olayları testten [RealtimeStatusCallback] ile verilir.
class _FakeTarget implements RealtimeAuthTarget {
  @override
  Future<void> apply(String token) async {}

  @override
  Future<void> useAnon() async {}

  @override
  Future<void> reset() async {}
}

class _Harness {
  _Harness(this.tester, {int channelsPerBuild = 2}) : _perBuild = channelsPerBuild {
    auth = RealtimeAuthManager(
      issueToken: () async {
        tokenCalls++;
        await tokenGate?.future;
        return Success(RealtimeToken(
          token: 'jwt-$tokenCalls',
          expiresAt: tester.binding.clock.now().toUtc().add(const Duration(minutes: 10)),
        ));
      },
      target: _FakeTarget(),
      now: () => tester.binding.clock.now().toUtc(),
    );
    group = RealtimeChannelGroup(
      auth: auth,
      userId: 'u1',
      build: (gen, onStatus) {
        builds.add((gen: gen, tokenCallsAtBuild: tokenCalls));
        statusCallbacks.add(onStatus);
        return [for (var i = 0; i < _perBuild; i++) _socket.channel('test:$gen:$i')];
      },
      reload: () async => reloads++,
      close: closed.add,
    );
  }

  final WidgetTester tester;
  final int _perBuild;
  final _socket = RealtimeClient('ws://127.0.0.1:9');
  late final RealtimeAuthManager auth;
  late final RealtimeChannelGroup group;
  final builds = <({int gen, int tokenCallsAtBuild})>[];
  final statusCallbacks = <RealtimeStatusCallback>[];
  final closed = <RealtimeChannel>[];
  int tokenCalls = 0;
  int reloads = 0;
  Completer<void>? tokenGate;

  /// Son kuruluşun kanallarından biri [status] bildirir.
  void report(RealtimeSubscribeStatus status, {int build = -1}) {
    final i = build < 0 ? statusCallbacks.length + build : build;
    statusCallbacks[i](status, null);
  }

  Future<void> wait(Duration d) => tester.pump(d);

  void finish() {
    group.dispose();
    auth.dispose();
  }
}

void _test(String description, Future<void> Function(_Harness h) body, {int channelsPerBuild = 2}) {
  testWidgets(description, (tester) async {
    final h = _Harness(tester, channelsPerBuild: channelsPerBuild);
    await body(h);
    h.finish();
  });
}

void main() {
  _test('abone olmadan ÖNCE kullanıcı token\'ı alınır', (h) async {
    await h.group.start();

    expect(h.builds.single.tokenCallsAtBuild, 1);
  });

  _test('sunucu kanalı kapatırsa (süresi geçen token) bekleyip yeniden kurar ve veriyi tazeler', (h) async {
    await h.group.start();

    h.report(RealtimeSubscribeStatus.closed);
    await h.wait(RealtimeChannelGroup.retryStep);

    expect(h.builds, hasLength(2));
    expect(h.reloads, 1, reason: 'kopukluk sırasında kaçan olaylar');
    expect(h.closed, hasLength(2), reason: 'eski kanalların ikisi de kapatılır');
  });

  for (final status in [RealtimeSubscribeStatus.channelError, RealtimeSubscribeStatus.timedOut]) {
    _test('$status → yeniden kurulum', (h) async {
      await h.group.start();

      h.report(status);
      await h.wait(RealtimeChannelGroup.retryStep);

      expect(h.builds, hasLength(2));
    });
  }

  _test('aynı kopuklukta tüm kanallar haber verse de TEK yeniden kurulum', (h) async {
    await h.group.start();

    h.report(RealtimeSubscribeStatus.closed);
    h.report(RealtimeSubscribeStatus.closed);
    h.report(RealtimeSubscribeStatus.channelError);
    await h.wait(RealtimeChannelGroup.retryStep * 3);

    expect(h.builds, hasLength(2));
  });

  _test('kendi kapattığımız eski kuruluşun "closed" durumu yeniden kurulum tetiklemez', (h) async {
    await h.group.start();
    await h.group.restart(reload: false);

    h.report(RealtimeSubscribeStatus.closed, build: 0);
    await h.wait(RealtimeChannelGroup.retryStep * 3);

    expect(h.builds, hasLength(2));
  });

  _test('art arda başarısızlık en çok 3 kez yeniden dener (artan bekleme)', (h) async {
    await h.group.start();

    for (var i = 1; i <= 4; i++) {
      h.report(RealtimeSubscribeStatus.channelError);
      await h.wait(RealtimeChannelGroup.retryStep * i);
    }

    expect(h.builds, hasLength(1 + RealtimeChannelGroup.maxRetries));
  });

  _test('başarılı abonelik sayacı sıfırlar: uzun oturumda her token bitişi yeniden kurulabilir', (h) async {
    await h.group.start();

    for (var i = 0; i < 5; i++) {
      h.report(RealtimeSubscribeStatus.subscribed);
      h.report(RealtimeSubscribeStatus.closed);
      await h.wait(RealtimeChannelGroup.retryStep);
    }

    expect(h.builds, hasLength(6));
  });

  _test('token öne gelişte yenilenince kanallar hemen yeniden kurulur', (h) async {
    await h.group.start();
    h.auth.onBackground();
    await h.wait(const Duration(minutes: 9)); // 1 dk kaldı

    await h.auth.onForeground();
    await h.tester.pump();
    await h.tester.pump();

    expect(h.tokenCalls, 2);
    expect(h.builds, hasLength(2));
    expect(h.builds.last.tokenCallsAtBuild, 2, reason: 'yeni kanallar yeni token\'la katılır');
    expect(h.reloads, 1);
  });

  _test('liste değişince (fetchMatches) tazelemeden yeniden kurulum', (h) async {
    await h.group.start();

    await h.group.restart(reload: false);

    expect(h.builds, hasLength(2));
    expect(h.reloads, 0);
    expect(h.group.generation, h.builds.last.gen);
  });

  _test('kapatılınca kanallar kapanır, bekleyen yeniden deneme iptal edilir', (h) async {
    await h.group.start();
    h.report(RealtimeSubscribeStatus.closed);

    h.group.dispose();
    await h.wait(RealtimeChannelGroup.retryStep * 3);

    expect(h.builds, hasLength(1));
    expect(h.closed, hasLength(2));
  });

  _test('token beklenirken ekran kapanırsa kanal kurulmaz', (h) async {
    h.tokenGate = Completer<void>();
    final starting = h.group.start();

    h.group.dispose();
    h.tokenGate!.complete();
    await starting;

    expect(h.builds, isEmpty);
  });
}
