import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';

import 'effect_host.dart';

const _cardKey = Key('card');
const _cardWidth = 300.0;

Widget _effect(int token, {VoidCallback? onTap, TextDirection? direction}) {
  final effect = SkipSlideEffect(
    playToken: token,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      key: _cardKey,
      onTap: onTap,
      child: const SizedBox(width: _cardWidth, height: 120, child: Center(child: Text('Soru'))),
    ),
  );
  return direction == null ? effect : Directionality(textDirection: direction, child: effect);
}

double _cardOpacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(SkipSlideEffect.childKey)).opacity.value;

double _badgeOpacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(SkipSlideEffect.badgeKey)).opacity.value;

/// Kartın dinlenme konumuna göre yatay kayması.
double _slidX(WidgetTester t, double restX) => t.getCenter(find.byKey(_cardKey)).dx - restX;

void main() {
  testWidgets('ilk build\'de kart yerinde ve görünür, ✓ yok, animasyon yok', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));

    expect(find.byKey(SkipSlideEffect.badgeKey), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(_cardOpacity(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir: kart kenara kaydı ve görünmez, ✓ tam görünür', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    final restX = tester.getCenter(find.byKey(_cardKey)).dx;
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(_slidX(tester, restX), _cardWidth, reason: 'kart kendi genişliği kadar kenara kayar');
    expect(_cardOpacity(tester), 0.0);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(_badgeOpacity(tester), 1.0);
  });

  testWidgets('oynarken kart kayarken soluklaşır, ✓ henüz belirmemiştir', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    final restX = tester.getCenter(find.byKey(_cardKey)).dx;
    await tester.pumpWidget(effectHost(_effect(1)));
    await pumpIntoPlay(tester, 0.25);

    expect(_slidX(tester, restX), allOf(greaterThan(0), lessThan(_cardWidth)));
    expect(_cardOpacity(tester), allOf(greaterThan(0), lessThan(1)));
    expect(_badgeOpacity(tester), 0.0);

    await tester.pump(PowerEffectTiming.enter * 0.5);
    expect(_badgeOpacity(tester), allOf(greaterThan(0), lessThan(1)));
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(1), reduceMotion: true));
    await tester.pump();

    expect(_cardOpacity(tester), 0.0);
    expect(_badgeOpacity(tester), 1.0);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı playToken ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_badgeOpacity(tester), 1.0);

    await tester.pumpWidget(effectHost(_effect(1)));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_cardOpacity(tester), 0.0);
  });

  testWidgets('yeni playToken efekti baştan oynatır', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    final restX = tester.getCenter(find.byKey(_cardKey)).dx;
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(effectHost(_effect(2)));
    await pumpIntoPlay(tester, 0.25);

    expect(tester.hasRunningAnimations, isTrue);
    expect(_slidX(tester, restX), allOf(greaterThan(0), lessThan(_cardWidth)));
  });

  testWidgets('kayma başlayınca kart dokunuş yakalamaz; başlamadan yakalar', (tester) async {
    var taps = 0;
    await tester.pumpWidget(effectHost(_effect(0, onTap: () => taps++)));
    final rest = tester.getCenter(find.byKey(_cardKey));
    await tester.tapAt(rest);
    expect(taps, 1);

    await tester.pumpWidget(effectHost(_effect(1, onTap: () => taps++)));
    await pumpIntoPlay(tester, 0.25);
    // Kart yarı yolda; sürüklenen kartın hâlâ kutunun içinde kalan kısmına dokun.
    await tester.tapAt(rest + const Offset(120, 0));

    expect(taps, 1, reason: 'geçilen soruya cevap verilemez');
  });

  testWidgets('RTL\'de kart okuma yönünün sonuna, yani sola kayar', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, direction: TextDirection.rtl)));
    final restX = tester.getCenter(find.byKey(_cardKey)).dx;
    await tester.pumpWidget(effectHost(_effect(1, direction: TextDirection.rtl)));
    await tester.pumpAndSettle();

    expect(_slidX(tester, restX), -_cardWidth);
  });
}
