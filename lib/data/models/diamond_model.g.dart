// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diamond_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiamondBalance _$DiamondBalanceFromJson(Map<String, dynamic> json) =>
    DiamondBalance(
      green: (json['green'] as num).toInt(),
      purple: (json['purple'] as num).toInt(),
    );

Map<String, dynamic> _$DiamondBalanceToJson(DiamondBalance instance) =>
    <String, dynamic>{'green': instance.green, 'purple': instance.purple};

DiamondTransaction _$DiamondTransactionFromJson(Map<String, dynamic> json) =>
    DiamondTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      reason: json['reason'] as String,
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$DiamondTransactionToJson(DiamondTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'amount': instance.amount,
      'reason': instance.reason,
      'reference_id': instance.referenceId,
      'created_at': instance.createdAt,
    };

DiamondHistoryResponse _$DiamondHistoryResponseFromJson(
  Map<String, dynamic> json,
) => DiamondHistoryResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => DiamondTransaction.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$DiamondHistoryResponseToJson(
  DiamondHistoryResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};
