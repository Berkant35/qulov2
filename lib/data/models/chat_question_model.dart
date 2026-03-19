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

  const ChatQuestionAnswerResponse({
    required this.isCorrect,
    required this.unmatched,
    this.rewardMediaUrl,
    this.question,
  });

  factory ChatQuestionAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionAnswerResponseFromJson(json);

  @override
  List<Object?> get props => [isCorrect, unmatched, rewardMediaUrl];
}
