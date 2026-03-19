import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'media_request_model.g.dart';

@JsonSerializable()
class MediaRequestModel extends Equatable {
  final String id;
  @JsonKey(name: 'match_id')
  final String? matchId;
  @JsonKey(name: 'requester_id')
  final String? requesterId;
  final String status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'responded_at')
  final String? respondedAt;

  const MediaRequestModel({
    required this.id,
    this.matchId,
    this.requesterId,
    required this.status,
    this.createdAt,
    this.respondedAt,
  });

  factory MediaRequestModel.fromJson(Map<String, dynamic> json) =>
      _$MediaRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$MediaRequestModelToJson(this);

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(createToJson: false)
class MediaStatusResponse extends Equatable {
  @JsonKey(name: 'media_enabled')
  final bool mediaEnabled;
  @JsonKey(name: 'my_enabled')
  final bool myEnabled;
  @JsonKey(name: 'other_enabled')
  final bool otherEnabled;
  @JsonKey(name: 'pending_request')
  final MediaRequestModel? pendingRequest;

  const MediaStatusResponse({
    required this.mediaEnabled,
    required this.myEnabled,
    required this.otherEnabled,
    this.pendingRequest,
  });

  factory MediaStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaStatusResponseFromJson(json);

  @override
  List<Object?> get props => [mediaEnabled, myEnabled, otherEnabled];
}
