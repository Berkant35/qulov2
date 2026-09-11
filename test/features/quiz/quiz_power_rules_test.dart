import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/features/quiz/mixins/power_bar_mixin.dart';
import 'package:qulo_v2/features/quiz/quiz_power_rules.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';

/// Guc bari ve rescue teklifinin PAYLASILAN kurallari — para yolu.
/// SKIP_ALL yalnizca kalan sorulari tek tek SKIP'lemekten UCUZSA teklif
/// edilir; pahali teklif kullaniciyi kandirmak olurdu. Fiyatlar sunucudan
/// (oturum carpani uygulanmis, `QuizState.powerCosts`).
void main() {
  group('remainingQuestionCount', () {
    test('su anki soru dahil kalan sayilir', () {
      expect(remainingQuestionCount(_quiz(total: 5, current: 3)), 3);
      expect(remainingQuestionCount(_quiz(total: 5, current: 5)), 1);
    });

    test('soru henuz yuklenmediyse hepsi kalmistir', () {
      expect(remainingQuestionCount(_quiz(total: 4)), 4);
    });

    test('toplam bilinmiyorsa 1 — sifira bolme/negatif yok', () {
      expect(remainingQuestionCount(_quiz(total: 0)), 1);
    });

    test('sinir asimi 1\'e kirpilir', () {
      expect(remainingQuestionCount(_quiz(total: 3, current: 7)), 1);
    });
  });

  group('shouldOfferSkipAll', () {
    test('fiyat yuklenmediyse teklif edilmez — yanlis teklif yerine hic', () {
      expect(shouldOfferSkipAll(_quiz(total: 6, current: 1, skip: 0, skipAll: 30)), isFalse);
      expect(shouldOfferSkipAll(_quiz(total: 6, current: 1, skip: 10, skipAll: 0)), isFalse);
    });

    test('2 soru kalmisken pahali (30 > 2×10) → teklif yok', () {
      expect(shouldOfferSkipAll(_quiz(total: 5, current: 4, skip: 10, skipAll: 30)), isFalse);
    });

    test('3 soru kalmisken basabas (30 = 3×10) → teklif yok — kazanc yoksa gosterme', () {
      expect(shouldOfferSkipAll(_quiz(total: 5, current: 3, skip: 10, skipAll: 30)), isFalse);
    });

    test('4 soru kalmisken ucuz (30 < 4×10) → teklif edilir', () {
      expect(shouldOfferSkipAll(_quiz(total: 5, current: 2, skip: 10, skipAll: 30)), isTrue);
    });

    test('TOPLAM degil KALAN soru sayilir — ayni quizde ilerledikce teklif kalkar', () {
      // 5 soruluk quizin basinda avantajli, 4. soruda artik degil.
      expect(shouldOfferSkipAll(_quiz(total: 5, current: 1, skip: 10, skipAll: 30)), isTrue);
      expect(shouldOfferSkipAll(_quiz(total: 5, current: 4, skip: 10, skipAll: 30)), isFalse);
    });
  });

  group('visiblePowers (guc bari)', () {
    final bar = _Bar();

    test('ipucu yoksa HINT gizlenir, varsa gosterilir', () {
      final quiz = _quiz(total: 2, current: 1, skip: 10, skipAll: 30);

      expect(bar.visiblePowers(quiz, hasHint: false), isNot(contains(PowerType.hint)));
      expect(bar.visiblePowers(quiz, hasHint: true), contains(PowerType.hint));
    });

    test('SKIP_ALL yalnizca avantajliyken gosterilir', () {
      expect(
        bar.visiblePowers(_quiz(total: 5, current: 1, skip: 10, skipAll: 30), hasHint: false),
        contains(PowerType.skipAll),
      );
      expect(
        bar.visiblePowers(_quiz(total: 5, current: 4, skip: 10, skipAll: 30), hasHint: false),
        isNot(contains(PowerType.skipAll)),
      );
    });

    test('sira sabit: oracle, half, skip, hint, sure, skip_all', () {
      final quiz = _quiz(total: 5, current: 1, skip: 10, skipAll: 30);

      expect(bar.visiblePowers(quiz, hasHint: true), [
        PowerType.oracle,
        PowerType.half,
        PowerType.skip,
        PowerType.hint,
        PowerType.timeExtend,
        PowerType.skipAll,
      ]);
    });
  });
}

class _Bar with PowerBarMixin {}

QuizState _quiz({required int total, int? current, int skip = 0, int skipAll = 0}) => QuizState(
      sessionId: 's1',
      totalQuestions: total,
      currentQuestion: current == null
          ? null
          : QuizQuestionModel(
              sessionId: 's1',
              questionNumber: current,
              totalQuestions: total,
              questionId: 'q$current',
              questionText: 'Soru',
              answers: const [QuizAnswerOption(index: 1, text: 'A')],
            ),
      powerCosts: {
        'SKIP': SessionPowerCost(purple: skip, green: 0),
        'SKIP_ALL': SessionPowerCost(purple: skipAll, green: 0),
      },
    );
