// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocaleContent _$LocaleContentFromJson(Map<String, dynamic> json) =>
    LocaleContent(
      title: json['title'] as String,
      body: json['body'] as String,
      ctaLabel: json['cta_label'] as String? ?? '',
    );

Map<String, dynamic> _$LocaleContentToJson(LocaleContent instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      'cta_label': instance.ctaLabel,
    };

PageMessageModel _$PageMessageModelFromJson(Map<String, dynamic> json) =>
    PageMessageModel(
      id: json['id'] as String,
      page: json['page'] as String,
      displayType: json['display_type'] as String,
      content: (json['content'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, LocaleContent.fromJson(e as Map<String, dynamic>)),
      ),
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      frequency: json['frequency'] as String,
      priority: (json['priority'] as num).toInt(),
    );

Map<String, dynamic> _$PageMessageModelToJson(PageMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'page': instance.page,
      'display_type': instance.displayType,
      'content': instance.content,
      'image_url': instance.imageUrl,
      'action_url': instance.actionUrl,
      'frequency': instance.frequency,
      'priority': instance.priority,
    };
