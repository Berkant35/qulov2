import 'package:qulo_v2/providers/quiz_provider.dart';

/// Guc bari ve rescue teklifi arasinda PAYLASILAN kurallar — iki yerde ayri
/// yazilirsa kacinilmaz olarak birbirinden ayrisir (bu fazda duzelttigimiz
/// fiyat bug'i tam olarak boyle olusmustu).

/// Cozulmemis soru sayisi (su anki soru dahil).
int remainingQuestionCount(QuizState quiz) {
  final total = quiz.totalQuestions;
  if (total <= 0) return 1;
  final current = quiz.currentQuestion?.questionNumber ?? 1;
  return (total - current + 1).clamp(1, total);
}

/// SKIP_ALL teklif edilsin mi?
///
/// Sadece kalan sorulari tek tek gecmekten UCUZ oldugunda. 2 soruluk quizde
/// 2xSKIP=20 iken SKIP_ALL=30 — ayni sonuc, %50 daha pahali. Carpan ikisine de
/// uygulandigi icin sadelesir: SKIP_ALL ancak 4+ soruda kazaniyor, 3 soruda basabas.
/// Fiyat henuz yuklenmediyse gizlenir — yanlis teklif gostermektense hic gosterme.
bool shouldOfferSkipAll(QuizState quiz) {
  final skipCost = quiz.purpleCostOf('SKIP');
  final skipAllCost = quiz.purpleCostOf('SKIP_ALL');
  if (skipCost <= 0 || skipAllCost <= 0) return false;
  return skipAllCost < remainingQuestionCount(quiz) * skipCost;
}
