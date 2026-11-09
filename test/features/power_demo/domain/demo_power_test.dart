import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';

void main() {
  group('DemoPower', () {
    test(
      'apiName sunucu güç adlarıyla birebir (UI PowerType.fromApiName ile eşler)',
      () {
        expect(
          {for (final p in DemoPower.values) p: p.apiName},
          {
            DemoPower.timeExtend: 'TIME_EXTEND',
            DemoPower.oracle: 'ORACLE',
            DemoPower.half: 'HALF',
            DemoPower.hint: 'HINT',
            DemoPower.skip: 'SKIP',
            DemoPower.skipAll: 'SKIP_ALL',
          },
        );
      },
    );

    test('tam 6 quiz gücü', () {
      expect(DemoPower.values, hasLength(6));
    });
  });
}
