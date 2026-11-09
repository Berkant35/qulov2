import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';

void main() {
  const base = PowerDemoProgress(
    stepIndex: 2,
    phase: PowerDemoPhase.awaitingAnswer,
  );

  test('varsayılanlar: seçim yok, kaldırılan şık yok, jetonlar 0', () {
    expect(base.selectedIndex, isNull);
    expect(base.removedIndices, isEmpty);
    expect(base.oracleIndex, isNull);
    expect(base.hintVisible, isFalse);
    expect(base.extraSecondsToken, 0);
    expect(base.skipToken, 0);
    expect(base.wrongAnswers, 0);
    expect(base.powerUsedAtStep, isNull);
  });

  test('copyWith yalnız verilen alanı değiştirir', () {
    final next = base.copyWith(
      selectedIndex: 1,
      hintVisible: true,
      wrongAnswers: 2,
    );

    expect(next.stepIndex, 2);
    expect(next.phase, PowerDemoPhase.awaitingAnswer);
    expect(next.selectedIndex, 1);
    expect(next.hintVisible, isTrue);
    expect(next.wrongAnswers, 2);
  });

  test('copyWith nullable alanları açıkça temizleyebilir', () {
    final set = base.copyWith(
      selectedIndex: 1,
      oracleIndex: 2,
      powerUsedAtStep: 2,
    );

    final cleared = set.copyWith(
      clearSelectedIndex: true,
      clearOracleIndex: true,
      clearPowerUsedAtStep: true,
    );

    expect(cleared.selectedIndex, isNull);
    expect(cleared.oracleIndex, isNull);
    expect(cleared.powerUsedAtStep, isNull);
  });

  test('değer eşitliği alanlara bakar (kaldırılan şık listesi dahil)', () {
    final a = base.copyWith(removedIndices: const [0, 1], selectedIndex: 3);
    final b = base.copyWith(removedIndices: [0, 1], selectedIndex: 3);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.copyWith(removedIndices: const [0, 2])));
    expect(a, isNot(a.copyWith(phase: PowerDemoPhase.rescue)));
  });
}
