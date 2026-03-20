import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class PassportState {
  final String? city;
  final double? lat;
  final double? lng;
  final bool isActive;
  final bool isLoading;
  final AppFailure? failure;

  const PassportState({this.city, this.lat, this.lng, this.isActive = false, this.isLoading = false, this.failure});

  PassportState copyWith({String? city, double? lat, double? lng, bool? isActive, bool? isLoading, AppFailure? failure}) {
    return PassportState(
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

class PassportNotifier extends Notifier<PassportState> {
  @override
  PassportState build() => const PassportState();

  Future<Result<Map<String, dynamic>>> activate({required String city, required double lat, required double lng}) async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(passportRepositoryProvider).activate(city: city, lat: lat, lng: lng);
    result.when(
      success: (_) => state = PassportState(city: city, lat: lat, lng: lng, isActive: true),
      failure: (f) => state = state.copyWith(isLoading: false, failure: f),
    );
    return result;
  }

  Future<Result<void>> deactivate() async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(passportRepositoryProvider).deactivate();
    result.when(
      success: (_) => state = const PassportState(),
      failure: (f) => state = state.copyWith(isLoading: false, failure: f),
    );
    return result;
  }

  Future<Result<Map<String, dynamic>>> changeCity({
    required String city,
    required double lat,
    required double lng,
  }) async {
    final previousCity = state.city;
    final previousLat = state.lat;
    final previousLng = state.lng;

    state = state.copyWith(isLoading: true, failure: null);

    final deactivateResult = await ref.read(passportRepositoryProvider).deactivate();
    bool deactivateFailed = false;
    AppFailure? deactivateFailure;
    deactivateResult.when(
      success: (_) {},
      failure: (f) {
        deactivateFailed = true;
        deactivateFailure = f;
      },
    );
    if (deactivateFailed) {
      state = state.copyWith(isLoading: false, failure: deactivateFailure);
      return Failure(deactivateFailure!);
    }

    final activateResult = await ref.read(passportRepositoryProvider).activate(
      city: city,
      lat: lat,
      lng: lng,
    );

    activateResult.when(
      success: (_) {
        state = PassportState(city: city, lat: lat, lng: lng, isActive: true);
      },
      failure: (f) {
        if (previousCity != null && previousLat != null && previousLng != null) {
          ref.read(passportRepositoryProvider).activate(
            city: previousCity,
            lat: previousLat,
            lng: previousLng,
          ).then((rollback) {
            rollback.when(
              success: (_) {
                state = PassportState(
                  city: previousCity,
                  lat: previousLat,
                  lng: previousLng,
                  isActive: true,
                );
              },
              failure: (_) {
                state = const PassportState();
              },
            );
          });
        } else {
          state = state.copyWith(isLoading: false, failure: f);
        }
      },
    );

    return activateResult;
  }

  void syncFromUser(String? city, double? lat, double? lng) {
    if (city != null) {
      state = PassportState(city: city, lat: lat, lng: lng, isActive: true);
    }
  }
}

final passportProvider = NotifierProvider<PassportNotifier, PassportState>(PassportNotifier.new);
