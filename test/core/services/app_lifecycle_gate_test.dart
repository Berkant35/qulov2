import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/app_lifecycle_gate.dart';

/// iOS sistem diyaloglari (ATT) uygulama aktif degilken sessizce basarisiz
/// olur; kapi ilk `resumed`'a kadar bekletir. Zaten aktifse beklemez.
void main() {
  Future<void> setLifecycle(WidgetTester tester, AppLifecycleState state) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(state.toString()),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('uygulama zaten aktifse hemen doner', (tester) async {
    await setLifecycle(tester, AppLifecycleState.resumed);
    var opened = false;

    unawaited(AppLifecycleGate.whenResumed().then((_) => opened = true));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('aktif degilse ilk resumed beklenir; inactive/paused kapiyi acmaz', (tester) async {
    await setLifecycle(tester, AppLifecycleState.inactive);
    var opened = false;

    unawaited(AppLifecycleGate.whenResumed().then((_) => opened = true));
    await tester.pump();
    expect(opened, isFalse, reason: 'inactive iken kapi kapali');

    await setLifecycle(tester, AppLifecycleState.paused);
    expect(opened, isFalse, reason: 'paused kapiyi acmaz');

    await setLifecycle(tester, AppLifecycleState.resumed);
    expect(opened, isTrue, reason: 'ilk resumed kapiyi acar');
  });

  testWidgets('kapi tek kullanimlik — sonraki resumed cevrimleri tekrar tetiklemez', (tester) async {
    await setLifecycle(tester, AppLifecycleState.inactive);
    var opens = 0;

    unawaited(AppLifecycleGate.whenResumed().then((_) => opens++));
    await setLifecycle(tester, AppLifecycleState.resumed);
    // ATT diyalogunun kendisi inactive→resumed cevrimi yaratir.
    await setLifecycle(tester, AppLifecycleState.inactive);
    await setLifecycle(tester, AppLifecycleState.resumed);

    expect(opens, 1);
    expect(tester.takeException(), isNull, reason: 'observer kaldirildi, ikinci complete yok');
  });
}
