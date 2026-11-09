import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';

class QuizState {
  final String? sessionId;
  final int totalQuestions;
  final QuizQuestionModel? currentQuestion;
  final QuizAnswerResponse? lastAnswer;
  final bool isLoading;
  final AppFailure? failure;

  /// Sunucudan gelen efektif guc fiyatlari (soru sayisi carpani uygulanmis).
  /// TEK DOGRU KAYNAK — client burada hesap yapmaz.
  final Map<String, SessionPowerCost> powerCosts;

  /// Su anki soruda kullanilmis gucler. Sunucu ucretlendirmeyi zaten reddediyor;
  /// bu, butonu kapatarak kullaniciya geri bildirim veriyor.
  final Set<String> usedPowers;

  const QuizState({
    this.sessionId,
    this.totalQuestions = 0,
    this.currentQuestion,
    this.lastAnswer,
    this.isLoading = false,
    this.failure,
    this.powerCosts = const {},
    this.usedPowers = const {},
  });

  /// Guc icin efektif mor elmas maliyeti. Bilinmiyorsa 0 (fiyat gosterilmez).
  int purpleCostOf(String powerName) => powerCosts[powerName]?.purple ?? 0;

  int greenCostOf(String powerName) => powerCosts[powerName]?.green ?? 0;

  QuizState copyWith({
    String? sessionId,
    int? totalQuestions,
    QuizQuestionModel? currentQuestion,
    QuizAnswerResponse? lastAnswer,
    bool? isLoading,
    AppFailure? failure,
    Map<String, SessionPowerCost>? powerCosts,
    Set<String>? usedPowers,
  }) {
    return QuizState(
      sessionId: sessionId ?? this.sessionId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastAnswer: lastAnswer,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      powerCosts: powerCosts ?? this.powerCosts,
      usedPowers: usedPowers ?? this.usedPowers,
    );
  }
}
