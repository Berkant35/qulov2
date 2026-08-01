import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

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

class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).startSession(targetId);
    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          sessionId: data.sessionId,
          totalQuestions: data.totalQuestions,
          powerCosts: data.powerCosts,
          isLoading: false,
        );
        await fetchCurrentQuestion();
      case Failure(:final failure):
        state = state.copyWith(isLoading: false, failure: failure);
    }
    return result;
  }

  Future<void> fetchCurrentQuestion() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).getCurrentQuestion(sessionId);
    result.when(
      // usedPowers sunucudan gelir — uygulama yeniden baslatilsa da buton durumu dogru.
      success: (question) => state = state.copyWith(
        currentQuestion: question,
        usedPowers: question.usedPowers.toSet(),
        isLoading: false,
      ),
      failure: (f) => state = state.copyWith(isLoading: false, failure: f),
    );
  }

  /// Guc kullanildi — butonu kapat. Sunucu ikinci kullanimi zaten reddediyor
  /// (POWER_ALREADY_USED), bu yalnizca gorsel geri bildirim.
  void markPowerUsed(String powerName) {
    state = state.copyWith(usedPowers: {...state.usedPowers, powerName});
  }

  Future<Result<QuizAnswerResponse>> answer(int? selectedAnswer, {String? powerUsed, int? timeSpent}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).answerQuestion(
      sessionId,
      selectedAnswer: selectedAnswer,
      powerUsed: powerUsed,
      timeSpent: timeSpent,
    );
    // Sadece success'i state'e yansıt — answer/rescue API hatasında state.failure
    // setlemek QuizErrorView'a yönlendirir; rescue popup'tan paywall'a geçiş bozulur.
    // Caller (mixin) failure'u Result üzerinden handle eder.
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> rescue({String powerType = 'SKIP'}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).rescueWithSkip(sessionId, powerType: powerType);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> fail() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).failSession(sessionId);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<QuizResultModel>> getResult() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    return ref.read(quizRepositoryProvider).getSessionResult(sessionId);
  }

  void reset() {
    state = const QuizState();
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);
