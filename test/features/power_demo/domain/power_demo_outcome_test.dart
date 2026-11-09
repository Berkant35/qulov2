import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';

void main() {
  group('PowerDemoOutcome kodlama', () {
    test('encode: completed / skipped:N / null', () {
      expect(const PowerDemoCompleted().encode(), 'completed');
      expect(const PowerDemoSkipped(3).encode(), 'skipped:3');
      expect(const PowerDemoNotSeen().encode(), isNull);
    });

    test('outcome encode/decode gidiş-dönüş + bozuk değer → notSeen', () {
      for (final outcome in <PowerDemoOutcome>[
        const PowerDemoCompleted(),
        const PowerDemoSkipped(0),
        const PowerDemoSkipped(3),
        const PowerDemoSkipped(9),
        const PowerDemoNotSeen(),
      ]) {
        expect(PowerDemoOutcome.decode(outcome.encode()), outcome);
      }

      for (final broken in <String?>[
        null,
        '',
        ' ',
        'foo',
        'Completed',
        'completed ',
        'skipped',
        'skipped:',
        'skipped:abc',
        'skipped:3x',
        'skipped: 3',
        'skipped:-1',
        'skipped:+3',
        'skipped:3:4',
        'skipped:99999999999999999999999',
      ]) {
        expect(
          PowerDemoOutcome.decode(broken),
          const PowerDemoNotSeen(),
          reason: '"$broken"',
        );
      }
    });

    test('decode skipped:N adımı taşır', () {
      final outcome = PowerDemoOutcome.decode('skipped:4');
      expect(outcome, isA<PowerDemoSkipped>());
      expect((outcome as PowerDemoSkipped).fromStep, 4);
    });

    test('değer eşitliği: aynı adım eşit, farklı adım eşit değil', () {
      expect(const PowerDemoSkipped(2), const PowerDemoSkipped(2));
      expect(
        const PowerDemoSkipped(2).hashCode,
        const PowerDemoSkipped(2).hashCode,
      );
      expect(const PowerDemoSkipped(2), isNot(const PowerDemoSkipped(3)));
      expect(const PowerDemoCompleted(), isNot(const PowerDemoNotSeen()));
    });
  });
}
