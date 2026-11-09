import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';

import 'effect_host.dart';

void main() {
  Future<bool> readReduceMotion(WidgetTester tester, {required bool disabled}) async {
    late bool result;
    await tester.pumpWidget(
      effectHost(
        Builder(
          builder: (context) {
            result = reduceMotionOf(context);
            return const SizedBox.shrink();
          },
        ),
        reduceMotion: disabled,
      ),
    );
    return result;
  }

  testWidgets('sistem "hareketi azalt" açıksa true', (tester) async {
    expect(await readReduceMotion(tester, disabled: true), isTrue);
  });

  testWidgets('sistem "hareketi azalt" kapalıysa false', (tester) async {
    expect(await readReduceMotion(tester, disabled: false), isFalse);
  });
}
