// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acquisition_channel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcquisitionChannel _$AcquisitionChannelFromJson(Map<String, dynamic> json) =>
    AcquisitionChannel(
      id: json['id'] as String,
      key: json['key'] as String,
      label: json['label'] as String,
      emoji: json['emoji'] as String?,
      isFreeform: json['is_freeform'] as bool? ?? false,
    );

Map<String, dynamic> _$AcquisitionChannelToJson(AcquisitionChannel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'label': instance.label,
      'emoji': instance.emoji,
      'is_freeform': instance.isFreeform,
    };
