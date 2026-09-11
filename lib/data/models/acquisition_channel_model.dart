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

  /// Agdan yuklenecek logo (icon_url) var mi.
  bool get hasLogo => iconUrl?.isNotEmpty ?? false;

  /// Bos string emoji yok sayilir — satirda bos Text + bosluk birakmasin.
  bool get hasEmoji => emoji?.isNotEmpty ?? false;

  /// Kanal satirinda gorsel (logo ya da emoji) var mi — yoksa bosluk da birakilmaz.
  bool get hasIcon => hasLogo || hasEmoji;

  factory AcquisitionChannel.fromJson(Map<String, dynamic> json) =>
      _$AcquisitionChannelFromJson(json);
  Map<String, dynamic> toJson() => _$AcquisitionChannelToJson(this);

  @override
  List<Object?> get props => [id, key, label, emoji, iconUrl, isFreeform];
}
