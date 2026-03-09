import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'power_model.g.dart';

@JsonSerializable()
class PowerModel extends Equatable {
  final String id;
  final String name;
  @JsonKey(name: 'base_cost')
  final int baseCost;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const PowerModel({
    required this.id,
    required this.name,
    required this.baseCost,
    this.isActive = true,
  });

  factory PowerModel.fromJson(Map<String, dynamic> json) =>
      _$PowerModelFromJson(json);
  Map<String, dynamic> toJson() => _$PowerModelToJson(this);

  @override
  List<Object?> get props => [id, name];
}
