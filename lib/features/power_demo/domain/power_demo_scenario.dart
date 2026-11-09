import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/quiz/domain/skip_all_offer.dart';

/// Demonun soru sırası. 6 gücün her biri tam bir soruda öğretilir; Hepsini Geç'ten sonra
/// onun geçeceği güçsüz sorular gelir.
class PowerDemoScenario {
  PowerDemoScenario(List<PowerDemoQuestion> questions)
    : questions = List.unmodifiable(questions),
      assert(
        questions.where((q) => q.power == DemoPower.skipAll).length == 1,
        'senaryoda tam bir Hepsini Geç sorusu olmalı',
      );

  /// Hepsini Geç adımı: gerçek quiz bu gücü yalnız kalan soruları tek tek geçmekten ucuzsa
  /// teklif eder (`skipAllOffered`); demo aynı kuralı canlı fiyatlarla uygular. Hepsini Geç
  /// sorusunda kalan soru sayısı (kendisi dahil) kuralın teklif ettiği en küçük sayıdır
  /// (2..4): prod 50/90 mor → 2 → 7 soru; yedek 20/60 → 4 → 9 soru.
  factory PowerDemoScenario.build({
    required int skipPurple,
    required int skipAllPurple,
  }) {
    final remainingAtSkipAll = minRemainingForSkipAll(
      skipCost: skipPurple,
      skipAllCost: skipAllPurple,
    );
    final powers = [
      ...DemoPower.values,
      ...List<DemoPower?>.filled(remainingAtSkipAll - 1, null),
    ];
    return PowerDemoScenario([
      for (var i = 0; i < powers.length; i++) _question(i, powers[i]),
    ]);
  }

  final List<PowerDemoQuestion> questions;

  /// Hepsini Geç sorusunun indeksi (0 tabanlı).
  int get skipAllIndex =>
      questions.indexWhere((q) => q.power == DemoPower.skipAll);

  int get length => questions.length;

  /// Şık sayısı ve doğru şık sorudan soruya değişir (hep "ilk şık" olmasın); Yarıla sorusu
  /// 4 şıklıdır (2 yanlış elenince 2 şık kalır).
  static PowerDemoQuestion _question(int index, DemoPower? power) {
    final optionCount = power == DemoPower.half ? 4 : 3;
    return PowerDemoQuestion(
      id: 'q${index + 1}',
      optionCount: optionCount,
      correctIndex:
          _correctIndices[index % _correctIndices.length] % optionCount,
      hasHint: power == DemoPower.hint,
      power: power,
    );
  }

  static const _correctIndices = [1, 2, 2, 0, 1, 0, 2, 1, 0];
}
