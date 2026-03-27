import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_question_model.g.dart';

@JsonSerializable()
class ChatQuestionModel extends Equatable {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'option_a')
  final String optionA;
  @JsonKey(name: 'option_b')
  final String optionB;
  @JsonKey(name: 'has_unmatch_risk')
  final bool hasUnmatchRisk;
  @JsonKey(name: 'diamond_cost')
  final int diamondCost;
  @JsonKey(name: 'answered_option')
  final String? answeredOption;
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  @JsonKey(name: 'answered_at')
  final String? answeredAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'option_count')
  final int optionCount;
  @JsonKey(name: 'option_c')
  final String? optionC;
  @JsonKey(name: 'option_d')
  final String? optionD;
  @JsonKey(name: 'time_limit_seconds')
  final int timeLimitSeconds;
  @JsonKey(name: 'hint_text')
  final String? hintText;
  @JsonKey(name: 'reward_media_url')
  final String? rewardMediaUrl;
  @JsonKey(name: 'reward_media_type')
  final String? rewardMediaType;
  @JsonKey(name: 'has_chat_lock')
  final bool hasChatLock;
  @JsonKey(name: 'has_power_block')
  final bool hasPowerBlock;
  @JsonKey(name: 'power_block_removed')
  final bool powerBlockRemoved;
  @JsonKey(name: 'powers_used')
  final List<dynamic> powersUsed;

  const ChatQuestionModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    this.hasUnmatchRisk = false,
    this.diamondCost = 0,
    this.answeredOption,
    this.isCorrect,
    this.answeredAt,
    required this.createdAt,
    this.optionCount = 2,
    this.optionC,
    this.optionD,
    this.timeLimitSeconds = 30,
    this.hintText,
    this.rewardMediaUrl,
    this.rewardMediaType,
    this.hasChatLock = false,
    this.hasPowerBlock = false,
    this.powerBlockRemoved = false,
    this.powersUsed = const [],
  });

  factory ChatQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatQuestionModelToJson(this);

  bool get isAnswered => answeredOption != null;
  bool get hasRewardMedia => rewardMediaUrl != null;
  bool get isPowerBlocked => hasPowerBlock && !powerBlockRemoved;
  List<String> get allOptions {
    if (optionCount == 4) return [optionA, optionB, optionC ?? '', optionD ?? ''];
    return [optionA, optionB];
  }

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(createToJson: false)
class ChatQuestionAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  final bool unmatched;
  @JsonKey(name: 'reward_media_url')
  final String? rewardMediaUrl;
  final ChatQuestionModel? question;
  @JsonKey(name: 'green_reward')
  final int greenReward;
  @JsonKey(name: 'powers_used')
  final List<String> powersUsed;
  @JsonKey(name: 'correct_option')
  final String? correctOption;
  @JsonKey(name: 'answered_option')
  final String? answeredOption;
  @JsonKey(name: 'time_spent')
  final int? timeSpent;

  const ChatQuestionAnswerResponse({
    required this.isCorrect,
    required this.unmatched,
    this.rewardMediaUrl,
    this.question,
    this.greenReward = 0,
    this.powersUsed = const [],
    this.correctOption,
    this.answeredOption,
    this.timeSpent,
  });

  factory ChatQuestionAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionAnswerResponseFromJson(json);

  @override
  List<Object?> get props => [isCorrect, unmatched, rewardMediaUrl, greenReward, powersUsed, correctOption, answeredOption];
}

@JsonSerializable(createToJson: false)
class UsePowerResponse extends Equatable {
  @JsonKey(name: 'power_name')
  final String? powerName;
  @JsonKey(name: 'suggested_option')
  final String? suggestedOption;
  @JsonKey(name: 'eliminated_options')
  final List<String>? eliminatedOptions;
  @JsonKey(name: 'hint_text')
  final String? hintText;
  @JsonKey(name: 'extra_seconds')
  final int? extraSeconds;
  final int? cost;
  @JsonKey(name: 'green_reward')
  final int? greenReward;
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  final ChatQuestionModel? question;
  final bool? skipped;
  final bool? unblocked;

  const UsePowerResponse({
    this.powerName,
    this.suggestedOption,
    this.eliminatedOptions,
    this.hintText,
    this.extraSeconds,
    this.cost,
    this.greenReward,
    this.isCorrect,
    this.question,
    this.skipped,
    this.unblocked,
  });

  factory UsePowerResponse.fromJson(Map<String, dynamic> json) =>
      _$UsePowerResponseFromJson(json);

  @override
  List<Object?> get props => [powerName, suggestedOption, eliminatedOptions];
}

@JsonSerializable(createToJson: false)
class HandleTimeoutResponse extends Equatable {
  @JsonKey(name: 'can_rescue')
  final bool canRescue;
  @JsonKey(name: 'has_power_block')
  final bool hasPowerBlock;

  const HandleTimeoutResponse({
    required this.canRescue,
    required this.hasPowerBlock,
  });

  factory HandleTimeoutResponse.fromJson(Map<String, dynamic> json) =>
      _$HandleTimeoutResponseFromJson(json);

  @override
  List<Object?> get props => [canRescue, hasPowerBlock];
}

@JsonSerializable(createToJson: false)
class ChatQuestionHistoryItem extends Equatable {
  final String id;
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'option_count')
  final int optionCount;
  @JsonKey(name: 'option_a')
  final String optionA;
  @JsonKey(name: 'option_b')
  final String optionB;
  @JsonKey(name: 'option_c')
  final String? optionC;
  @JsonKey(name: 'option_d')
  final String? optionD;
  @JsonKey(name: 'correct_option')
  final String correctOption;
  @JsonKey(name: 'time_limit_seconds')
  final int timeLimitSeconds;
  @JsonKey(name: 'hint_text')
  final String? hintText;
  @JsonKey(name: 'has_unmatch_risk')
  final bool hasUnmatchRisk;
  @JsonKey(name: 'has_chat_lock')
  final bool hasChatLock;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ChatQuestionHistoryItem({
    required this.id,
    required this.questionText,
    required this.optionCount,
    required this.optionA,
    required this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    required this.timeLimitSeconds,
    this.hintText,
    required this.hasUnmatchRisk,
    required this.hasChatLock,
    required this.createdAt,
  });

  factory ChatQuestionHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionHistoryItemFromJson(json);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(createToJson: false)
class ChatQuestionHistoryResponse extends Equatable {
  final List<ChatQuestionHistoryItem> items;
  final int total;
  final int page;
  final int limit;

  const ChatQuestionHistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ChatQuestionHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionHistoryResponseFromJson(json);

  @override
  List<Object?> get props => [items, total];
}
