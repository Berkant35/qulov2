// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_change_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingChangeModel _$PendingChangeModelFromJson(Map<String, dynamic> json) =>
    PendingChangeModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      changeType: json['change_type'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      appliedAt: json['applied_at'] as String?,
    );

Map<String, dynamic> _$PendingChangeModelToJson(PendingChangeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_id': instance.questionId,
      'change_type': instance.changeType,
      'payload': instance.payload,
      'status': instance.status,
      'created_at': instance.createdAt,
      'applied_at': instance.appliedAt,
    };
