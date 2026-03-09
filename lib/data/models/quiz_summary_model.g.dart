// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizSummaryModel _$QuizSummaryModelFromJson(Map<String, dynamic> json) =>
    QuizSummaryModel(
      sessionId: json['session_id'] as String,
      solverId: json['solver_id'] as String,
      totalQuestions: (json['total_questions'] as num).toInt(),
      totalCorrect: (json['total_correct'] as num).toInt(),
      totalTimeSpent: (json['total_time_spent'] as num?)?.toInt(),
      powersUsed: json['powers_used'] as Map<String, dynamic>?,
      totalPowersUsed: (json['total_powers_used'] as num).toInt(),
      performanceBadge: json['performance_badge'] as String,
      completedAt: json['completed_at'] as String?,
    );

Map<String, dynamic> _$QuizSummaryModelToJson(QuizSummaryModel instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'solver_id': instance.solverId,
      'total_questions': instance.totalQuestions,
      'total_correct': instance.totalCorrect,
      'total_time_spent': instance.totalTimeSpent,
      'powers_used': instance.powersUsed,
      'total_powers_used': instance.totalPowersUsed,
      'performance_badge': instance.performanceBadge,
      'completed_at': instance.completedAt,
    };
