import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quiz_summary_model.g.dart';

@JsonSerializable()
class QuizSummaryModel extends Equatable {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'solver_id')
  final String solverId;
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'total_correct')
  final int totalCorrect;
  @JsonKey(name: 'total_time_spent')
  final int? totalTimeSpent;
  @JsonKey(name: 'powers_used')
  final Map<String, dynamic>? powersUsed;
  @JsonKey(name: 'total_powers_used')
  final int totalPowersUsed;
  @JsonKey(name: 'performance_badge')
  final String performanceBadge;
  @JsonKey(name: 'completed_at')
  final String? completedAt;

  const QuizSummaryModel({
    required this.sessionId,
    required this.solverId,
    required this.totalQuestions,
    required this.totalCorrect,
    this.totalTimeSpent,
    this.powersUsed,
    required this.totalPowersUsed,
    required this.performanceBadge,
    this.completedAt,
  });

  factory QuizSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$QuizSummaryModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuizSummaryModelToJson(this);

  @override
  List<Object?> get props => [sessionId];
}
