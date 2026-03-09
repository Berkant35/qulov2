// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      campaignId: json['campaign_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'campaign_id': instance.campaignId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'image_url': instance.imageUrl,
      'action_url': instance.actionUrl,
      'action_label': instance.actionLabel,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
    };
