// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  matchId: json['match_id'] as String,
  senderId: json['sender_id'] as String,
  content: json['content'] as String,
  isImage: json['is_image'] as bool? ?? false,
  readAt: json['read_at'] as String?,
  deletedAt: json['deleted_at'] as String?,
  audioUrl: json['audio_url'] as String?,
  audioDurationSeconds: (json['audio_duration_seconds'] as num?)?.toInt(),
  reactions: (json['reactions'] as List<dynamic>?)
      ?.map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'is_image': instance.isImage,
      'read_at': instance.readAt,
      'deleted_at': instance.deletedAt,
      'audio_url': instance.audioUrl,
      'audio_duration_seconds': instance.audioDurationSeconds,
      'reactions': instance.reactions,
      'created_at': instance.createdAt,
    };

MessageReaction _$MessageReactionFromJson(Map<String, dynamic> json) =>
    MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['user_id'] as String,
    );


MessagesResponse _$MessagesResponseFromJson(Map<String, dynamic> json) =>
    MessagesResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$MessagesResponseToJson(MessagesResponse instance) =>
    <String, dynamic>{
      'messages': instance.messages,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
