import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'acquisition_channel_model.g.dart';

@JsonSerializable()
class AcquisitionChannel extends Equatable {
  final String id;
  final String key;
  final String label;
  final String? emoji;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'is_freeform')
  final bool isFreeform;

  const AcquisitionChannel({
    required this.id,
    required this.key,
    required this.label,
    this.emoji,
    this.iconUrl,
    this.isFreeform = false,
  });

  factory AcquisitionChannel.fromJson(Map<String, dynamic> json) =>
      _$AcquisitionChannelFromJson(json);
  Map<String, dynamic> toJson() => _$AcquisitionChannelToJson(this);

  @override
  List<Object?> get props => [id, key, label, emoji, iconUrl, isFreeform];
}
