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
      diamondCost: (json['diamond_cost'] as num?)?.toInt() ?? 0,
      answeredOption: json['answered_option'] as String?,
      isCorrect: json['is_correct'] as bool?,
      answeredAt: json['answered_at'] as String?,
      createdAt: json['created_at'] as String,
      optionCount: (json['option_count'] as num?)?.toInt() ?? 2,
      optionC: json['option_c'] as String?,
      optionD: json['option_d'] as String?,
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt() ?? 30,
      hintText: json['hint_text'] as String?,
      rewardMediaUrl: json['reward_media_url'] as String?,
      rewardMediaType: json['reward_media_type'] as String?,
      hasChatLock: json['has_chat_lock'] as bool? ?? false,
      hasPowerBlock: json['has_power_block'] as bool? ?? false,
      powerBlockRemoved: json['power_block_removed'] as bool? ?? false,
      powersUsed: json['powers_used'] as List<dynamic>? ?? const [],
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
      'option_count': instance.optionCount,
      'option_c': instance.optionC,
      'option_d': instance.optionD,
      'time_limit_seconds': instance.timeLimitSeconds,
      'hint_text': instance.hintText,
      'reward_media_url': instance.rewardMediaUrl,
      'reward_media_type': instance.rewardMediaType,
      'has_chat_lock': instance.hasChatLock,
      'has_power_block': instance.hasPowerBlock,
      'power_block_removed': instance.powerBlockRemoved,
      'powers_used': instance.powersUsed,
    };

ChatQuestionAnswerResponse _$ChatQuestionAnswerResponseFromJson(
  Map<String, dynamic> json,
) => ChatQuestionAnswerResponse(
  isCorrect: json['is_correct'] as bool,
  unmatched: json['unmatched'] as bool,
  rewardMediaUrl: json['reward_media_url'] as String?,
  question: json['question'] == null
      ? null
      : ChatQuestionModel.fromJson(json['question'] as Map<String, dynamic>),
);

UsePowerResponse _$UsePowerResponseFromJson(Map<String, dynamic> json) =>
    UsePowerResponse(
      powerName: json['power_name'] as String?,
      suggestedOption: json['suggested_option'] as String?,
      eliminatedOptions: (json['eliminated_options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hintText: json['hint_text'] as String?,
      extraSeconds: (json['extra_seconds'] as num?)?.toInt(),
      cost: (json['cost'] as num?)?.toInt(),
      greenReward: (json['green_reward'] as num?)?.toInt(),
      isCorrect: json['is_correct'] as bool?,
      question: json['question'] == null
          ? null
          : ChatQuestionModel.fromJson(
              json['question'] as Map<String, dynamic>,
            ),
      skipped: json['skipped'] as bool?,
      unblocked: json['unblocked'] as bool?,
    );

HandleTimeoutResponse _$HandleTimeoutResponseFromJson(
  Map<String, dynamic> json,
) => HandleTimeoutResponse(
  canRescue: json['can_rescue'] as bool,
  hasPowerBlock: json['has_power_block'] as bool,
);

ChatQuestionHistoryItem _$ChatQuestionHistoryItemFromJson(
  Map<String, dynamic> json,
) => ChatQuestionHistoryItem(
  id: json['id'] as String,
  questionText: json['question_text'] as String,
  optionCount: (json['option_count'] as num).toInt(),
  optionA: json['option_a'] as String,
  optionB: json['option_b'] as String,
  optionC: json['option_c'] as String?,
  optionD: json['option_d'] as String?,
  correctOption: json['correct_option'] as String,
  timeLimitSeconds: (json['time_limit_seconds'] as num).toInt(),
  hintText: json['hint_text'] as String?,
  hasUnmatchRisk: json['has_unmatch_risk'] as bool,
  hasChatLock: json['has_chat_lock'] as bool,
  createdAt: json['created_at'] as String,
);

ChatQuestionHistoryResponse _$ChatQuestionHistoryResponseFromJson(
  Map<String, dynamic> json,
) => ChatQuestionHistoryResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => ChatQuestionHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);
