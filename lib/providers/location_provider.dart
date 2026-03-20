import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class LocationState {
  final double? lat;
  final double? lng;
  final String? city;
  final bool isLoading;
  final String? error;

  const LocationState({this.lat, this.lng, this.city, this.isLoading = false, this.error});

  LocationState copyWith({double? lat, double? lng, String? city, bool? isLoading, String? error}) {
    return LocationState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      city: city ?? this.city,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  DateTime? _lastUpdateTime;
  static const _kLocationUpdateInterval = Duration(minutes: 15);

  @override
  LocationState build() => const LocationState();

  /// Login sonrası user profildeki mevcut lat/lng ile state'i doldur.
  /// GPS çağrısı yapmadan hemen discover'ı kullanılabilir hale getirir.
  void seedFromProfile({required double lat, required double lng, String? city}) {
    if (state.lat != null) return; // Zaten set edilmişse atla
    state = state.copyWith(lat: lat, lng: lng, city: city);
  }

  /// App resume olduğunda çağrılır.
  /// Error varsa veya 15dk geçmişse konum güncellenir.
  void onAppResumed() {
    if (state.isLoading) return;

    // Error varsa her zaman retry
    if (state.error != null) {
      getCurrentLocation();
      return;
    }

    // Throttle: son güncellemeden 15dk geçmişse güncelle
    if (_lastUpdateTime == null ||
        DateTime.now().difference(_lastUpdateTime!) >= _kLocationUpdateInterval) {
      getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final manager = ref.read(locationManagerProvider);

      final serviceEnabled = await manager.isServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLoading: false, error: 'LOCATION_SERVICE_DISABLED');
        return;
      }

      var permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await manager.requestPermission();
        if (permission == LocationPermissionStatus.denied) {
          state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED');
          return;
        }
      }

      if (permission == LocationPermissionStatus.deniedForever) {
        state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED_FOREVER');
        return;
      }

      final result = await manager.getCurrentPosition();

      state = state.copyWith(
        lat: result.lat,
        lng: result.lng,
        city: result.city,
        isLoading: false,
      );

      _lastUpdateTime = DateTime.now();

      await ref.read(userRepositoryProvider).updateLocation(
        lat: result.lat,
        lng: result.lng,
        city: result.city,
      );
    } on MockLocationException {
      state = state.copyWith(isLoading: false, error: 'LOCATION_MOCK_DETECTED');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
