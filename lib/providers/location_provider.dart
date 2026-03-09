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
  @override
  LocationState build() => const LocationState();

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

      await ref.read(userRepositoryProvider).updateLocation(
        lat: result.lat,
        lng: result.lng,
        city: result.city,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
