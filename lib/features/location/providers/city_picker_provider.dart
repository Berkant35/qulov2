import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';
import 'package:qulo_v2/features/location/providers/city_picker_state.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Cihazın bölgesi (ISO 3166-1 alpha-2, büyük harf): şehir seçicinin varsayılan ülkesi.
final deviceRegionProvider = Provider<String?>(
  (_) => WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase(),
);

/// Konumsuz yedek yol (2.0.18 madde 9): konum izni yok ya da Discover 400
/// `PROFILE_INCOMPLETE` → kullanıcı şehir seçer, sunucu şehir merkezini yazar.
class CityPickerNotifier extends AutoDisposeNotifier<CityPickerState> {
  int _request = 0;
  String _query = '';

  @override
  CityPickerState build() => const CityPickerState();

  /// Cihaz bölgesiyle açılır; bölge listede yoksa en çok kullanıcılı ülkeye düşer.
  Future<void> start() async {
    final region = ref.read(deviceRegionProvider);
    await _load(country: region);
    final countries = state.countries;
    if (countries.isEmpty || countries.contains(region)) return;
    state = state.copyWith(regionUnsupported: true);
    await _load(country: countries.first);
  }

  Future<void> search(String query) => _load(country: state.country, query: query);

  Future<void> selectCountry(String country) => _load(country: country, query: _query);

  Future<void> _load({String? country, String query = ''}) async {
    final request = ++_request;
    _query = query;
    state = state.copyWith(country: country, isLoading: true, hasError: false);
    final result = await ref.read(cityRepositoryProvider).search(country: country, query: query);
    if (request != _request) return; // daha yeni arama geldi
    state = switch (result) {
      Success(:final data) => state.copyWith(
          isLoading: false,
          cities: data.cities,
          countries: data.countries.isEmpty ? null : data.countries,
        ),
      Failure() => state.copyWith(isLoading: false, hasError: true, cities: const []),
    };
  }

  /// Kaydeder; başarıda profil (şehir merkezi) ve deste yeniden çekilir.
  /// Ekran kapansa da akış tamamlanır.
  Future<CitySaveResult?> save(CityModel city) async {
    if (state.savingCityId != null) return null;
    final link = ref.keepAlive();
    state = state.copyWith(savingCityId: city.id);
    try {
      final result = await ref.read(cityRepositoryProvider).setCity(city.id);
      if (result case Failure(:final failure)) {
        state = state.copyWith(savingCityId: null);
        final gone = failure is ServerFailure && failure.code == CityRepository.cityNotFoundCode;
        if (gone) await _load(country: state.country, query: _query);
        return gone ? CitySaveResult.cityGone : CitySaveResult.failed;
      }
      await _applySavedCity();
      return CitySaveResult.saved;
    } finally {
      link.close();
    }
  }

  Future<void> _applySavedCity() async {
    await ref.read(userProvider.notifier).fetchMe();
    final user = ref.read(userProvider).valueOrNull;
    if (user?.lat != null && user?.lng != null) {
      ref.read(locationProvider.notifier).seedFromProfile(lat: user!.lat!, lng: user.lng!, city: user.city);
    }
    await ref.read(discoverProvider.notifier).loadCards();
  }
}

final cityPickerProvider =
    AutoDisposeNotifierProvider<CityPickerNotifier, CityPickerState>(CityPickerNotifier.new);
