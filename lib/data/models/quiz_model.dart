import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quiz_model.g.dart';

@JsonSerializable()
class QuizStartResponse extends Equatable {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'total_questions')
  final int totalQuestions;

  const QuizStartResponse({
    required this.sessionId,
    required this.totalQuestions,
  });

  factory QuizStartResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizStartResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizStartResponseToJson(this);

  @override
  List<Object?> get props => [sessionId];
}

@JsonSerializable()
class QuizQuestionModel extends Equatable {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'question_number')
  final int questionNumber;
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'question_id')
  final String questionId;
  @JsonKey(name: 'question_text')
  final String questionText;
  final List<QuizAnswerOption> answers;
  @JsonKey(name: 'has_hint')
  final bool hasHint;
  @JsonKey(name: 'time_limit_seconds')
  final int timeLimitSeconds;

  const QuizQuestionModel({
    required this.sessionId,
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionId,
    required this.questionText,
    required this.answers,
    this.hasHint = false,
    this.timeLimitSeconds = 30,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuizQuestionModelToJson(this);

  @override
  List<Object?> get props => [sessionId, questionNumber];
}

@JsonSerializable()
class QuizAnswerOption extends Equatable {
  final int index;
  final String text;

  const QuizAnswerOption({required this.index, required this.text});

  factory QuizAnswerOption.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerOptionFromJson(json);
  Map<String, dynamic> toJson() => _$QuizAnswerOptionToJson(this);

  @override
  List<Object?> get props => [index, text];
}

@JsonSerializable()
class QuizAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  final bool? matched;
  @JsonKey(name: 'next_question')
  final int? nextQuestion;
  @JsonKey(name: 'session_status')
  final String? sessionStatus;
  @JsonKey(name: 'power_result')
  final Map<String, dynamic>? powerResult;
  @JsonKey(name: 'awaiting_answer')
  final bool? awaitingAnswer;

  const QuizAnswerResponse({
    this.isCorrect,
    this.matched,
    this.nextQuestion,
    this.sessionStatus,
    this.powerResult,
    this.awaitingAnswer,
  });

  factory QuizAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizAnswerResponseToJson(this);

  @override
  List<Object?> get props => [isCorrect, sessionStatus];
}

@JsonSerializable()
class QuizResultModel extends Equatable {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'solver_id')
  final String solverId;
  @JsonKey(name: 'target_id')
  final String targetId;
  final String status;
  @JsonKey(name: 'current_q')
  final int currentQ;
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  final List<Map<String, dynamic>> answers;

  const QuizResultModel({
    required this.sessionId,
    required this.solverId,
    required this.targetId,
    required this.status,
    required this.currentQ,
    required this.totalQuestions,
    required this.expiresAt,
    this.completedAt,
    required this.answers,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) =>
      _$QuizResultModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuizResultModelToJson(this);

  @override
  List<Object?> get props => [sessionId];
}
