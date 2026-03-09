import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Equatable {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(name: 'is_image')
  final bool isImage;
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.isImage = false,
    this.readAt,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class MessagesResponse extends Equatable {
  final List<MessageModel> messages;
  final int total;
  final int page;
  final int limit;

  const MessagesResponse({
    required this.messages,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessagesResponseToJson(this);

  @override
  List<Object?> get props => [total, page];
}
