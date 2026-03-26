import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_model.g.dart';

@JsonSerializable()
class ReferralStats extends Equatable {
  final int total;
  final int pending;
  final int completed;
  final int remaining;

  const ReferralStats({
    required this.total,
    required this.pending,
    required this.completed,
    required this.remaining,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) =>
      _$ReferralStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ReferralStatsToJson(this);

  @override
  List<Object?> get props => [total, pending, completed, remaining];
}

@JsonSerializable()
class ReferralItem extends Equatable {
  final String id;
  @JsonKey(name: 'refereeName')
  final String refereeName;
  final String status;
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @JsonKey(name: 'completedAt')
  final String? completedAt;

  const ReferralItem({
    required this.id,
    required this.refereeName,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) =>
      _$ReferralItemFromJson(json);
  Map<String, dynamic> toJson() => _$ReferralItemToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class ValidateCodeResponse extends Equatable {
  final bool valid;
  @JsonKey(name: 'referrerName')
  final String? referrerName;

  const ValidateCodeResponse({
    required this.valid,
    this.referrerName,
  });

  factory ValidateCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateCodeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ValidateCodeResponseToJson(this);

  @override
  List<Object?> get props => [valid, referrerName];
}

@JsonSerializable()
class MyReferrerResponse extends Equatable {
  @JsonKey(name: 'referrerName')
  final String? referrerName;
  final String? status;

  const MyReferrerResponse({
    this.referrerName,
    this.status,
  });

  factory MyReferrerResponse.fromJson(Map<String, dynamic> json) =>
      _$MyReferrerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyReferrerResponseToJson(this);

  @override
  List<Object?> get props => [referrerName, status];
}
