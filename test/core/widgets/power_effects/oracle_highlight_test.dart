import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';

import 'effect_host.dart';

const _label = '%70 doğru';
const _childKey = Key('answer');

Widget _oracle(bool active, {VoidCallback? onTap}) => OracleHighlight(
      active: active,
      label: _label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        key: _childKey,
        onTap: onTap,
        child: const SizedBox(width: 240, height: 56, child: Center(child: Text('Şık A'))),
      ),
    );

List<BoxShadow>? _glow(WidgetTester t) =>
    (t.widget<DecoratedBox>(find.byKey(OracleHighlight.glowKey)).decoration as BoxDecoration).boxShadow;

double _glowAlpha(WidgetTester t) => _glow(t)!.first.color.a;

double _labelOpacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(OracleHighlight.labelKey)).opacity.value;

void main() {
  testWidgets('pasifken çocuk düz çizilir: etiket yok, ışıma yok, animasyon yok', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false)));

    expect(find.text('Şık A'), findsOneWidget);
    expect(find.text(_label), findsNothing);
    expect(_glow(tester), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('oynatınca son hâle gelir: etiket görünür, yumuşak ışıma sabitlenir', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false)));
    await tester.pumpWidget(effectHost(_oracle(true)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    // Tekrarlayan bir nabız olsaydı pumpAndSettle zaman aşımına düşerdi.
    await tester.pumpAndSettle();

    expect(find.text(_label), findsOneWidget);
    expect(_labelOpacity(tester), 1.0);
    expect(_glowAlpha(tester), allOf(greaterThan(0), lessThanOrEqualTo(0.5)));

    final settledAlpha = _glowAlpha(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_glowAlpha(tester), settledAlpha, reason: 'tek giriş animasyonu: ışıma nabız atmaz');
  });

  testWidgets('oynarken ışıma ve etiket kademeli belirir', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false)));
    await tester.pumpWidget(effectHost(_oracle(true)));
    await pumpIntoPlay(tester, 0.5);

    final partial = _glowAlpha(tester);
    expect(partial, greaterThan(0));
    expect(_labelOpacity(tester), allOf(greaterThan(0), lessThan(1)));

    await tester.pumpAndSettle();
    expect(_glowAlpha(tester), greaterThan(partial));
  });

  testWidgets('hareketi azalt açıkken ilk karede son hâl', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false), reduceMotion: true));
    await tester.pumpWidget(effectHost(_oracle(true), reduceMotion: true));
    await tester.pump();

    expect(find.text(_label), findsOneWidget);
    expect(_labelOpacity(tester), 1.0);
    expect(_glowAlpha(tester), greaterThan(0));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ilk build zaten aktifse animasyonsuz son hâlde açılır', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(true)));

    expect(find.text(_label), findsOneWidget);
    expect(_labelOpacity(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı active ile yeniden build oynatmaz', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false)));
    await tester.pumpWidget(effectHost(_oracle(true)));
    final step = PowerEffectTiming.enter * 0.55;
    await tester.pump();
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(effectHost(_oracle(true)));
    await tester.pump(step);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_labelOpacity(tester), 1.0);

    await tester.pumpWidget(effectHost(_oracle(true)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('active kalkınca ışıma ve etiket kapanır', (tester) async {
    await tester.pumpWidget(effectHost(_oracle(false)));
    await tester.pumpWidget(effectHost(_oracle(true)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(effectHost(_oracle(false)));
    await tester.pumpAndSettle();

    expect(find.text(_label), findsNothing);
    expect(_glow(tester), isNull);
  });

  testWidgets('uzun etiket çocuğun genişliğini aşmaz, etiket çocuğun üst-son köşesine biner', (tester) async {
    const childWidth = 120.0;
    Widget narrow(bool active) => OracleHighlight(
          active: active,
          label: 'Çok uzun bir etiket metni burada yazıyor',
          child: const SizedBox(key: _childKey, width: childWidth, height: 56),
        );
    await tester.pumpWidget(effectHost(narrow(false)));
    await tester.pumpWidget(effectHost(narrow(true)));
    await tester.pumpAndSettle();

    final label = tester.getRect(find.byKey(OracleHighlight.labelKey));
    final child = tester.getRect(find.byKey(_childKey));
    expect(label.width, lessThanOrEqualTo(childWidth));
    expect(label.right, child.right - AppSpacing.md);
    expect(label.top, lessThan(child.top), reason: 'üst kenara biner (yarısı dışarıda)');
    expect(label.bottom, greaterThan(child.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vurgu çocuğun dokunuşunu engellemez', (tester) async {
    var taps = 0;
    await tester.pumpWidget(effectHost(_oracle(false, onTap: () => taps++)));
    await tester.pumpWidget(effectHost(_oracle(true, onTap: () => taps++)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_childKey));

    expect(taps, 1);
  });
}
