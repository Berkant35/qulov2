import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/quiz_state.dart';

export 'package:qulo_v2/providers/quiz_state.dart';

/// Provider GLOBAL (ekran basina degil): her QuizScreen `initMixin`'de [reset]
/// cagirir. Crashlytics iOS 2.0.17 (`quiz_screen.dart:106` `sessionId!`): cozme
/// dugmesine ust uste basilinca iki quiz ekrani acildi; ikincinin [reset]'i
/// birincinin YOLDAKI soru yanitindan once geldi, yanit sifirlanmis duruma
/// yazildi → soru dolu, oturum `null`. Kural: her async yazim, basladigi
/// oturum hala gecerliyse yapilir ([_epoch] + `sessionId` eslesmesi).
class QuizNotifier extends Notifier<QuizState> {
  /// [reset] ve yeni [startSession] artirir; eski isteklerin yanitlari yok sayilir.
  int _epoch = 0;

  @override
  QuizState build() => const QuizState();

  bool _isCurrent(int epoch, String? sessionId) =>
      epoch == _epoch && state.sessionId == sessionId;

  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    final epoch = ++_epoch;
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).startSession(targetId);
    if (epoch != _epoch) return result;
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
    final epoch = _epoch;
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).getCurrentQuestion(sessionId);
    if (!_isCurrent(epoch, sessionId)) return;
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
    final epoch = _epoch;
    final result = await ref.read(quizRepositoryProvider).answerQuestion(
      sessionId,
      selectedAnswer: selectedAnswer,
      powerUsed: powerUsed,
      timeSpent: timeSpent,
    );
    _applyAnswer(result, epoch, sessionId);
    return result;
  }

  Future<Result<QuizAnswerResponse>> rescue({String powerType = 'SKIP'}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final epoch = _epoch;
    final result = await ref.read(quizRepositoryProvider).rescueWithSkip(sessionId, powerType: powerType);
    _applyAnswer(result, epoch, sessionId);
    return result;
  }

  Future<Result<QuizAnswerResponse>> fail() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final epoch = _epoch;
    final result = await ref.read(quizRepositoryProvider).failSession(sessionId);
    _applyAnswer(result, epoch, sessionId);
    return result;
  }

  /// Sadece success'i state'e yansıt — answer/rescue API hatasında state.failure
  /// setlemek QuizErrorView'a yönlendirir; rescue popup'tan paywall'a geçiş bozulur.
  /// Caller (mixin) failure'u Result üzerinden handle eder.
  ///
  /// Eşleşme sunucuda bu yanıtla oluşur (`matched: true`, quiz.service); ürünün
  /// kuzey yıldızı `match_new` ekran değil burada atılır — kutlama ekranı
  /// görülmese de sayılır, reklam kalitesi ve huni optimizasyonu buna bakar.
  ///
  /// Eski oturumun yaniti (ekran degisti) duruma yazilmaz; eslesme olayi yine
  /// atilir — eslesme sunucuda olustu.
  void _applyAnswer(Result<QuizAnswerResponse> result, int epoch, String sessionId) {
    final current = _isCurrent(epoch, sessionId);
    result.when(
      success: (data) {
        if (current) state = state.copyWith(lastAnswer: data);
        if (data.matched == true) {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.matchNew, params: {
            AnalyticsEvents.paramRole: 'solver',
            AnalyticsEvents.paramBadge: data.badge ?? 'none',
          });
        }
      },
      failure: (_) {},
    );
  }

  Future<Result<QuizResultModel>> getResult() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    return ref.read(quizRepositoryProvider).getSessionResult(sessionId);
  }

  void reset() {
    _epoch++;
    state = const QuizState();
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);
