// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizStartResponse _$QuizStartResponseFromJson(Map<String, dynamic> json) =>
    QuizStartResponse(
      sessionId: json['session_id'] as String,
      totalQuestions: (json['total_questions'] as num).toInt(),
    );

Map<String, dynamic> _$QuizStartResponseToJson(QuizStartResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'total_questions': instance.totalQuestions,
    };

QuizQuestionModel _$QuizQuestionModelFromJson(Map<String, dynamic> json) =>
    QuizQuestionModel(
      sessionId: json['session_id'] as String,
      questionNumber: (json['question_number'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => QuizAnswerOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasHint: json['has_hint'] as bool? ?? false,
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$QuizQuestionModelToJson(QuizQuestionModel instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'question_number': instance.questionNumber,
      'total_questions': instance.totalQuestions,
      'question_id': instance.questionId,
      'question_text': instance.questionText,
      'answers': instance.answers,
      'has_hint': instance.hasHint,
      'time_limit_seconds': instance.timeLimitSeconds,
    };

QuizAnswerOption _$QuizAnswerOptionFromJson(Map<String, dynamic> json) =>
    QuizAnswerOption(
      index: (json['index'] as num).toInt(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$QuizAnswerOptionToJson(QuizAnswerOption instance) =>
    <String, dynamic>{'index': instance.index, 'text': instance.text};

QuizAnswerResponse _$QuizAnswerResponseFromJson(Map<String, dynamic> json) =>
    QuizAnswerResponse(
      isCorrect: json['is_correct'] as bool?,
      matched: json['matched'] as bool?,
      nextQuestion: (json['next_question'] as num?)?.toInt(),
      sessionStatus: json['session_status'] as String?,
      powerResult: json['power_result'] as Map<String, dynamic>?,
      awaitingAnswer: json['awaiting_answer'] as bool?,
      canRescue: json['can_rescue'] as bool?,
      badge: json['badge'] as String?,
    );

Map<String, dynamic> _$QuizAnswerResponseToJson(QuizAnswerResponse instance) =>
    <String, dynamic>{
      'is_correct': instance.isCorrect,
      'matched': instance.matched,
      'next_question': instance.nextQuestion,
      'session_status': instance.sessionStatus,
      'power_result': instance.powerResult,
      'awaiting_answer': instance.awaitingAnswer,
      'can_rescue': instance.canRescue,
      'badge': instance.badge,
    };

QuizResultModel _$QuizResultModelFromJson(Map<String, dynamic> json) =>
    QuizResultModel(
      sessionId: json['session_id'] as String,
      solverId: json['solver_id'] as String,
      targetId: json['target_id'] as String,
      status: json['status'] as String,
      currentQ: (json['current_q'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      expiresAt: json['expires_at'] as String,
      completedAt: json['completed_at'] as String?,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$QuizResultModelToJson(QuizResultModel instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'solver_id': instance.solverId,
      'target_id': instance.targetId,
      'status': instance.status,
      'current_q': instance.currentQ,
      'total_questions': instance.totalQuestions,
      'expires_at': instance.expiresAt,
      'completed_at': instance.completedAt,
      'answers': instance.answers,
    };
