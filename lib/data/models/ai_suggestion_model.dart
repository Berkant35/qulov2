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
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? locale;

  const AiSuggestionModel({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
    this.hint,
    this.category,
    this.locale,
  });

  AiSuggestionModel withLocale(String locale) => AiSuggestionModel(
    questionText: questionText,
    answers: answers,
    correctAnswer: correctAnswer,
    hint: hint,
    category: category,
    locale: locale,
  );

  factory AiSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$AiSuggestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$AiSuggestionModelToJson(this);

  @override
  List<Object?> get props => [questionText];
}
