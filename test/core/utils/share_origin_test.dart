import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/share_origin.dart';

/// iOS paylaşım sayfası sıfır ya da görünüm dışına taşan çıkış alanında
/// `sharePositionOrigin: argument must be set` ile crash veriyordu
/// (Crashlytics 2.0.14–2.0.15, ekran 390×844). Alan her durumda sıfırdan
/// farklı ve ekranın içinde olmalı.
void main() {
  const screen = Size(390, 844);

  Future<BuildContext> pumpAt(WidgetTester tester, Widget Function(GlobalKey key) build) async {
    // MediaQuery görünümün boyutunu okur (setSurfaceSize yalnız çizim yüzeyini değiştirir).
    tester.view
      ..physicalSize = screen
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: build(key))));
    return key.currentContext!;
  }

  void expectValidOrigin(Rect origin) {
    expect(origin.width, greaterThan(0));
    expect(origin.height, greaterThan(0));
    expect((Offset.zero & screen).expandToInclude(origin), Offset.zero & screen,
        reason: 'alan görünümün içinde kalmalı');
  }

  testWidgets('dokunulan widget ekranda görünen alanını verir', (tester) async {
    final context = await pumpAt(
      tester,
      (key) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 100),
          child: SizedBox(key: key, width: 120, height: 40),
        ),
      ),
    );

    expect(shareOriginFor(context), const Rect.fromLTWH(20, 100, 120, 40));
  });

  testWidgets('kısmen ekran dışındaki uzun widget görünür kısmıyla kırpılır', (tester) async {
    final context = await pumpAt(
      tester,
      (key) => OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: 2000,
        child: SizedBox(key: key, width: 390, height: 2000),
      ),
    );

    final origin = shareOriginFor(context);
    expectValidOrigin(origin);
    expect(origin.height, screen.height);
  });

  testWidgets('ölçülemeyen (sıfır boyutlu) widget ekran ortasında 1×1 alan verir', (tester) async {
    final context = await pumpAt(tester, (key) => SizedBox.shrink(key: key));

    final origin = shareOriginFor(context);
    expectValidOrigin(origin);
    expect(origin.center, screen.center(Offset.zero));
  });
}
