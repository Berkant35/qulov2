import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';

/// Efekt testlerinin ortak ev sahibi: MaterialApp + isteğe bağlı "hareketi azalt".
Widget effectHost(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: app!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Efekti başlatan kareyi çizer, sonra girişin [fraction] oranı kadar ilerletir.
Future<void> pumpIntoPlay(WidgetTester tester, double fraction) async {
  await tester.pump();
  await tester.pump(PowerEffectTiming.enter * fraction);
}
