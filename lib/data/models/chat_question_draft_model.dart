import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_question_draft_model.g.dart';

@JsonSerializable()
class ChatQuestionDraftModel extends Equatable {
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

  const ChatQuestionDraftModel({
    required this.id,
    required this.questionText,
    this.optionCount = 2,
    required this.optionA,
    required this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    this.timeLimitSeconds = 30,
    this.hintText,
    this.hasUnmatchRisk = false,
    this.hasChatLock = false,
    required this.createdAt,
  });

  factory ChatQuestionDraftModel.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionDraftModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatQuestionDraftModelToJson(this);

  @override
  List<Object?> get props => [id];
}
