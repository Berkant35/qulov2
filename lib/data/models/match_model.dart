import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_model.g.dart';

@JsonSerializable()
class MatchModel extends Equatable {
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'matched_at')
  final String matchedAt;
  final MatchUserModel? user;
  @JsonKey(name: 'media_enabled_by_user1')
  final bool mediaEnabledByUser1;
  @JsonKey(name: 'media_enabled_by_user2')
  final bool mediaEnabledByUser2;
  @JsonKey(name: 'last_message')
  final String? lastMessage;
  @JsonKey(name: 'last_message_sent_at')
  final String? lastMessageSentAt;
  @JsonKey(name: 'last_message_sender_id')
  final String? lastMessageSenderId;
  @JsonKey(name: 'unread_count')
  final int unreadCount;

  const MatchModel({
    required this.matchId,
    required this.matchedAt,
    this.user,
    this.mediaEnabledByUser1 = false,
    this.mediaEnabledByUser2 = false,
    this.lastMessage,
    this.lastMessageSentAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);

  bool get isMediaEnabled => mediaEnabledByUser1 && mediaEnabledByUser2;

  MatchModel copyWith({
    String? matchId,
    String? matchedAt,
    MatchUserModel? user,
    bool? mediaEnabledByUser1,
    bool? mediaEnabledByUser2,
    String? lastMessage,
    String? lastMessageSentAt,
    String? lastMessageSenderId,
    int? unreadCount,
  }) {
    return MatchModel(
      matchId: matchId ?? this.matchId,
      matchedAt: matchedAt ?? this.matchedAt,
      user: user ?? this.user,
      mediaEnabledByUser1: mediaEnabledByUser1 ?? this.mediaEnabledByUser1,
      mediaEnabledByUser2: mediaEnabledByUser2 ?? this.mediaEnabledByUser2,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSentAt: lastMessageSentAt ?? this.lastMessageSentAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        user,
        lastMessage,
        lastMessageSentAt,
        lastMessageSenderId,
        unreadCount,
        mediaEnabledByUser1,
        mediaEnabledByUser2,
      ];
}

@JsonSerializable()
class MatchUserModel extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;
  final String? name;
  final int? age;
  final String? city;
  final List<String>? photos;
  final String? bio;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_seen')
  final String? lastSeen;

  const MatchUserModel({
    required this.userId,
    this.name,
    this.age,
    this.city,
    this.photos,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
  });

  factory MatchUserModel.fromJson(Map<String, dynamic> json) =>
      _$MatchUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchUserModelToJson(this);

  MatchUserModel copyWith({
    String? userId,
    String? name,
    int? age,
    String? city,
    List<String>? photos,
    String? bio,
    bool? isOnline,
    String? lastSeen,
  }) {
    return MatchUserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      city: city ?? this.city,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [userId, isOnline, lastSeen];
}
