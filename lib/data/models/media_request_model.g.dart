// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaRequestModel _$MediaRequestModelFromJson(Map<String, dynamic> json) =>
    MediaRequestModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String?,
      requesterId: json['requester_id'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String?,
      respondedAt: json['responded_at'] as String?,
    );

Map<String, dynamic> _$MediaRequestModelToJson(MediaRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'requester_id': instance.requesterId,
      'status': instance.status,
      'created_at': instance.createdAt,
      'responded_at': instance.respondedAt,
    };

MediaStatusResponse _$MediaStatusResponseFromJson(Map<String, dynamic> json) =>
    MediaStatusResponse(
      mediaEnabled: json['media_enabled'] as bool,
      myEnabled: json['my_enabled'] as bool,
      otherEnabled: json['other_enabled'] as bool,
      pendingRequest: json['pending_request'] == null
          ? null
          : MediaRequestModel.fromJson(
              json['pending_request'] as Map<String, dynamic>,
            ),
    );

