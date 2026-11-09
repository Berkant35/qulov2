import 'package:qulo_v2/features/quiz/domain/skip_all_offer.dart';
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

/// SKIP_ALL teklif edilsin mi? Kural `skipAllOffered`ta (gercek quiz + guc demosu ortak);
/// burasi sadece oturumun fiyatlarini ve kalan soru sayisini verir.
/// Fiyat henuz yuklenmediyse gizlenir — yanlis teklif gostermektense hic gosterme.
bool shouldOfferSkipAll(QuizState quiz) => skipAllOffered(
  skipCost: quiz.purpleCostOf('SKIP'),
  skipAllCost: quiz.purpleCostOf('SKIP_ALL'),
  remaining: remainingQuestionCount(quiz),
);
