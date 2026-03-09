import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_details_model.g.dart';

@JsonSerializable()
class UserDetailsModel extends Equatable {
  final int? height;
  final int? weight;
  final String? zodiac;
  final String? job;
  final String? school;
  final String? smoking;
  final String? alcohol;
  final String? pets;
  @JsonKey(name: 'music_type')
  final String? musicType;
  final String? personality;

  const UserDetailsModel({
    this.height,
    this.weight,
    this.zodiac,
    this.job,
    this.school,
    this.smoking,
    this.alcohol,
    this.pets,
    this.musicType,
    this.personality,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserDetailsModelToJson(this);

  @override
  List<Object?> get props => [
        height,
        weight,
        zodiac,
        job,
        school,
        smoking,
        alcohol,
        pets,
        musicType,
        personality,
      ];
}
