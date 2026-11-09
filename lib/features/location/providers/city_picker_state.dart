import 'package:qulo_v2/data/models/city_model.dart';

/// Şehir seçicinin durumu (konumsuz yedek yol, 2.0.18).
class CityPickerState {
  final String? country;
  final List<String> countries;
  final List<CityModel> cities;
  final bool isLoading;
  final bool hasError;

  /// Cihaz bölgesi desteklenen ülkeler arasında değil: "en yakın büyük şehri seç" ipucu.
  final bool regionUnsupported;

  /// Kaydedilmekte olan şehir; çift dokunuşu engeller.
  final String? savingCityId;

  const CityPickerState({
    this.country,
    this.countries = const [],
    this.cities = const [],
    this.isLoading = true,
    this.hasError = false,
    this.regionUnsupported = false,
    this.savingCityId,
  });

  static const _keep = Object();

  CityPickerState copyWith({
    String? country,
    List<String>? countries,
    List<CityModel>? cities,
    bool? isLoading,
    bool? hasError,
    bool? regionUnsupported,
    Object? savingCityId = _keep,
  }) =>
      CityPickerState(
        country: country ?? this.country,
        countries: countries ?? this.countries,
        cities: cities ?? this.cities,
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? this.hasError,
        regionUnsupported: regionUnsupported ?? this.regionUnsupported,
        savingCityId: identical(savingCityId, _keep) ? this.savingCityId : savingCityId as String?,
      );
}

/// Şehir kaydının sonucu; ekran mesajı buna göre seçer.
enum CitySaveResult { saved, cityGone, failed }
