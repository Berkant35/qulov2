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

  const ChatQuestionModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    this.hasUnmatchRisk = false,
    this.diamondCost = 5,
    this.answeredOption,
    this.isCorrect,
    this.answeredAt,
    required this.createdAt,
  });

  factory ChatQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatQuestionModelToJson(this);

  bool get isAnswered => answeredOption != null;

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class ChatQuestionAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  final bool unmatched;

  const ChatQuestionAnswerResponse({
    required this.isCorrect,
    required this.unmatched,
  });

  factory ChatQuestionAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionAnswerResponseFromJson(json);

  @override
  List<Object?> get props => [isCorrect, unmatched];
}
