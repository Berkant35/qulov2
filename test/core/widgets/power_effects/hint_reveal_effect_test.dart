import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';

import 'effect_host.dart';

const _hint = 'Cevap bir renk';

Widget _effect(String? text) => HintRevealEffect(text: text);

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(find.descendant(of: find.byType(HintRevealEffect), matching: find.byType(FadeTransition)))
    .opacity
    .value;

double _sizeFactor(WidgetTester t) => t
    .widget<SizeTransition>(find.descendant(of: find.byType(HintRevealEffect), matching: find.byType(SizeTransition)))
    .sizeFactor
    .value;

double _heightOf(WidgetTester t) => t.getSize(find.byType(HintRevealEffect)).height;

void main() {
  testWidgets('text null iken hiçbir şey çizilmez, yer kaplamaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(null)));

    expect(find.byType(Text), findsNothing);
    expect(_heightOf(tester), 0.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir: kart tam yükseklikte ve opak', (tester) async {
    await tester.pumpWidget(effectHost(_effect(null)));
    await tester.pumpWidget(effectHost(_effect(_hint)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(find.text(_hint), findsOneWidget);
    expect(_opacity(tester), 1.0);
    expect(_sizeFactor(tester), 1.0);
    expect(_heightOf(tester), greaterThan(0));
  });

  testWidgets('açılırken yükseklik ve opaklık birlikte artar', (tester) async {
    await tester.pumpWidget(effectHost(_effect(null)));
    await tester.pumpWidget(effectHost(_effect(_hint)));
    await pumpIntoPlay(tester, 0.25);

    expect(_sizeFactor(tester), allOf(greaterThan(0), lessThan(1)));
    expect(_opacity(tester), allOf(greaterThan(0), lessThan(1)));
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_effect(null), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(_hint), reduceMotion: true));
    await tester.pump();

    expect(find.text(_hint), findsOneWidget);
    expect(_sizeFactor(tester), 1.0);
    expect(_opacity(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('hareketi azalt açıkken kapanış da ilk karede biter', (tester) async {
    await tester.pumpWidget(effectHost(_effect(_hint), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(null), reduceMotion: true));
    await tester.pump();

    expect(find.text(_hint), findsNothing);
    expect(_heightOf(tester), 0.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ilk build text doluysa animasyonsuz açık', (tester) async {
    await tester.pumpWidget(effectHost(_effect(_hint)));

    expect(find.text(_hint), findsOneWidget);
    expect(_sizeFactor(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı text ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(null)));
    await tester.pumpWidget(effectHost(_effect(_hint)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_effect(_hint)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_sizeFactor(tester), 1.0);

    await tester.pumpWidget(effectHost(_effect(_hint)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('açıkken metin değişirse yeniden oynamaz, yeni metin görünür', (tester) async {
    await tester.pumpWidget(effectHost(_effect(_hint)));
    await tester.pumpWidget(effectHost(_effect('Başka ipucu')));

    expect(find.text('Başka ipucu'), findsOneWidget);
    expect(find.text(_hint), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('text null olunca kapanır; kapanırken metin kaybolmaz, bitince ağaçtan çıkar', (tester) async {
    await tester.pumpWidget(effectHost(_effect(_hint)));
    await tester.pumpWidget(effectHost(_effect(null)));
    await tester.pump();
    await tester.pump(PowerEffectTiming.exit * 0.5);

    expect(find.text(_hint), findsOneWidget, reason: 'kapanış sırasında içerik boşalmamalı');
    expect(_sizeFactor(tester), allOf(greaterThan(0), lessThan(1)));

    await tester.pumpAndSettle();
    expect(find.text(_hint), findsNothing);
    expect(_heightOf(tester), 0.0);
  });

  testWidgets('kapanış PowerEffectTiming.exit süresinde biter (girişten kısa)', (tester) async {
    await tester.pumpWidget(effectHost(_effect(_hint)));
    await tester.pumpWidget(effectHost(_effect(null)));
    await tester.pump();
    await tester.pump(PowerEffectTiming.exit + const Duration(milliseconds: 16));

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text(_hint), findsNothing);
  });
}
