import 'package:equatable/equatable.dart';

class NotificationPreferencesModel extends Equatable {
  final bool messages;
  final bool matches;
  final bool campaigns;

  const NotificationPreferencesModel({
    this.messages = true,
    this.matches = true,
    this.campaigns = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      messages: json['messages'] as bool? ?? true,
      matches: json['matches'] as bool? ?? true,
      campaigns: json['campaigns'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'messages': messages,
        'matches': matches,
        'campaigns': campaigns,
      };

  NotificationPreferencesModel copyWith({
    bool? messages,
    bool? matches,
    bool? campaigns,
  }) {
    return NotificationPreferencesModel(
      messages: messages ?? this.messages,
      matches: matches ?? this.matches,
      campaigns: campaigns ?? this.campaigns,
    );
  }

  @override
  List<Object?> get props => [messages, matches, campaigns];
}
