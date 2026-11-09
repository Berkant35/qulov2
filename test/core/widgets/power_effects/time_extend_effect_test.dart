import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';

import 'effect_host.dart';

Widget _effect(int token, {int seconds = 15}) => TimeExtendEffect(seconds: seconds, playToken: token);

double _opacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(TimeExtendEffect.chipKey)).opacity.value;

Offset _offset(WidgetTester t) => t
    .widget<SlideTransition>(
      find.descendant(of: find.byKey(TimeExtendEffect.chipKey), matching: find.byType(SlideTransition)),
    )
    .position
    .value;

void main() {
  testWidgets('ilk build\'de oynamaz: çip yok, animasyon yok', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));

    expect(find.text('+15'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(find.text('+15'), findsOneWidget);
    expect(_opacity(tester), 1.0);
    expect(_offset(tester), Offset.zero);
  });

  testWidgets('oynarken çip aşağıdan sayaca doğru kayarak belirir', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    await pumpIntoPlay(tester, 0.25);

    expect(_opacity(tester), allOf(greaterThan(0), lessThan(1)));
    expect(_offset(tester).dy, allOf(greaterThan(0), lessThan(1)));
    expect(_offset(tester).dx, 0);
  });

  testWidgets('sabit "+15" değil, verilen saniye gösterilir', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0, seconds: 20)));
    await tester.pumpWidget(effectHost(_effect(1, seconds: 20)));
    await tester.pumpAndSettle();

    expect(find.text('+20'), findsOneWidget);
    expect(find.text('+15'), findsNothing);
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0), reduceMotion: true));
    await tester.pumpWidget(effectHost(_effect(1), reduceMotion: true));
    await tester.pump();

    expect(find.text('+15'), findsOneWidget);
    expect(_opacity(tester), 1.0);
    expect(_offset(tester), Offset.zero);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynarken hareketi azalt açılırsa hemen son hâle atlar', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    await pumpIntoPlay(tester, 0.25);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_effect(1), reduceMotion: true));
    await tester.pump();

    expect(_opacity(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı playToken ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    // Aynı token: animasyon baştan başlasaydı iki adım sonra hâlâ sürerdi.
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 1.0);

    // Bittikten sonra yeniden build de oynatmaz.
    await tester.pumpWidget(effectHost(_effect(1)));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 1.0);
  });

  testWidgets('yeni playToken efekti baştan oynatır', (tester) async {
    await tester.pumpWidget(effectHost(_effect(0)));
    await tester.pumpWidget(effectHost(_effect(1)));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1.0);

    await tester.pumpWidget(effectHost(_effect(2)));
    await pumpIntoPlay(tester, 0.1);

    expect(tester.hasRunningAnimations, isTrue);
    expect(_opacity(tester), lessThan(1.0));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1.0);
  });
}
