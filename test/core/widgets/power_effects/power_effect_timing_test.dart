import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';

void main() {
  test('süreler spec §4.3 aralığında: 300-600 ms, kapanış girişten uzun değil', () {
    expect(PowerEffectTiming.enter.inMilliseconds, inInclusiveRange(300, 600));
    expect(PowerEffectTiming.exit.inMilliseconds, inInclusiveRange(300, 600));
    expect(PowerEffectTiming.exit, lessThanOrEqualTo(PowerEffectTiming.enter));
  });

  test('eğri uçları sabitler: 0 → 0, 1 → 1', () {
    expect(PowerEffectTiming.curve.transform(0), 0);
    expect(PowerEffectTiming.curve.transform(1), 1);
    expect(PowerEffectTiming.curve, isA<Curve>());
  });
}
