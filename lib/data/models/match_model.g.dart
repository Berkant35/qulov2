// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
  matchId: json['match_id'] as String,
  matchedAt: json['matched_at'] as String,
  user: json['user'] == null
      ? null
      : MatchUserModel.fromJson(json['user'] as Map<String, dynamic>),
  mediaEnabledByUser1: json['media_enabled_by_user1'] as bool? ?? false,
  mediaEnabledByUser2: json['media_enabled_by_user2'] as bool? ?? false,
  lastMessage: json['last_message'] as String?,
  lastMessageSentAt: json['last_message_sent_at'] as String?,
  lastMessageSenderId: json['last_message_sender_id'] as String?,
  unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'match_id': instance.matchId,
      'matched_at': instance.matchedAt,
      'user': instance.user,
      'media_enabled_by_user1': instance.mediaEnabledByUser1,
      'media_enabled_by_user2': instance.mediaEnabledByUser2,
      'last_message': instance.lastMessage,
      'last_message_sent_at': instance.lastMessageSentAt,
      'last_message_sender_id': instance.lastMessageSenderId,
      'unread_count': instance.unreadCount,
    };

MatchUserModel _$MatchUserModelFromJson(Map<String, dynamic> json) =>
    MatchUserModel(
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      age: (json['age'] as num?)?.toInt(),
      city: json['city'] as String?,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bio: json['bio'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] as String?,
    );

Map<String, dynamic> _$MatchUserModelToJson(MatchUserModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'age': instance.age,
      'city': instance.city,
      'photos': instance.photos,
      'bio': instance.bio,
      'is_online': instance.isOnline,
      'last_seen': instance.lastSeen,
    };
