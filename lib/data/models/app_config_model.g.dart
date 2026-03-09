// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigModel _$AppConfigModelFromJson(Map<String, dynamic> json) =>
    AppConfigModel(
      minVersion: json['minVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      storeUrl: json['storeUrl'] as String,
      isMaintenance: json['isMaintenance'] as bool,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      isForceUpdateEnabled: json['isForceUpdateEnabled'] as bool,
    );

Map<String, dynamic> _$AppConfigModelToJson(AppConfigModel instance) =>
    <String, dynamic>{
      'minVersion': instance.minVersion,
      'latestVersion': instance.latestVersion,
      'storeUrl': instance.storeUrl,
      'isMaintenance': instance.isMaintenance,
      'maintenanceMessage': instance.maintenanceMessage,
      'isForceUpdateEnabled': instance.isForceUpdateEnabled,
    };
