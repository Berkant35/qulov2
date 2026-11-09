import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config_model.g.dart';

@JsonSerializable()
class AppConfigModel extends Equatable {
  final String minVersion;
  final String latestVersion;
  final String storeUrl;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final bool isForceUpdateEnabled;

  /// Güç demosu kapatma anahtarı. Alan yoksa/null ise demo açık (fail-open).
  @JsonKey(defaultValue: true)
  final bool powerDemoEnabled;

  /// Discover native reklam anahtarı. Alan yoksa/null ise reklam KAPALI
  /// (fail-closed): gerçek AdMob kimliği girilene dek yalnız sunucu `true` verince açılır.
  @JsonKey(defaultValue: false)
  final bool adsEnabled;

  const AppConfigModel({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.isMaintenance,
    this.maintenanceMessage,
    required this.isForceUpdateEnabled,
    this.powerDemoEnabled = true,
    this.adsEnabled = false,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigModelToJson(this);

  @override
  List<Object?> get props => [
        minVersion,
        latestVersion,
        storeUrl,
        isMaintenance,
        maintenanceMessage,
        isForceUpdateEnabled,
        powerDemoEnabled,
        adsEnabled,
      ];
}
