// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionStatsModel _$QuestionStatsModelFromJson(Map<String, dynamic> json) =>
    QuestionStatsModel(
      correct: (json['correct'] as num).toInt(),
      wrong: (json['wrong'] as num).toInt(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      successRate: (json['success_rate'] as num).toInt(),
      solveCount: (json['solve_count'] as num).toInt(),
      avgTime: (json['avg_time'] as num).toInt(),
      greenEarned: (json['green_earned'] as num).toInt(),
      answerDistribution: json['answer_distribution'] as Map<String, dynamic>,
      powers: json['powers'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$QuestionStatsModelToJson(QuestionStatsModel instance) =>
    <String, dynamic>{
      'correct': instance.correct,
      'wrong': instance.wrong,
      'total_attempts': instance.totalAttempts,
      'success_rate': instance.successRate,
      'solve_count': instance.solveCount,
      'avg_time': instance.avgTime,
      'green_earned': instance.greenEarned,
      'answer_distribution': instance.answerDistribution,
      'powers': instance.powers,
    };

QuestionAnalyticsItem _$QuestionAnalyticsItemFromJson(
  Map<String, dynamic> json,
) => QuestionAnalyticsItem(
  orderNum: (json['order_num'] as num).toInt(),
  questionText: json['question_text'] as String,
  category: json['category'] as String?,
  timeLimit: (json['time_limit'] as num).toInt(),
  stats: QuestionStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
  difficultyBadge: json['difficulty_badge'] as String,
);

Map<String, dynamic> _$QuestionAnalyticsItemToJson(
  QuestionAnalyticsItem instance,
) => <String, dynamic>{
  'order_num': instance.orderNum,
  'question_text': instance.questionText,
  'category': instance.category,
  'time_limit': instance.timeLimit,
  'stats': instance.stats,
  'difficulty_badge': instance.difficultyBadge,
};

QuestionAnalyticsTotals _$QuestionAnalyticsTotalsFromJson(
  Map<String, dynamic> json,
) => QuestionAnalyticsTotals(
  totalSolveCount: (json['total_solve_count'] as num).toInt(),
  totalGreenEarned: (json['total_green_earned'] as num).toInt(),
  overallSuccessRate: (json['overall_success_rate'] as num).toInt(),
  bestQuestionOrder: (json['best_question_order'] as num?)?.toInt(),
);

Map<String, dynamic> _$QuestionAnalyticsTotalsToJson(
  QuestionAnalyticsTotals instance,
) => <String, dynamic>{
  'total_solve_count': instance.totalSolveCount,
  'total_green_earned': instance.totalGreenEarned,
  'overall_success_rate': instance.overallSuccessRate,
  'best_question_order': instance.bestQuestionOrder,
};

QuestionAnalyticsResponse _$QuestionAnalyticsResponseFromJson(
  Map<String, dynamic> json,
) => QuestionAnalyticsResponse(
  questions: (json['questions'] as List<dynamic>)
      .map((e) => QuestionAnalyticsItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totals: QuestionAnalyticsTotals.fromJson(
    json['totals'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$QuestionAnalyticsResponseToJson(
  QuestionAnalyticsResponse instance,
) => <String, dynamic>{
  'questions': instance.questions,
  'totals': instance.totals,
};
