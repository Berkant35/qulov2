import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_message_model.g.dart';

@JsonSerializable()
class LocaleContent extends Equatable {
  final String title;
  final String body;
  @JsonKey(name: 'cta_label', defaultValue: '')
  final String ctaLabel;

  const LocaleContent({required this.title, required this.body, this.ctaLabel = ''});

  factory LocaleContent.fromJson(Map<String, dynamic> json) => _$LocaleContentFromJson(json);
  Map<String, dynamic> toJson() => _$LocaleContentToJson(this);

  @override
  List<Object?> get props => [title, body, ctaLabel];
}

@JsonSerializable()
class PageMessageModel extends Equatable {
  final String id;
  final String page;
  @JsonKey(name: 'display_type')
  final String displayType;
  final Map<String, LocaleContent> content;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'action_url')
  final String? actionUrl;
  final String frequency;
  final int priority;

  const PageMessageModel({
    required this.id,
    required this.page,
    required this.displayType,
    required this.content,
    this.imageUrl,
    this.actionUrl,
    required this.frequency,
    required this.priority,
  });

  /// Mevcut locale içeriği; yoksa 'en'; o da yoksa ilk mevcut.
  LocaleContent localized(String locale) =>
      content[locale] ?? content['en'] ?? content.values.first;

  factory PageMessageModel.fromJson(Map<String, dynamic> json) => _$PageMessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$PageMessageModelToJson(this);

  @override
  List<Object?> get props => [id, page, displayType, content, imageUrl, actionUrl, frequency, priority];
}
