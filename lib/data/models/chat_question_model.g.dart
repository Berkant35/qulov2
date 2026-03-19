// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatQuestionModel _$ChatQuestionModelFromJson(Map<String, dynamic> json) =>
    ChatQuestionModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      questionText: json['question_text'] as String,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      hasUnmatchRisk: json['has_unmatch_risk'] as bool? ?? false,
      diamondCost: (json['diamond_cost'] as num?)?.toInt() ?? 5,
      answeredOption: json['answered_option'] as String?,
      isCorrect: json['is_correct'] as bool?,
      answeredAt: json['answered_at'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ChatQuestionModelToJson(ChatQuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'sender_id': instance.senderId,
      'question_text': instance.questionText,
      'option_a': instance.optionA,
      'option_b': instance.optionB,
      'has_unmatch_risk': instance.hasUnmatchRisk,
      'diamond_cost': instance.diamondCost,
      'answered_option': instance.answeredOption,
      'is_correct': instance.isCorrect,
      'answered_at': instance.answeredAt,
      'created_at': instance.createdAt,
    };

ChatQuestionAnswerResponse _$ChatQuestionAnswerResponseFromJson(
  Map<String, dynamic> json,
) => ChatQuestionAnswerResponse(
  isCorrect: json['is_correct'] as bool,
  unmatched: json['unmatched'] as bool,
);

Map<String, dynamic> _$ChatQuestionAnswerResponseToJson(
  ChatQuestionAnswerResponse instance,
) => <String, dynamic>{
  'is_correct': instance.isCorrect,
  'unmatched': instance.unmatched,
};
