// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConvertResponse _$ConvertResponseFromJson(Map<String, dynamic> json) =>
    ConvertResponse(
      purpleReceived: (json['purple_received'] as num).toInt(),
      newBalance: DiamondBalance.fromJson(
        json['new_balance'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ConvertResponseToJson(ConvertResponse instance) =>
    <String, dynamic>{
      'purple_received': instance.purpleReceived,
      'new_balance': instance.newBalance,
    };

BuyPowerResponse _$BuyPowerResponseFromJson(Map<String, dynamic> json) =>
    BuyPowerResponse(
      newCount: (json['new_count'] as num).toInt(),
      newBalance: DiamondBalance.fromJson(
        json['new_balance'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BuyPowerResponseToJson(BuyPowerResponse instance) =>
    <String, dynamic>{
      'new_count': instance.newCount,
      'new_balance': instance.newBalance,
    };

PowerInventoryItem _$PowerInventoryItemFromJson(Map<String, dynamic> json) =>
    PowerInventoryItem(
      powerName: json['power_name'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$PowerInventoryItemToJson(PowerInventoryItem instance) =>
    <String, dynamic>{
      'power_name': instance.powerName,
      'count': instance.count,
    };

InventoryResponse _$InventoryResponseFromJson(Map<String, dynamic> json) =>
    InventoryResponse(
      inventory: (json['inventory'] as List<dynamic>)
          .map((e) => PowerInventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InventoryResponseToJson(InventoryResponse instance) =>
    <String, dynamic>{'inventory': instance.inventory};

ExchangeRatePower _$ExchangeRatePowerFromJson(Map<String, dynamic> json) =>
    ExchangeRatePower(
      name: json['name'] as String,
      baseCost: (json['base_cost'] as num).toInt(),
      greenCost: (json['green_cost'] as num).toInt(),
      purpleCost: (json['purple_cost'] as num).toInt(),
      accuracyRate: (json['accuracy_rate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ExchangeRatePowerToJson(ExchangeRatePower instance) =>
    <String, dynamic>{
      'name': instance.name,
      'base_cost': instance.baseCost,
      'green_cost': instance.greenCost,
      'purple_cost': instance.purpleCost,
      'accuracy_rate': instance.accuracyRate,
    };

RatesResponse _$RatesResponseFromJson(Map<String, dynamic> json) =>
    RatesResponse(
      convertRatio: (json['convert_ratio'] as num).toInt(),
      powers: (json['powers'] as List<dynamic>)
          .map((e) => ExchangeRatePower.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RatesResponseToJson(RatesResponse instance) =>
    <String, dynamic>{
      'convert_ratio': instance.convertRatio,
      'powers': instance.powers,
    };
