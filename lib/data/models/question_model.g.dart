// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionModel _$QuestionModelFromJson(
  Map<String, dynamic> json,
) => QuestionModel(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  orderNum: (json['order_num'] as num).toInt(),
  questionText: json['question_text'] as String,
  correctAnswer: (json['correct_answer'] as num).toInt(),
  answer1: json['answer_1'] as String,
  answer2: json['answer_2'] as String,
  answer3: json['answer_3'] as String,
  answer4: json['answer_4'] as String,
  hintText: json['hint_text'] as String?,
  category: json['category'] as String?,
  locale: json['locale'] as String?,
  timeLimit: (json['time_limit'] as num?)?.toInt() ?? 30,
  statsCorrect: (json['stats_correct'] as num?)?.toInt() ?? 0,
  statsWrong: (json['stats_wrong'] as num?)?.toInt() ?? 0,
  statsSolveCount: (json['stats_solve_count'] as num?)?.toInt() ?? 0,
  statsTotalTimeSpent: (json['stats_total_time_spent'] as num?)?.toInt() ?? 0,
  statsGreenEarned: (json['stats_green_earned'] as num?)?.toInt() ?? 0,
  statsCopyUsed: (json['stats_copy_used'] as num?)?.toInt() ?? 0,
  statsHalfUsed: (json['stats_half_used'] as num?)?.toInt() ?? 0,
  statsHintUsed: (json['stats_hint_used'] as num?)?.toInt() ?? 0,
  statsTimeExtendUsed: (json['stats_time_extend_used'] as num?)?.toInt() ?? 0,
  statsSkipUsed: (json['stats_skip_used'] as num?)?.toInt() ?? 0,
  statsAnswer1Count: (json['stats_answer_1_count'] as num?)?.toInt() ?? 0,
  statsAnswer2Count: (json['stats_answer_2_count'] as num?)?.toInt() ?? 0,
  statsAnswer3Count: (json['stats_answer_3_count'] as num?)?.toInt() ?? 0,
  statsAnswer4Count: (json['stats_answer_4_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'order_num': instance.orderNum,
      'question_text': instance.questionText,
      'correct_answer': instance.correctAnswer,
      'answer_1': instance.answer1,
      'answer_2': instance.answer2,
      'answer_3': instance.answer3,
      'answer_4': instance.answer4,
      'hint_text': instance.hintText,
      'category': instance.category,
      'time_limit': instance.timeLimit,
      'stats_correct': instance.statsCorrect,
      'stats_wrong': instance.statsWrong,
      'stats_solve_count': instance.statsSolveCount,
      'stats_total_time_spent': instance.statsTotalTimeSpent,
      'stats_green_earned': instance.statsGreenEarned,
      'stats_copy_used': instance.statsCopyUsed,
      'stats_half_used': instance.statsHalfUsed,
      'stats_hint_used': instance.statsHintUsed,
      'stats_time_extend_used': instance.statsTimeExtendUsed,
      'stats_skip_used': instance.statsSkipUsed,
      'stats_answer_1_count': instance.statsAnswer1Count,
      'stats_answer_2_count': instance.statsAnswer2Count,
      'stats_answer_3_count': instance.statsAnswer3Count,
      'stats_answer_4_count': instance.statsAnswer4Count,
      'created_at': instance.createdAt,
      'locale': instance.locale,
    };
