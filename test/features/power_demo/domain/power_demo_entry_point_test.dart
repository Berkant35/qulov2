import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';

void main() {
  test(
    'analyticsValue: onboarding | market | quiz_intro (entry_point parametresi)',
    () {
      expect(PowerDemoEntryPoint.onboarding.analyticsValue, 'onboarding');
      expect(PowerDemoEntryPoint.market.analyticsValue, 'market');
      expect(PowerDemoEntryPoint.quizIntro.analyticsValue, 'quiz_intro');
    },
  );

  test('üç giriş noktası, değerler tekil', () {
    final values = PowerDemoEntryPoint.values
        .map((e) => e.analyticsValue)
        .toSet();
    expect(values, hasLength(3));
  });
}
