import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_suggestion_model.g.dart';

@JsonSerializable()
class AiSuggestionModel extends Equatable {
  @JsonKey(name: 'question_text')
  final String questionText;
  final List<String> answers;
  @JsonKey(name: 'correct_answer')
  final int correctAnswer;
  final String? hint;
  final String? category;

  const AiSuggestionModel({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
    this.hint,
    this.category,
  });

  factory AiSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$AiSuggestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$AiSuggestionModelToJson(this);

  @override
  List<Object?> get props => [questionText];
}
