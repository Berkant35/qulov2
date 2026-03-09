// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'power_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PowerModel _$PowerModelFromJson(Map<String, dynamic> json) => PowerModel(
  id: json['id'] as String,
  name: json['name'] as String,
  baseCost: (json['base_cost'] as num).toInt(),
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$PowerModelToJson(PowerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'base_cost': instance.baseCost,
      'is_active': instance.isActive,
    };
