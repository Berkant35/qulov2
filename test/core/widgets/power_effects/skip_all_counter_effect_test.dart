import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_all_counter_effect.dart';

import 'effect_host.dart';

Widget _effect(int token, {int from = 6, int to = 7}) => SkipAllCounterEffect(from: from, to: to, playToken: token);

String _counter(WidgetTester t) => t.widget<Text>(find.byKey(SkipAllCounterEffect.counterKey)).data!;

int _current(WidgetTester t) => int.parse(_counter(t).split('/').first);

double _checkOpacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(SkipAllCounterEffect.checkKey)).opacity.value;

void main() {
  testWidgets('ilk build\'de "from/to" gösterir, ✓ yok, animasyon yok', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));

    expect(find.text('6/7'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir: 7/7 ve ✓', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(find.text('7/7'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(_checkOpacity(tester), 1.0);
  });

  testWidgets('to\'ya doğru tek yönlü sayar, payda sabit kalır, ara değerler görünür', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, from: 2, to: 9)));
    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    await tester.pump();

    final seen = <int>[_current(tester)];
    for (var i = 0; i < 12; i++) {
      await tester.pump(PowerEffectTiming.enter ~/ 12);
      expect(_counter(tester), endsWith('/9'));
      seen.add(_current(tester));
    }

    expect(seen.first, 2);
    expect(seen.last, 9);
    expect(seen, orderedEquals([...seen]..sort()), reason: 'geri saymaz');
    expect(seen.toSet().difference({2, 9}), isNotEmpty, reason: 'ara değerlerden geçer');
  });

  testWidgets('✓ sayma bitmeden belirmez, bitince tam görünür', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, from: 2, to: 9)));
    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    await pumpIntoPlay(tester, 0.25);

    expect(_checkOpacity(tester), 0.0);

    await tester.pumpAndSettle();
    expect(_checkOpacity(tester), 1.0);
  });

  testWidgets('from == to: sayma yok, doğrudan ✓', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, from: 7, to: 7)));
    await tester.pumpWidget(effectHost(_effect(1, from: 7, to: 7)));
    await pumpIntoPlay(tester, 0.3);
    expect(find.text('7/7'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('7/7'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(1), reduceMotion: true));
    await tester.pump();

    expect(find.text('7/7'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(_checkOpacity(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı playToken ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, from: 2, to: 9)));
    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('9/9'), findsOneWidget);

    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('9/9'), findsOneWidget);
  });

  testWidgets('yeni playToken ve yeni from/to ile baştan sayar', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, from: 2, to: 9)));
    await tester.pumpWidget(effectHost(_effect(1, from: 2, to: 9)));
    await tester.pumpAndSettle();
    expect(find.text('9/9'), findsOneWidget);

    await tester.pumpWidget(effectHost(_effect(2, from: 9, to: 12)));
    await tester.pump();
    expect(find.text('9/12'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(find.text('12/12'), findsOneWidget);
  });
}
