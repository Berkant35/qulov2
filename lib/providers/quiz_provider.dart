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

  const QuizState({
    this.sessionId,
    this.totalQuestions = 0,
    this.currentQuestion,
    this.lastAnswer,
    this.isLoading = false,
    this.failure,
  });

  QuizState copyWith({
    String? sessionId,
    int? totalQuestions,
    QuizQuestionModel? currentQuestion,
    QuizAnswerResponse? lastAnswer,
    bool? isLoading,
    AppFailure? failure,
  }) {
    return QuizState(
      sessionId: sessionId ?? this.sessionId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastAnswer: lastAnswer,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
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
      success: (question) => state = state.copyWith(currentQuestion: question, isLoading: false),
      failure: (f) => state = state.copyWith(isLoading: false, failure: f),
    );
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
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> rescue() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).rescueWithSkip(sessionId);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> fail() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).failSession(sessionId);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
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
