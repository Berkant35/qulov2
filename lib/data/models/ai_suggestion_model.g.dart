// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiSuggestionModel _$AiSuggestionModelFromJson(Map<String, dynamic> json) =>
    AiSuggestionModel(
      questionText: json['question_text'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      correctAnswer: (json['correct_answer'] as num).toInt(),
      hint: json['hint'] as String?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$AiSuggestionModelToJson(AiSuggestionModel instance) =>
    <String, dynamic>{
      'question_text': instance.questionText,
      'answers': instance.answers,
      'correct_answer': instance.correctAnswer,
      'hint': instance.hint,
      'category': instance.category,
    };
