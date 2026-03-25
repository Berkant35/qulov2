// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_question_draft_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatQuestionDraftModel _$ChatQuestionDraftModelFromJson(
  Map<String, dynamic> json,
) => ChatQuestionDraftModel(
  id: json['id'] as String,
  questionText: json['question_text'] as String,
  optionCount: (json['option_count'] as num?)?.toInt() ?? 2,
  optionA: json['option_a'] as String,
  optionB: json['option_b'] as String,
  optionC: json['option_c'] as String?,
  optionD: json['option_d'] as String?,
  correctOption: json['correct_option'] as String,
  timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt() ?? 30,
  hintText: json['hint_text'] as String?,
  hasUnmatchRisk: json['has_unmatch_risk'] as bool? ?? false,
  hasChatLock: json['has_chat_lock'] as bool? ?? false,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$ChatQuestionDraftModelToJson(
  ChatQuestionDraftModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'question_text': instance.questionText,
  'option_count': instance.optionCount,
  'option_a': instance.optionA,
  'option_b': instance.optionB,
  'option_c': instance.optionC,
  'option_d': instance.optionD,
  'correct_option': instance.correctOption,
  'time_limit_seconds': instance.timeLimitSeconds,
  'hint_text': instance.hintText,
  'has_unmatch_risk': instance.hasUnmatchRisk,
  'has_chat_lock': instance.hasChatLock,
  'created_at': instance.createdAt,
};
