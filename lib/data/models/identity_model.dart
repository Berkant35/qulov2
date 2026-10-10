import 'package:equatable/equatable.dart';

List<String> _labels(Object? raw) =>
    raw is List ? raw.whereType<String>().toList(growable: false) : const [];

/// Kullanıcının kendi etiketleri ve görünürlük ayarları (`GET/PUT /users/me/identity`).
class IdentityModel extends Equatable {
  final List<String> genderLabels;
  final List<String> orientationLabels;
  final bool showGenderLabels;
  final bool showOrientationLabels;

  const IdentityModel({
    this.genderLabels = const [],
    this.orientationLabels = const [],
    this.showGenderLabels = false,
    this.showOrientationLabels = false,
  });

  static const empty = IdentityModel();

  bool get isEmpty => genderLabels.isEmpty && orientationLabels.isEmpty;

  factory IdentityModel.fromJson(Map<String, dynamic> json) => IdentityModel(
        genderLabels: _labels(json['gender_labels']),
        orientationLabels: _labels(json['orientation_labels']),
        showGenderLabels: json['show_gender_labels'] as bool? ?? false,
        showOrientationLabels: json['show_orientation_labels'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'gender_labels': genderLabels,
        'orientation_labels': orientationLabels,
        'show_gender_labels': showGenderLabels,
        'show_orientation_labels': showOrientationLabels,
      };

  IdentityModel copyWith({
    List<String>? genderLabels,
    List<String>? orientationLabels,
    bool? showGenderLabels,
    bool? showOrientationLabels,
  }) =>
      IdentityModel(
        genderLabels: genderLabels ?? this.genderLabels,
        orientationLabels: orientationLabels ?? this.orientationLabels,
        showGenderLabels: showGenderLabels ?? this.showGenderLabels,
        showOrientationLabels: showOrientationLabels ?? this.showOrientationLabels,
      );

  @override
  List<Object?> get props => [genderLabels, orientationLabels, showGenderLabels, showOrientationLabels];
}

/// Başka kullanıcının yalnız görünür yaptığı etiketler (Discover kartı / profil detayı).
class VisibleIdentityModel extends Equatable {
  final List<String> genderLabels;
  final List<String> orientationLabels;

  const VisibleIdentityModel({this.genderLabels = const [], this.orientationLabels = const []});

  bool get isEmpty => genderLabels.isEmpty && orientationLabels.isEmpty;

  factory VisibleIdentityModel.fromJson(Map<String, dynamic> json) => VisibleIdentityModel(
        genderLabels: _labels(json['gender_labels']),
        orientationLabels: _labels(json['orientation_labels']),
      );

  Map<String, dynamic> toJson() => {
        if (genderLabels.isNotEmpty) 'gender_labels': genderLabels,
        if (orientationLabels.isNotEmpty) 'orientation_labels': orientationLabels,
      };

  @override
  List<Object?> get props => [genderLabels, orientationLabels];
}
