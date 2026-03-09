// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDetailsModel _$UserDetailsModelFromJson(Map<String, dynamic> json) =>
    UserDetailsModel(
      height: (json['height'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toInt(),
      zodiac: json['zodiac'] as String?,
      job: json['job'] as String?,
      school: json['school'] as String?,
      smoking: json['smoking'] as String?,
      alcohol: json['alcohol'] as String?,
      pets: json['pets'] as String?,
      musicType: json['music_type'] as String?,
      personality: json['personality'] as String?,
    );

Map<String, dynamic> _$UserDetailsModelToJson(UserDetailsModel instance) =>
    <String, dynamic>{
      'height': instance.height,
      'weight': instance.weight,
      'zodiac': instance.zodiac,
      'job': instance.job,
      'school': instance.school,
      'smoking': instance.smoking,
      'alcohol': instance.alcohol,
      'pets': instance.pets,
      'music_type': instance.musicType,
      'personality': instance.personality,
    };
