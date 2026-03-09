import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_change_model.g.dart';

@JsonSerializable()
class PendingChangeModel extends Equatable {
  final String id;
  @JsonKey(name: 'question_id')
  final String questionId;
  @JsonKey(name: 'change_type')
  final String changeType;
  final Map<String, dynamic>? payload;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'applied_at')
  final String? appliedAt;

  const PendingChangeModel({
    required this.id,
    required this.questionId,
    required this.changeType,
    this.payload,
    required this.status,
    required this.createdAt,
    this.appliedAt,
  });

  factory PendingChangeModel.fromJson(Map<String, dynamic> json) =>
      _$PendingChangeModelFromJson(json);
  Map<String, dynamic> toJson() => _$PendingChangeModelToJson(this);

  @override
  List<Object?> get props => [id];
}
