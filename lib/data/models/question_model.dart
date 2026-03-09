import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question_model.g.dart';

@JsonSerializable()
class QuestionModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'order_num')
  final int orderNum;
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'correct_answer')
  final int correctAnswer;
  @JsonKey(name: 'answer_1')
  final String answer1;
  @JsonKey(name: 'answer_2')
  final String answer2;
  @JsonKey(name: 'answer_3')
  final String answer3;
  @JsonKey(name: 'answer_4')
  final String answer4;
  @JsonKey(name: 'hint_text')
  final String? hintText;
  @JsonKey(name: 'category')
  final String? category;
  @JsonKey(name: 'time_limit', defaultValue: 30)
  final int timeLimit;
  @JsonKey(name: 'stats_correct')
  final int statsCorrect;
  @JsonKey(name: 'stats_wrong')
  final int statsWrong;
  @JsonKey(name: 'stats_solve_count', defaultValue: 0)
  final int statsSolveCount;
  @JsonKey(name: 'stats_total_time_spent', defaultValue: 0)
  final int statsTotalTimeSpent;
  @JsonKey(name: 'stats_green_earned', defaultValue: 0)
  final int statsGreenEarned;
  @JsonKey(name: 'stats_copy_used', defaultValue: 0)
  final int statsCopyUsed;
  @JsonKey(name: 'stats_half_used', defaultValue: 0)
  final int statsHalfUsed;
  @JsonKey(name: 'stats_hint_used', defaultValue: 0)
  final int statsHintUsed;
  @JsonKey(name: 'stats_time_extend_used', defaultValue: 0)
  final int statsTimeExtendUsed;
  @JsonKey(name: 'stats_skip_used', defaultValue: 0)
  final int statsSkipUsed;
  @JsonKey(name: 'stats_answer_1_count', defaultValue: 0)
  final int statsAnswer1Count;
  @JsonKey(name: 'stats_answer_2_count', defaultValue: 0)
  final int statsAnswer2Count;
  @JsonKey(name: 'stats_answer_3_count', defaultValue: 0)
  final int statsAnswer3Count;
  @JsonKey(name: 'stats_answer_4_count', defaultValue: 0)
  final int statsAnswer4Count;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  final String? locale;

  const QuestionModel({
    required this.id,
    required this.userId,
    required this.orderNum,
    required this.questionText,
    required this.correctAnswer,
    required this.answer1,
    required this.answer2,
    required this.answer3,
    required this.answer4,
    this.hintText,
    this.category,
    this.locale,
    this.timeLimit = 30,
    this.statsCorrect = 0,
    this.statsWrong = 0,
    this.statsSolveCount = 0,
    this.statsTotalTimeSpent = 0,
    this.statsGreenEarned = 0,
    this.statsCopyUsed = 0,
    this.statsHalfUsed = 0,
    this.statsHintUsed = 0,
    this.statsTimeExtendUsed = 0,
    this.statsSkipUsed = 0,
    this.statsAnswer1Count = 0,
    this.statsAnswer2Count = 0,
    this.statsAnswer3Count = 0,
    this.statsAnswer4Count = 0,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);

  @override
  List<Object?> get props => [id, orderNum];
}
