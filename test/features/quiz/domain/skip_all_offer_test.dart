import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/quiz/domain/skip_all_offer.dart';

/// "Hepsini Geç" teklif kuralı — gerçek quiz VE güç demosu aynı kuralı kullanır.
/// Fiyatlar canlı ekonomi ayarından gelir (prod: Doğru Say 50 / Hepsini Geç 90 mor;
/// istemci yedeği: 20 / 60).
void main() {
  group('skipAllOffered', () {
    test('kalan 2, 50/90 → true', () {
      expect(
        skipAllOffered(skipCost: 50, skipAllCost: 90, remaining: 2),
        isTrue,
      );
    });

    test('kalan 2, 20/60 → false', () {
      expect(
        skipAllOffered(skipCost: 20, skipAllCost: 60, remaining: 2),
        isFalse,
      );
    });

    test(
      'maliyet 0 → false (fiyat yüklenmediyse yanlış teklif yerine hiç)',
      () {
        expect(
          skipAllOffered(skipCost: 0, skipAllCost: 90, remaining: 4),
          isFalse,
        );
        expect(
          skipAllOffered(skipCost: 50, skipAllCost: 0, remaining: 4),
          isFalse,
        );
        expect(
          skipAllOffered(skipCost: 0, skipAllCost: 0, remaining: 4),
          isFalse,
        );
      },
    );

    test('negatif maliyet → false', () {
      expect(
        skipAllOffered(skipCost: -10, skipAllCost: 30, remaining: 4),
        isFalse,
      );
      expect(
        skipAllOffered(skipCost: 10, skipAllCost: -30, remaining: 4),
        isFalse,
      );
    });

    test('başabaş (60 = 3×20) teklif değil — kazanç yoksa gösterme', () {
      expect(
        skipAllOffered(skipCost: 20, skipAllCost: 60, remaining: 3),
        isFalse,
      );
      expect(
        skipAllOffered(skipCost: 20, skipAllCost: 60, remaining: 4),
        isTrue,
      );
    });
  });

  group('minRemainingForSkipAll', () {
    test('prod 50/90 → 2', () {
      expect(minRemainingForSkipAll(skipCost: 50, skipAllCost: 90), 2);
    });

    test('fallback 20/60 → 4', () {
      expect(minRemainingForSkipAll(skipCost: 20, skipAllCost: 60), 4);
    });

    test('10/30 → 4 (3 soruda başabaş, 4\'te ucuz)', () {
      expect(minRemainingForSkipAll(skipCost: 10, skipAllCost: 30), 4);
    });

    test('hiçbir k uymuyorsa ceiling döner (fiyat 0 dahil)', () {
      expect(minRemainingForSkipAll(skipCost: 0, skipAllCost: 0), 4);
      expect(minRemainingForSkipAll(skipCost: 10, skipAllCost: 500), 4);
      expect(
        minRemainingForSkipAll(skipCost: 10, skipAllCost: 500, ceiling: 6),
        6,
      );
    });

    test('floor altına inmez: Hepsini Geç çok ucuzsa bile floor', () {
      expect(minRemainingForSkipAll(skipCost: 50, skipAllCost: 1), 2);
      expect(minRemainingForSkipAll(skipCost: 50, skipAllCost: 1, floor: 3), 3);
    });
  });
}
