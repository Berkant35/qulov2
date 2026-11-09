import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_effects.dart';

void main() {
  group('halfRemovedIndices', () {
    test('Yarıla doğru ve Kâhin şıkkını elemez', () {
      // 4 şık, doğru 1, Kâhin yanlış olan 2'yi öneriyor → yalnız 0 ve 3 elenebilir.
      expect(
        halfRemovedIndices(optionCount: 4, correctIndex: 1, keepIndex: 2),
        [0, 3],
      );
    });

    test('Kâhin yok: doğru hariç artan sırada ilk 2 şık elenir', () {
      expect(halfRemovedIndices(optionCount: 4, correctIndex: 0), [1, 2]);
      expect(halfRemovedIndices(optionCount: 4, correctIndex: 2), [0, 1]);
      expect(halfRemovedIndices(optionCount: 4, correctIndex: 3), [0, 1]);
    });

    test('Kâhin doğruyu öneriyorsa (demo) yalnız doğru korunur', () {
      expect(
        halfRemovedIndices(optionCount: 4, correctIndex: 2, keepIndex: 2),
        [0, 1],
      );
    });

    test('doğru ya da Kâhin şıkkı hiçbir zaman elenenler arasında değil', () {
      for (var count = 2; count <= 5; count++) {
        for (var correct = 0; correct < count; correct++) {
          for (var keep = 0; keep < count; keep++) {
            final removed = halfRemovedIndices(
              optionCount: count,
              correctIndex: correct,
              keepIndex: keep,
            );
            expect(
              removed,
              isNot(contains(correct)),
              reason: '$count/$correct/$keep',
            );
            expect(
              removed,
              isNot(contains(keep)),
              reason: '$count/$correct/$keep',
            );
            expect(removed.length, lessThanOrEqualTo(2));
            expect(removed, orderedEquals([...removed]..sort()));
          }
        }
      }
    });

    test('elenecek şık 2\'den azsa elde olan kadarı elenir', () {
      // 3 şık, doğru 0, Kâhin 1 → yalnız 2 elenebilir.
      expect(
        halfRemovedIndices(optionCount: 3, correctIndex: 0, keepIndex: 1),
        [2],
      );
      expect(halfRemovedIndices(optionCount: 2, correctIndex: 1), [0]);
    });

    test('dönen liste değiştirilemez', () {
      final removed = halfRemovedIndices(optionCount: 4, correctIndex: 0);
      expect(() => removed.add(9), throwsUnsupportedError);
    });
  });
}
