import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question_analytics_model.g.dart';

@JsonSerializable()
class QuestionStatsModel extends Equatable {
  final int correct;
  final int wrong;
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  @JsonKey(name: 'success_rate')
  final int successRate;
  @JsonKey(name: 'solve_count')
  final int solveCount;
  @JsonKey(name: 'avg_time')
  final int avgTime;
  @JsonKey(name: 'green_earned')
  final int greenEarned;
  @JsonKey(name: 'answer_distribution')
  final Map<String, dynamic> answerDistribution;
  final Map<String, dynamic> powers;

  const QuestionStatsModel({
    required this.correct,
    required this.wrong,
    required this.totalAttempts,
    required this.successRate,
    required this.solveCount,
    required this.avgTime,
    required this.greenEarned,
    required this.answerDistribution,
    required this.powers,
  });

  factory QuestionStatsModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionStatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionStatsModelToJson(this);

  @override
  List<Object?> get props => [solveCount, successRate];
}

@JsonSerializable()
class QuestionAnalyticsItem extends Equatable {
  @JsonKey(name: 'order_num')
  final int orderNum;
  @JsonKey(name: 'question_text')
  final String questionText;
  final String? category;
  @JsonKey(name: 'time_limit')
  final int timeLimit;
  final QuestionStatsModel stats;
  @JsonKey(name: 'difficulty_badge')
  final String difficultyBadge;

  const QuestionAnalyticsItem({
    required this.orderNum,
    required this.questionText,
    this.category,
    required this.timeLimit,
    required this.stats,
    required this.difficultyBadge,
  });

  factory QuestionAnalyticsItem.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnalyticsItemFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnalyticsItemToJson(this);

  @override
  List<Object?> get props => [orderNum];
}

@JsonSerializable()
class QuestionAnalyticsTotals extends Equatable {
  @JsonKey(name: 'total_solve_count')
  final int totalSolveCount;
  @JsonKey(name: 'total_green_earned')
  final int totalGreenEarned;
  @JsonKey(name: 'overall_success_rate')
  final int overallSuccessRate;
  @JsonKey(name: 'best_question_order')
  final int? bestQuestionOrder;

  const QuestionAnalyticsTotals({
    required this.totalSolveCount,
    required this.totalGreenEarned,
    required this.overallSuccessRate,
    this.bestQuestionOrder,
  });

  factory QuestionAnalyticsTotals.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnalyticsTotalsFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnalyticsTotalsToJson(this);

  @override
  List<Object?> get props => [totalSolveCount];
}

@JsonSerializable()
class QuestionAnalyticsResponse extends Equatable {
  final List<QuestionAnalyticsItem> questions;
  final QuestionAnalyticsTotals totals;

  const QuestionAnalyticsResponse({
    required this.questions,
    required this.totals,
  });

  factory QuestionAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnalyticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnalyticsResponseToJson(this);

  @override
  List<Object?> get props => [questions];
}
