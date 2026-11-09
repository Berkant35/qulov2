import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';

import 'effect_host.dart';

const _childKey = Key('option');
const _width = 240.0;
const _height = 56.0;

Widget _effect(bool removed, {VoidCallback? onTap}) => HalfStrikeEffect(
      removed: removed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        key: _childKey,
        onTap: onTap,
        child: const SizedBox(width: _width, height: _height, child: Center(child: Text('Şık B'))),
      ),
    );

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(find.descendant(of: find.byType(HalfStrikeEffect), matching: find.byType(FadeTransition)))
    .opacity
    .value;

double _sizeFactor(WidgetTester t) => t
    .widget<SizeTransition>(find.descendant(of: find.byType(HalfStrikeEffect), matching: find.byType(SizeTransition)))
    .sizeFactor
    .value;

double _effectHeight(WidgetTester t) => t.getSize(find.byType(HalfStrikeEffect)).height;

Object get _drawsStrike => paints..line();

void main() {
  testWidgets('kaldırılmamışken çocuk tam boyda: çizgi yok, animasyon yok', (tester) async {
    await tester.pumpWidget(effectHost(_effect(false)));

    expect(_opacity(tester), 1.0);
    expect(_sizeFactor(tester), 1.0);
    expect(_effectHeight(tester), _height);
    expect(tester.renderObject(find.byKey(HalfStrikeEffect.strikeKey)), isNot(_drawsStrike));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir: opaklık 0, yükseklik 0, çizgi tam genişlikte', (tester) async {
    await tester.pumpWidget(effectHost(_effect(false)));
    await tester.pumpWidget(effectHost(_effect(true)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(_opacity(tester), 0.0);
    expect(_sizeFactor(tester), 0.0);
    expect(_effectHeight(tester), 0.0);
    expect(
      tester.renderObject(find.byKey(HalfStrikeEffect.strikeKey)),
      paints..line(p1: const Offset(AppSpacing.lg, _height / 2), p2: const Offset(_width - AppSpacing.lg, _height / 2)),
    );
  });

  testWidgets('önce üstü çizilir (şık yerinde), sonra opaklık düşer ve yükseklik kapanır', (tester) async {
    await tester.pumpWidget(effectHost(_effect(false)));
    await tester.pumpWidget(effectHost(_effect(true)));
    await pumpIntoPlay(tester, 0.25);

    expect(tester.renderObject(find.byKey(HalfStrikeEffect.strikeKey)), _drawsStrike);
    expect(_opacity(tester), 1.0, reason: 'çizgi çekilirken şık hâlâ görünür');
    expect(_sizeFactor(tester), 1.0);

    await tester.pump(PowerEffectTiming.enter * 0.45);
    expect(_opacity(tester), allOf(greaterThan(0), lessThan(1)));
    expect(_sizeFactor(tester), allOf(greaterThan(0), lessThan(1)));
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_effect(false), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(true), reduceMotion: true));
    await tester.pump();

    expect(_opacity(tester), 0.0);
    expect(_sizeFactor(tester), 0.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ilk build zaten kaldırılmışsa ilk karede kapalı', (tester) async {
    await tester.pumpWidget(effectHost(_effect(true)));

    expect(_opacity(tester), 0.0);
    expect(_sizeFactor(tester), 0.0);
    expect(_effectHeight(tester), 0.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı removed ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(false)));
    await tester.pumpWidget(effectHost(_effect(true)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_effect(true)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 0.0);

    await tester.pumpWidget(effectHost(_effect(true)));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_sizeFactor(tester), 0.0);
  });

  testWidgets('removed geri alınınca şık tam boya döner', (tester) async {
    await tester.pumpWidget(effectHost(_effect(true)));
    await tester.pumpWidget(effectHost(_effect(false)));
    await tester.pumpAndSettle();

    expect(_opacity(tester), 1.0);
    expect(_sizeFactor(tester), 1.0);
    expect(_effectHeight(tester), _height);
  });

  testWidgets('kaldırılan şık kaybolurken dokunuşu yakalamaz; kaldırılmamış şık yakalar', (tester) async {
    var taps = 0;
    await tester.pumpWidget(effectHost(_effect(false, onTap: () => taps++)));
    await tester.tap(find.byKey(_childKey));
    expect(taps, 1);

    await tester.pumpWidget(effectHost(_effect(true, onTap: () => taps++)));
    await pumpIntoPlay(tester, 0.25); // çizgi çekiliyor: şık hâlâ yerinde ve görünür
    await tester.tap(find.byKey(_childKey), warnIfMissed: false);

    expect(taps, 1, reason: 'kaldırılmış şıkka dokunmak cevap sayılmamalı');
  });

  testWidgets('RTL\'de çizgi okuma yönünde sağdan sola çekilir', (tester) async {
    await tester.pumpWidget(
      effectHost(Directionality(textDirection: TextDirection.rtl, child: _effect(false))),
    );
    await tester.pumpWidget(
      effectHost(Directionality(textDirection: TextDirection.rtl, child: _effect(true))),
    );
    await tester.pumpAndSettle();

    expect(
      tester.renderObject(find.byKey(HalfStrikeEffect.strikeKey)),
      paints..line(p1: const Offset(_width - AppSpacing.lg, _height / 2), p2: const Offset(AppSpacing.lg, _height / 2)),
    );
  });
}
