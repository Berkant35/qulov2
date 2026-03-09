// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReferralStats _$ReferralStatsFromJson(Map<String, dynamic> json) =>
    ReferralStats(
      total: (json['total'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      remaining: (json['remaining'] as num).toInt(),
    );

Map<String, dynamic> _$ReferralStatsToJson(ReferralStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'pending': instance.pending,
      'completed': instance.completed,
      'remaining': instance.remaining,
    };

ReferralItem _$ReferralItemFromJson(Map<String, dynamic> json) => ReferralItem(
  id: json['id'] as String,
  refereeName: json['refereeName'] as String,
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
  completedAt: json['completedAt'] as String?,
);

Map<String, dynamic> _$ReferralItemToJson(ReferralItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'refereeName': instance.refereeName,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'completedAt': instance.completedAt,
    };

ValidateCodeResponse _$ValidateCodeResponseFromJson(
  Map<String, dynamic> json,
) => ValidateCodeResponse(
  valid: json['valid'] as bool,
  referrerName: json['referrerName'] as String?,
);

Map<String, dynamic> _$ValidateCodeResponseToJson(
  ValidateCodeResponse instance,
) => <String, dynamic>{
  'valid': instance.valid,
  'referrerName': instance.referrerName,
};
