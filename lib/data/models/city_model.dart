import 'package:qulo_v2/data/models/json_read.dart';

/// Şehir seçici satırı (`GET /app/cities`). Ad çevrilmez, olduğu gibi gösterilir.
class CityModel {
  final String id;
  final String name;
  final String country;

  const CityModel({required this.id, required this.name, required this.country});

  static CityModel? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    final name = jsonText(json['name']);
    final country = jsonText(json['country']);
    if (id == null || name == null || country == null) return null;
    return CityModel(id: id, name: name, country: country);
  }
}

/// `GET /app/cities` yanıtı: desteklenen ülkeler (kullanıcı sayısına göre) + eşleşen şehirler.
class CityListResponse {
  final List<String> countries;
  final List<CityModel> cities;

  const CityListResponse({required this.countries, required this.cities});

  /// Eksik / bozuk alan çökme değil boş liste; bozuk satır atlanır.
  factory CityListResponse.fromJson(Object? json) {
    final map = jsonMap(json) ?? const <String, dynamic>{};
    final countries = map['countries'];
    return CityListResponse(
      countries: countries is List ? countries.whereType<String>().toList() : const [],
      cities: jsonMaps(map['cities']).map(CityModel.tryParse).whereType<CityModel>().toList(),
    );
  }
}
