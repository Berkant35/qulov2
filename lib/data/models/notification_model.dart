import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  final String type;
  final String title;
  final String body;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'action_url')
  final String? actionUrl;
  @JsonKey(name: 'action_label')
  final String? actionLabel;
  @JsonKey(name: 'is_read', defaultValue: false)
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.campaignId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Yerel "okundu" guncellemesi icin. Alanlari elle kopyalamak, modele yeni
  /// alan eklendiginde onu sessizce dusururdu.
  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        campaignId: campaignId,
        type: type,
        title: title,
        body: body,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        campaignId,
        type,
        title,
        body,
        imageUrl,
        actionUrl,
        actionLabel,
        isRead,
        createdAt,
      ];
}
